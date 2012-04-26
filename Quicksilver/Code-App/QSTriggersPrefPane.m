#import "QSTriggersPrefPane.h"
#import "QSTriggerCenter.h"

#import "NSEvent+BLTRExtensions.h"
#import "QSCommandBuilder.h"
#import "QSLibrarian.h"
#import "QSAction.h"
#import "QSRegistry.h"

#import "QSObject.h"

#import "QSTrigger.h"
#import "QSCommand.h"
#import "QSInterfaceController.h"
#import "QSBackgroundView.h"
#import "QSController.h"
#import <Carbon/Carbon.h>
#import "QSImageAndTextCell.h"
#import "QSResourceManager.h"
#import "QSHandledSplitView.h"

#import "NSSortDescriptor+BLTRExtensions.h"
#import "QSTriggerManager.h"

#import "QSTableView.h"
#import "QSOutlineView.h"

@interface QSObject (NSTreeNodePrivate)
//- (NSIndexPath *)indexPath;
- (id)observedObject;
//- (id)objectAtIndexPath:(NSIndexPath *)path;
@end

@implementation QSTriggersArrayController
- (void)prepareContent {}
@end

#define QSTriggerDragType @"QSTriggerPBoardData"

@implementation QSTriggersPrefPane
+ (QSTriggersPrefPane *)sharedInstance {
	static QSTriggersPrefPane *_sharedInstance = nil;
	if (!_sharedInstance) {
		_sharedInstance = [[[self class] allocWithZone:[self zone]] init];
	}
	return _sharedInstance;
}
- (NSView *)loadMainView {
	NSView *oldMainView = [super loadMainView];

	splitView = [[QSHandledSplitView alloc] init];
	[splitView setVertical:YES];
	[splitView addSubview:sidebar];
	[splitView addSubview:oldMainView];

	_mainView = splitView;
	return _mainView;
}

- (id)init {
	//	self = [self initWithWindowNibName:@"Triggers"];
	self = [super initWithBundle:[NSBundle bundleForClass:[self class]]];
	if (self) {
		selectedRow = -1;
		//	[self setSort:[[[NSSortDescriptor alloc] initWithKey:@"command" ascending:YES] autorelease]];
		//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectTrigger:) name:NSOutlin object:triggerTable];
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(triggerChanged:) name:QSTriggerChangedNotification object:nil];
		[nc addObserver:self selector:@selector(populateTypeMenu) name:QSPlugInLoadedNotification object:nil];
		commandEditor = [[QSCommandBuilder alloc] init];
		[self setCurrentSet:@"Custom Triggers"];
	}
	return self;
}

- (void)paneLoadedByController:(id)controller {
	[optionsDrawer setParentWindow:[controller window]];
	[optionsDrawer setLeadingOffset:48];
	[optionsDrawer setTrailingOffset:24];
	[optionsDrawer setPreferredEdge:NSMaxXEdge];
	[[[optionsDrawer contentView] window] setDelegate:self];
}

- (void)willUnselect {
	[[QSTriggerCenter sharedInstance] writeTriggers];
    [optionsDrawer close];
}
- (int)tabViewIndex {
    return [drawerTabView indexOfTabViewItem:[drawerTabView selectedTabViewItem]];
}
- (void)setTabViewIndex:(int)index {
    [drawerTabView selectTabViewItemAtIndex:index];
}

- (NSString *)mainNibName { return @"QSTriggersPrefPane";  }

- (void)didSelect {
    [optionsDrawer setParentWindow:[[self mainView] window]];
}

- (NSArray *)typeMenuItems { return [[typeMenu itemArray] valueForKey:@"representedObject"];  }

- (NSArray *)typeMenuNames { return [[typeMenu itemArray] valueForKey:@"title"];  }

- (NSArray *)setNames {
	NSMutableArray *sets = [[[[NSSet setWithArray:[[[[QSTriggerCenter sharedInstance] triggersDict] allValues] valueForKey:@"triggerSet"]]allObjects] mutableCopy] autorelease];
	[sets removeObject:[NSNull null]];
	//	[sets addObject:@"- "];
	[sets addObject:@"All Triggers"];
	[sets addObject:@"Custom"];
	return sets;
}

- (BOOL)currentSetIsEnabled { return YES;  }

- (void)setCurrentSetIsEnabled:(BOOL)flag {}

- (void)populateTypeMenu {
	[typeMenu autorelease];
	typeMenu = [[NSMenu alloc] initWithTitle:@"Types"];

	NSMenu *addMenu = [[NSMenu alloc] initWithTitle:@"Types"];

	//NSLog(@"add %@ %@", addButton, typeMenu);
	id item;

	NSDictionary *managers = [QSReg instancesForTable:@"QSTriggerManagers"];

	//	NSLog(@"populate %@", managers);
	id manager = nil;
	NSMutableArray *items = [NSMutableArray array];

	id groupItem = nil;
	for(NSString *key in managers) {
		manager = [managers objectForKey:key];
		item = [[[NSMenuItem alloc] initWithTitle:[manager name] action:NULL keyEquivalent:@""] autorelease];
		[item setRepresentedObject:key];
		[item setImage:[manager image]];
		//	[item setAction:@selector(addTrigger:)];
		if ([key isEqualToString:@"QSGroupTrigger"])
			groupItem = item;
		else
			[items addObject:item];
	}

	[items sortUsingDescriptors:[NSSortDescriptor descriptorArrayWithKey:@"title" ascending:YES]];

	[typeMenu performSelector:@selector(addItem:) onObjectsInArray:items returnValues:NO];

	// Make a copy for addMenu
	//NSLog(@"items %@", items);
	items = [items valueForKeyPath:@"copy.autorelease"];

	[addMenu performSelector:@selector(addItem:) onObjectsInArray:items returnValues:NO];

	if (groupItem) {
		[addMenu addItem:[NSMenuItem separatorItem]];
		[addMenu addItem:groupItem];
	}

	for(id menuItem in [addMenu itemArray]) {
		[menuItem setTarget:self];
		[menuItem setAction:@selector(addTrigger:)];
	}

	[addButton setMenu:addMenu];
    [addMenu release];
}

- (id)preferencesSplitView { return [sidebar superview];  }

- (void)awakeFromNib {
	typeMenu = nil;
	[self populateTypeMenu];
    
    [addButton setKeyEquivalent:@"+"];
    [removeButton setKeyEquivalent:@"-"];
    [infoButton setKeyEquivalent:@"i"];
    for (NSButton *aButton in [NSArray arrayWithObjects:addButton,removeButton,infoButton, nil]) {
        [aButton setKeyEquivalentModifierMask:NSCommandKeyMask];
    }
    
	[triggerTable registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, QSTriggerDragType, nil]];

	[triggerTable setVerticalMotionCanBeginDrag: TRUE];

	//[[self window] setRepresentedFilename:[pTriggerSettings stringByStandardizingPath]];
	//[[[self window] standardWindowButton:NSWindowDocumentIconButton] setImage:[NSImage imageNamed:@"DocTriggers"]];

	[triggerTable setAction:@selector(outlineClicked:)];
	[triggerTable setTarget:self];
	[triggerTable setOutlineTableColumn:[triggerTable tableColumnWithIdentifier:@"command"]];
	[[[triggerTable tableColumnWithIdentifier:@"type"] dataCell] setArrowPosition:NSPopUpNoArrow];

	//  QSImageAndTextCell *imageAndTextCell = [[[QSImageAndTextCell alloc] initTextCell:@""] autorelease];
	//	[imageAndTextCell setEditable: YES];
	//	[imageAndTextCell setWraps:NO];
	//	[imageAndTextCell setFont:[[[triggerTable tableColumnWithIdentifier: @"command"] dataCell] font]];
	//	[[triggerTable tableColumnWithIdentifier: @"command"] setDataCell:imageAndTextCell];

	NSColor *color = [triggerSetsTable backgroundColor];
	float hue, saturation, brightness, alpha;
	[color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
	// NSLog(@"hu %f %f %f %f", hue, saturation, brightness, alpha);

	[triggerSetsTable setBackgroundColor:[NSColor colorWithCalibratedHue:0.15f
                                                              saturation:0.1f
                                                              brightness:0.980000f
                                                                   alpha:1.000000f]];
	NSColor *highlightColor = [NSColor colorWithCalibratedHue:0.11944444444
                                                   saturation:0.88f
                                                   brightness:1.000000f
                                                        alpha:1.000000f];

	[(QSTableView *)triggerSetsTable setHighlightColor:highlightColor];
	[(QSOutlineView *)triggerTable setHighlightColor:highlightColor];

	//[[triggerTable tableColumnWithIdentifier: @"command"] bind:@"objectValue"
	//												 toObject:triggerTreeController
	//											 withKeyPath:@"arrangedObjects"
	//												 options:nil];

	// NSView *border = [[optionsDrawer _drawerWindow] _borderView];
	// NSView *background = [[QSBackgroundView alloc] initWithFrame:NSMakeRect(0, 0, 200, 200)];

	// [border addSubview:background];
	// NSLog(@"%@", [[optionsDrawer _drawerWindow] _borderView]);
	//  NSLog(@"%@", [triggerTable columnWithIdentifier:@"type"]);
	//	[[[triggerTable columnWithIdentifier:@"type"] dataCell] setMenu:nil];

	[triggerTreeController addObserver:self
							forKeyPath:@"selectedObjects"
							   options:0
							   context:nil];
	NSSortDescriptor* aSortDesc = [[[NSSortDescriptor alloc]
                                    initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease];
	[triggerArrayController setSortDescriptors:[NSArray arrayWithObject: aSortDesc]];
	[triggerArrayController rearrangeObjects];

	[self reloadFilters];

	[triggerSetsController addObserver:self
							forKeyPath:@"selection"
							   options:0
							   context:triggerSetsController];
}
//- (int) numberOfRowsInTableView:(NSTableView *)aTableView {
//	return [triggerArray count];
//}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == triggerSetsController) {

		//	NSLog(@"trig %@", keyPath);
		NSArray *selection = [(NSArrayController *)triggerSetsController selectedObjects];
		[self setCurrentSet:[[selection lastObject] objectForKey:@"text"]];
	} else {
		//	NSLog(@"trig2 %@", keyPath);

        [infoButton setEnabled:YES];
        [removeButton setEnabled:YES];
        
		NSArray *selection = [triggerTreeController selectedObjects];
        if ([selection count] != 1) {
            if ([selection count] == 0 ) {
                [removeButton setEnabled:NO];
            }
            [infoButton setEnabled:NO];
        }
		[self setSelectedTrigger:[selection lastObject]];
	}
}

//- (void)outlineView:(NSOutlineView *)outlineView didClickTableColumn:(NSTableColumn *)tableColumn {
//NSLog()
//}

//- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
//	// theValue =
//	NSDictionary *thisTrigger = rowIndex<0?nil:[triggerArray objectAtIndex:rowIndex];
//	id manager = [QSReg instanceForKey:[thisTrigger objectForKey:@"type"] inTable:QSTriggerManagers];
//
//	if ([[aTableColumn identifier] isEqualToString: @"command"]) {
//		return [thisTrigger name];
////		NSMutableParagraphStyle *style = [[[NSMutableParagraphStyle alloc] init] autorelease];
////		[style setLineBreakMode:NSLineBreakByTruncatingTail];
////		NSMutableAttributedString *truncString = [[[NSMutableAttributedString alloc] initWithString:[command description]]autorelease];
////		[truncString addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, [truncString length])];
////		return truncString;
//	} else if ([[aTableColumn identifier] isEqualToString: @"trigger"]) {
//		return [thisTrigger description];
//	} else {
//		return [thisTrigger objectForKey:[aTableColumn identifier]];
//	}
//	return nil;
//}

- (IBAction)triggerChanged:(id)sender {
	[triggerTable reloadData];
}

- (QSTrigger *)currentTrigger {
	NSArray *triggers = [triggerArrayController selectedObjects];
	//	NSLog(@"trig %@ %@", triggerArrayController, triggers);
	if ([triggers count] != 1) {
		return nil;
	}
	return [triggers lastObject];
}

- (IBAction)selectTrigger:(id)sender {

	NSArray *triggers = [triggerTreeController selectedObjects];
    
	if ([triggers count] != 1) {
		[settingsItem setView:[[[NSView alloc] init] autorelease]];
		return;
	}
    
	QSTrigger *thisTrigger = [triggers lastObject];

	//	NSLog(@"trig %@", thisTrigger);

	id manager = [thisTrigger manager];
	NSView *settingsView = nil;

	if ([manager respondsToSelector:@selector(settingsView)])
		settingsView = [manager settingsView];

	if (!settingsView) settingsView = [[[NSView alloc] init] autorelease];

	[settingsItem setView:settingsView];

	if ([manager respondsToSelector:@selector(setCurrentTrigger:)])
		[manager setCurrentTrigger:thisTrigger];
}

/*
 + (NSString*)_stringForModifiers: (long)modifiers
 {
 static long modToChar[4] [2] =
 {
 { cmdKey, 		 } ,
 { optionKey, 	 } ,
 { controlKey, 	 } ,
 { shiftKey, 		 }
 } ;

 NSString* str;
 NSString* charStr;
 long i;

 str = [NSString string];

 for( i = 0; i < 4; i++ )
 {
 if ( modifiers & modToChar[i] [0] )
 {
 charStr = [NSString stringWithCharacters: (const unichar*)&modToChar[i] [1] length: 1];
 str = [str stringByAppendingString: charStr];
 }
 }

 return str;
 }
 */

- (QSTrigger *)selectedTrigger { return [[selectedTrigger retain] autorelease];  }
- (void)setSelectedTrigger:(QSTrigger *)newSelectedTrigger {
	if (selectedTrigger != newSelectedTrigger) {
		[selectedTrigger release];
		selectedTrigger = [newSelectedTrigger retain];
		[self selectTrigger:selectedTrigger];
	}
}
- (NSArray *)applications {
	return [[[NSWorkspace sharedWorkspace] launchedApplications] valueForKey:@"NSApplicationName"];
}

// Enabling/disabling of the 'edit' button is done programmatically within the outlineClicked: method
- (IBAction)editCommand:(id)sender {
	[self editTriggerCommand:selectedTrigger callback:@selector(editSheetDidEnd:returnCode:contextInfo:)];
}


- (IBAction)showTriggerInfo:(id)sender {
    [optionsDrawer open:sender];
}

// Called when a trigger's info panel is closed
- (IBAction)hideTriggerInfo:(id)sender {
	[[QSTriggerCenter sharedInstance] triggerChanged:selectedTrigger];
    [optionsDrawer close:sender];    
}

- (BOOL)editTriggerCommand:(QSTrigger *)trigger callback:(SEL)aSelector {
	//[[optionsDrawer contentView] window] //
	[commandEditor setCommand:[trigger command]];
	[NSApp beginSheet:[commandEditor window] modalForWindow:[[self mainView] window] modalDelegate:self didEndSelector:aSelector contextInfo:[trigger retain]];
	return YES;
}

- (void)editSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	QSCommand *command = [commandEditor representedCommand];
	QSTrigger *trigger = (QSTrigger *)contextInfo;
	if (command) {
        [trigger setCommand:command];
		[[QSTriggerCenter sharedInstance] triggerChanged:trigger];
	}
	[trigger release];
	[sheet orderOut:self];
}

- (void)addSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	QSCommand *command = [commandEditor representedCommand];
	QSTrigger *trigger = (QSTrigger*)contextInfo;
	if (command) {
		//		if (VERBOSE) NSLog(@"command %@", command);
		[trigger setCommand:command];
		[[QSTriggerCenter sharedInstance] triggerChanged:trigger];
	} else {
		[[QSTriggerCenter sharedInstance] removeTrigger:trigger];
		[self updateTriggerArray];
	}
    [trigger release];
	[sheet orderOut:self];
}

- (IBAction)addTrigger:(id)sender {
	if (!mOptionKeyIsDown)
		[self setCurrentSet:@"Custom Triggers"];

	NSMutableDictionary *info;
	if (mOptionKeyIsDown) {
		id theSelectedTrigger = [[triggerArrayController selectedObjects] lastObject];
		info = [[theSelectedTrigger info] mutableCopy];
		[info setObject:[NSNumber numberWithBool:NO] forKey:kItemEnabled];
	} else {
		id command = [[(QSController *)[NSApp delegate] interfaceController] currentCommand];
        info = [[NSMutableDictionary alloc] initWithCapacity:5];
		[info setObject:[sender representedObject] forKey:@"type"];
		[info setObject:[NSNumber numberWithBool:YES] forKey:kItemEnabled];
		if (command)
			[info setObject:command forKey:@"command"];
		//		[triggerTreeController add:sender];
	}
	[info setObject:[NSString uniqueString] forKey:kItemID];

	QSTrigger *trigger = [QSTrigger triggerWithDictionary:info];
    [info release];
	[trigger initializeTrigger];
	[[QSTriggerCenter sharedInstance] addTrigger:trigger];
	[self updateTriggerArray];
	//	[triggerArrayController
	//[triggerTreeController setSelectedObjects:[NSArray arrayWithObject:trigger]];
	[self selectTrigger:nil];

	[triggerTable reloadData];

	if ([[trigger type] isEqualToString:@"QSGroupTrigger"]) {
		int row = [triggerTable selectedRow];
		//NSLog(@"row %d %@", row, [[triggerArrayController selectedObjects] lastObject]);
		[triggerTable editColumn:[triggerTable columnWithIdentifier:@"command"]
							 row:row withEvent:[NSApp currentEvent] select:YES];
	} else if (!mOptionKeyIsDown) {
		[self editTriggerCommand:trigger
						callback:@selector(addSheetDidEnd:returnCode:contextInfo:)];
	}
}

- (IBAction)editTrigger:(id)sender {
	if ([triggerTable selectedRow] >= 0) {
		[self editTriggerCommand:[triggerArray objectAtIndex:[triggerTable selectedRow]] callback:@selector(editSheetDidEnd:returnCode:contextInfo:) ];
	}
}

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject {
	if (anObject == triggerTable) {
		if ([triggerTable clickedColumn] == [triggerTable columnWithIdentifier:@"trigger"] || [triggerTable editedColumn] == [triggerTable columnWithIdentifier:@"trigger"]) {
			NSArray *triggers = [triggerArrayController arrangedObjects];
			int index = [triggerTable clickedRow];
			if (index<0) return nil;
			id manager = [(QSTrigger *)[triggers objectAtIndex:index] manager];
			//NSLog(@"othereditor %@ %@", manager, thisTrigger);
			if ([manager respondsToSelector:@selector(windowWillReturnFieldEditor:toObject:)])
				return [manager windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject];
			//if (VERBOSE) NSLog(@"No Editor");
		}
	} else if ([anObject isDescendantOf:[optionsDrawer contentView]]) {
		id manager = [[self currentTrigger] manager];
		if ([manager respondsToSelector:@selector(windowWillReturnFieldEditor:toObject:)])
			return [manager windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject];
	}
	return nil;
}

- (IBAction)outlineClicked:(id)sender {
	// User has deselected a row
    if( [triggerTable clickedColumn] == -1 ) {
		[editButton setEnabled:NO];
#ifdef DEBUG
		NSLog(@"%@ with column == -1", NSStringFromSelector(_cmd));
#endif
        return;
    }
	NSTableColumn *col = [[triggerTable tableColumns] objectAtIndex:[triggerTable clickedColumn]];
	id item = [triggerTable itemAtRow:[triggerTable clickedRow]];
	item = [item respondsToSelector:@selector(representedObject)] ?[item representedObject] :[item observedObject];
    //	NSLog(@"%@ %@ %d %d", item, [col identifier] , selectedRow, [triggerTable clickedRow]);

  // check that the event is a mouse event (all events up to and including NSMouseExited) before doing anything else
  if ([[NSApp currentEvent] type] <= NSMouseExited && selectedRow == [triggerTable clickedRow] && [sender clickedRow] >= 0) {
		if ([[NSApp currentEvent] clickCount] >1) return;
		if ( [[col identifier] isEqualToString:@"command"]) {
			id theSelectedTrigger = item; //[[triggerArrayController arrangedObjects] objectAtIndex:[sender clickedRow]];
			if ([theSelectedTrigger isPreset]) return;
			[[triggerTable window] setAcceptsMouseMovedEvents:YES];
			NSEvent *theEvent = [NSApp nextEventMatchingMask:NSLeftMouseDownMask | NSKeyDownMask | NSLeftMouseDraggedMask | NSMouseMovedMask untilDate:[NSDate dateWithTimeIntervalSinceNow:[NSEvent doubleClickTime]] inMode:NSDefaultRunLoopMode dequeue:NO];

			if (!theEvent)
				[sender editColumn:[sender clickedColumn] row:[sender clickedRow] withEvent:[NSApp currentEvent] select:YES];
			[[triggerTable window] setAcceptsMouseMovedEvents:NO];
		}
	}
	selectedRow = [triggerTable clickedRow];
	[editButton setEnabled:YES];
}

- (void)updateTriggerArray {
	[self setTriggerArray:[[[[[QSTriggerCenter sharedInstance] triggersDict] allValues] mutableCopy] autorelease]];
	[triggerArrayController rearrangeObjects];
	[triggerTreeController rearrangeObjects];
	[triggerTable reloadData];
}

- (NSSortDescriptor *)sort { return sort;  }

- (void)setSort:(NSSortDescriptor *)newSort {
	[sort release];
	sort = [newSort retain];
}

- (NSArray *)triggerArray { return [[[QSTriggerCenter sharedInstance] triggersDict] allValues];  }

- (void)setTriggerArray:(NSMutableArray *)newTriggerArray {
	[triggerArray release];
	triggerArray = [newTriggerArray retain];
	//[triggerArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
}

- (IBAction)removeTrigger:(id)sender {
	if ([triggerTable selectedRow] <0) return;
	for(QSTrigger * trigger in [triggerTreeController selectedObjects]) {
		//NSLog(@"trig %@", trigger);
		if ([trigger isPreset])
			[trigger setEnabled:NO];
		else
			[[QSTriggerCenter sharedInstance] removeTrigger:trigger];
	}
	[self updateTriggerArray];
}

- (NSString *)currentSet { return currentSet;  }
- (void)setCurrentSet:(NSString *)value {
	if (currentSet != value) {
		[currentSet release];
		currentSet = [value copy];
		[self reloadFilters];
	}
}

- (void)showTrigger:(QSTrigger *)trigger {
	[self showTriggerGroupWithIdentifier:[trigger triggerSet]];
    //	NSLog(@"trig %@ %@", trigger, set);
}
- (void)showTriggerWithIdentifier:(NSString *)triggerID {
	[self showTrigger:[[QSTriggerCenter sharedInstance] triggerWithID:triggerID]];
}
- (void)showTriggerGroupWithIdentifier:(NSString *)groupID {
	[self setCurrentSet:groupID];
    //	NSLog(@"index %d", index);
	[(NSArrayController *)triggerSetsController setSelectionIndex:[[[self triggerSets] valueForKey:@"text"] indexOfObject:groupID]];
}

- (void)handleURL:(NSURL *)url { [self showTriggerWithIdentifier:[url fragment]];  }

- (void)reloadFilters {
	NSPredicate *predicate = nil;
	NSPredicate *rootPredicate = [NSPredicate predicateWithFormat:@"parentID == NULL"];
	//	[triggerArrayController setFilterPredicate:nil];
	if (![currentSet length] || [currentSet isEqual:@"Custom Triggers"]) {
		predicate = [NSPredicate predicateWithFormat:@"triggerSet == NULL", currentSet];
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates:
                     [NSArray arrayWithObjects:predicate, rootPredicate, nil]];
	} else if ([currentSet isEqual:@"All Triggers"]) {
	} else {
		predicate = [NSPredicate predicateWithFormat:@"triggerSet == %@", currentSet];
	}

	if ([search length]) {
		NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"name like[cd] %@", [NSString stringWithFormat:@"*%@*", search]];
		if (predicate)
			predicate = [NSCompoundPredicate andPredicateWithSubpredicates: [NSArray arrayWithObjects:predicate, searchPredicate, nil]];
		else
			predicate = searchPredicate;
	}
    //	NSLog(@"arranged %@", [triggerArrayController arrangedObjects]);
	[triggerArrayController setFilterPredicate:predicate];
}

- (NSString *)search { return search; }
- (void)setSearch:(NSString *)newSearch {
	if(newSearch != search){
		[search release];
		search = [newSearch retain];
		[self reloadFilters];
	}
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item {return nil;}
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {return NO;}
- (int) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {return 0;}
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {return nil;}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(NSCell *)aCell forTableColumn:(NSTableColumn *)aTableColumn item:(id)item {
	item = [item respondsToSelector:@selector(representedObject)] ?[item representedObject] :[item observedObject];

	//- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	QSTrigger *thisTrigger = item; //[[triggerArrayController arrangedObjects] objectAtIndex:rowIndex];
	BOOL isGroup = [thisTrigger isGroup];

	//	if ([[aTableColumn identifier] isEqualToString: @"command"]) {
	//
	//
	//		if ([aCell isHighlighted]) {
	//			[aCell setTextColor:[NSColor selectedTextColor]];
	//			NSLog(@"white");
	//		} else {
	//			[aCell setTextColor:[NSColor textColor]];
	//			NSLog(@"black");
	//		}
	//		if (![aCell isEnabled]) {
	//			[aCell setTextColor:[[aCell textColor] colorWithAlphaComponent:0.5]];
	//			NSLog(@"gray");
	//		}
	//
	//	}

	if ([[aTableColumn identifier] isEqualToString: @"type"]) {
		if ([aCell isMemberOfClass:[NSPopUpButtonCell class]]) {
			NSString *type = [thisTrigger valueForKey:@"type"];
			[aCell setMenu:[[typeMenu copy] autorelease]];
			[(NSPopUpButtonCell*)aCell selectItemAtIndex:[(NSPopUpButtonCell*)aCell indexOfItemWithRepresentedObject:type]];

			[aCell setEnabled:!isGroup && ([typeMenu numberOfItems] >1 || ![type length])];
		}
		return;
	}
	if ([[aTableColumn identifier] isEqualToString: @"enabled"]) {
		[(NSButtonCell*)aCell setTransparent:isGroup];
		return;
	}

	if ([[aTableColumn identifier] isEqualToString: @"trigger"]) {
        id desc = [item triggerDescription];
        [aCell setStringValue:( desc ? desc : @"Unknown" )];
		[aCell setRepresentedObject:item];
		return;
	}
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)aTableColumn byItem:(id)item {

	//- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	QSTrigger *thisTrigger = [item respondsToSelector:@selector(representedObject)] ?[item representedObject] :[item observedObject]; //[[triggerArrayController arrangedObjects] objectAtIndex:rowIndex];
	//NSLog(@"cell for %@", item);

	id manager = [thisTrigger manager];
	return ([manager respondsToSelector:@selector(descriptionCellForTrigger:)]) ? [manager performSelector:@selector(descriptionCellForTrigger:) withObject:thisTrigger] : nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)aTableColumn item:(id)item {
	//- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	item = [item respondsToSelector:@selector(representedObject)] ?[item representedObject] :[item observedObject];
	id theSelectedTrigger = item; //[[triggerArrayController selectedObjects] lastObject];
	if ([[aTableColumn identifier] isEqualToString:@"trigger"]) {
		//BOOL shouldEdit = NO;
		id manager = [theSelectedTrigger manager];
		//NSLog(@"othereditor %@ %@", manager, thisTrigger);
		//	if ([manager respondsToSelector:@selector(shouldEditTrigger:)])
		//			shouldEdit = [manager shouldEditTrigger:theSelectedTrigger];
		//
		//		if (!shouldEdit)
		[optionsDrawer open];
		if ([manager respondsToSelector:@selector(triggerDoubleClicked:)])
			[manager performSelector:@selector(triggerDoubleClicked:) withObject:theSelectedTrigger];
		return NO;
	}
	if ([[aTableColumn identifier] isEqualToString:@"command"] || [[aTableColumn identifier] isEqualToString:@"icon"]) {
		if ([theSelectedTrigger usesPresetCommand])
			return NO;
		if ([[NSApp currentEvent] type] == NSKeyDown) {
			[outlineView reloadData];
			[[outlineView window] makeFirstResponder:outlineView];
			return YES;
		}
		if ([[theSelectedTrigger type] isEqualToString:@"QSGroupTrigger"]) return YES;

		[self editTriggerCommand:theSelectedTrigger callback:@selector(editSheetDidEnd:returnCode:contextInfo:)];
		return NO;
		// return YES;
	} /*else if ([[aTableColumn identifier] isEqualToString: @"type"]) { this block commented out by me
       //NSLog(@"edit type");
       return NO;
       } */
	return NO;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn byItem:(id)item {
	//- (void)outlineView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	item = [item respondsToSelector:@selector(representedObject)] ?[item representedObject] :[item observedObject];
	QSTrigger *thisTrigger = item; //[[triggerArrayController arrangedObjects] objectAtIndex:rowIndex];

    if ([[aTableColumn identifier] isEqualToString: @"type"]) {
        //NSLog(@"anobject %@", anObject);

        int typeIndex = [anObject intValue];
        if (typeIndex == -1) return;
        NSString *type = [[typeMenu itemAtIndex:typeIndex] representedObject];
        [thisTrigger setType:type];
        [triggerTable reloadData];
        [optionsDrawer open];

        [self selectTrigger:self];
        //	} else if ([[aTableColumn identifier] isEqualToString: @"command"]) {
        //		if (![(NSString *)anObject length])anObject = nil;
        //		[thisTrigger setName:anObject];
        //		[aTableView reloadData];

    } else if ([[aTableColumn identifier] isEqualToString: @"trigger"]) {
        //NSLog(@"setdescrip %@", anObject);
        id manager = [thisTrigger manager];
        if ([manager respondsToSelector:@selector(trigger:setTriggerDescription:)])
            [manager trigger:[self currentTrigger] setTriggerDescription:anObject];

    } else if ([[aTableColumn identifier] isEqualToString: @"enabled"]) {
        return;

    }
    //else {
    //		[thisTrigger setValue:anObject forKey:[aTableColumn identifier]];
    //	}
    //
    NS_DURING
    [[QSTriggerCenter sharedInstance] triggerChanged:thisTrigger];
    NS_HANDLER
    NSBeep();
    NS_ENDHANDLER

    return;
}

// drag and drop
- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
    if([items count] == 0)
        return NO;
    //    items = ([items count] && [[items lastObject] respondsToSelector:@selector(representedObject)]) ? [items valueForKey:@"representedObject"] : [items valueForKey:@"observedObject"];

	[pboard declareTypes:[NSArray arrayWithObject:QSTriggerDragType] owner:self];
    NSArray *indexes = [items valueForKey:@"indexPath"];
    id data = [NSKeyedArchiver archivedDataWithRootObject:indexes];
	[pboard setData:data forType:QSTriggerDragType];
    NSLog(@"write %@", indexes);
	return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index {
	id realItem = item;
	item = [item respondsToSelector:@selector(representedObject)] ? [item representedObject] : [item observedObject];
    int dragOperation = (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) ? NSDragOperationCopy : NSDragOperationMove);

    /*    if ([draggedEntries containsObject:item])
     return NSDragOperationNone;*/

    if (!item && index == -1) {
        //        NSLog(@"No item, and index == -1");
        dragOperation = NSDragOperationNone;
    } else if (!item && index != -1) {
        //        NSLog(@"No item, but index == %d", index);
        [outlineView setDropItem:realItem dropChildIndex:index];
    } else if (item && [item isGroup]) {
        //        NSLog(@"Has item, which is a group, index == %d", index);
        if(index == -1)
            [outlineView setDropItem:realItem dropChildIndex:NSOutlineViewDropOnItemIndex];
        else
            [outlineView setDropItem:realItem dropChildIndex:index];
    } else {
        //        NSLog(@"On Item (isGroup: %@)?", ([item isGroup] ? @"YES" : @"NO"));
        dragOperation = NSDragOperationNone;
    }
    return dragOperation;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index {
	//id treeItem = item;
	//NSIndexPath *indexPath = [item indexPath];
	item = [item respondsToSelector:@selector(representedObject)] ? [item representedObject] : [item observedObject];
    NSLog(@"drop on %@ - %@ at index %d", item, [item identifier], index);

    NSPasteboard *pb = [info draggingPasteboard];
    NSData *data = [pb dataForType:QSTriggerDragType];
    NSArray *indexes = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSLog(@"indexes: %@", indexes);

	if ([info draggingSourceOperationMask] == NSDragOperationMove
        && [info draggingSource] == triggerTable) {
        /*        [triggerTreeController
         [triggerTreeController moveNodes:<#(NSArray *)nodes#> toIndexPath:<#(NSIndexPath *)startingIndexPath#>*/
        //		[draggedEntries setValue:[item identifier] forKey:@"parentID"];

		//NSLog(@"dragged %@", [draggedEntries valueForKey:@"parentID"]);
		//	[treeController removeObjectsAtArrangedObjectIndexPaths:draggedIndexPaths];
	}
	//
	//	//	NSLog(@"objects %@", objects);
	//	insertionArray = (NSMutableArray *)[item children];
	//	//	[treeController insertObject:[objects lastObject] atArrangedObjectIndexPath:indexPath];
	//
	//	if (index >= 0) [insertionArray replaceObjectsInRange:NSMakeRange(index, 0) withObjectsFromArray:objects];
	//	else [insertionArray addObjectsFromArray:objects];
	//
	[triggerArrayController rearrangeObjects];
	[triggerTreeController rearrangeObjects];
	//
	//
	[triggerTable reloadData];
	[[QSTriggerCenter sharedInstance] triggerChanged:nil];
	//
	//
	//	//[treeController setSelectionIndexPath:indexPath];
	//
	//	[self selectEntry:[objects lastObject]];
	//if (shouldShowOptions) {
	//		[self showOptionsDrawer];
	//	}
	//
	//	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogStructureChanged object:nil];
	return YES;
}

- (NSMutableArray *)triggerSets {
    {
		NSMutableDictionary *sets = [QSReg tableNamed:@"QSTriggerSets"];
		//[[[[NSSet setWithArray:[[[[QSTriggerCenter sharedInstance] triggersDict] allValues] valueForKey:@"triggerSet"]]allObjects] mutableCopy] autorelease];
		//[sets removeObject:[NSNull null]];

		NSMutableArray *setDicts = [NSMutableArray array];
		[setDicts addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Custom Triggers", @"text", [NSImage imageNamed:@"Triggers"] , @"image", nil]];

		foreachkey(key, set, sets) {

			[setDicts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                 [set objectForKey:@"name"] , @"text", [QSResourceManager imageNamed:[set objectForKey:@"icon"]], @"image", nil]];
		}
		[setDicts addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"All Triggers", @"text", [NSImage imageNamed:@"Pref-Triggers"] , @"image", nil]];

		//NSLog(@"sets %@", setDicts);
		return setDicts;
	}
	return [[triggerSets retain] autorelease];
}
- (void)setTriggerSets:(NSMutableArray *)newTriggerSets {
	if (triggerSets != newTriggerSets) {
		[triggerSets release];
		triggerSets = [newTriggerSets retain];
	}
}


- (NSString *)tokenField:(NSTokenField *)tokenField editingStringForRepresentedObject:(id)representedObject {
	NSString *path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:representedObject];
	return [[path lastPathComponent] stringByDeletingPathExtension];
}

// The method called when the token field (e.g. the 'scope' field completes/creates a new token
- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject {
	NSString *path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:representedObject];
	[[QSTriggerCenter sharedInstance] triggerChanged:selectedTrigger];
	return [[path lastPathComponent] stringByDeletingPathExtension];
}

// The method called to find a representation for the entered string in the token field
- (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString {
	NSString *path = [[NSWorkspace sharedWorkspace] fullPathForApplication:editingString];
    return [[NSBundle bundleWithPath:path] bundleIdentifier];
}
- (NSTokenStyle) tokenField:(NSTokenField *)tokenField styleForRepresentedObject:(id)representedObject {

	if ([representedObject hasPrefix:@"."]) return NSPlainTextTokenStyle;
	return NSRoundedTokenStyle;
}
- (BOOL)tokenField:(NSTokenField *)tokenField hasMenuForRepresentedObject:(id)representedObject {
	//if ([representedObject hasPrefix:@"'"] || [representedObject hasPrefix:@"."]) return NO;
	return NO;
}

@end

//Disabling "Return moves editing to next cell" in TableView (NSTableView->General)
//When you edit cells in a tableview, pressing return, tab, or shift-tab will end the current editing (which is good), and starts editing the next cell. But of times you don't want that to happen - the user wants to edit an attribute of a given row, but it doesn't ever want to do batch changes to everything.
//To make editing end, you need to subclass NSTableView and add code to catch the textDidEndEditing delegate notification, massage the text movement value to be something other than the return and tab text movement, and then let NSTableView handle things.
//
//// make return and tab only end editing, and not cause other cells to edit
//
//- (void)textDidEndEditing: (NSNotification *)notification
// {
//	NSDictionary *userInfo = [notification userInfo];
//
//	int textMovement = [[userInfo valueForKey:@"NSTextMovement"] intValue];
//
//	if (textMovement == NSReturnTextMovement
//		 || textMovement == NSTabTextMovement
//		 || textMovement == NSBacktabTextMovement) {
//
//		NSMutableDictionary *newInfo;
//		newInfo = [NSMutableDictionary dictionaryWithDictionary: userInfo];
//
//		[newInfo setObject: [NSNumber numberWithInt: NSIllegalTextMovement]
//					forKey: @"NSTextMovement"];
//
//		notification =
//			[NSNotification notificationWithName: [notification name]
//										 object: [notification object]
//										userInfo: newInfo];
//
//	}
//
//	[super textDidEndEditing: notification];
//	[[self window] makeFirstResponder:self];
//
//} // textDidEndEditing
