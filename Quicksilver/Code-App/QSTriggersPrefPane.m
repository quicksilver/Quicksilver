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

@implementation QSTriggersArrayController
- (void)prepareContent {}
@end

#define QSTriggerDragType @"QSTriggerPBoardData"

@implementation QSTriggersPrefPane
+ (QSTriggersPrefPane *)sharedInstance {
	static QSTriggersPrefPane *_sharedInstance = nil;
	if (!_sharedInstance) {
		_sharedInstance = [[super allocWithZone:[self zone]] init];
	}
	return _sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [[self sharedInstance] retain];
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
	self = [super initWithBundle:[NSBundle bundleForClass:[self class]]];
	if (self) {
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
- (NSInteger)tabViewIndex {
    return [drawerTabView indexOfTabViewItem:[drawerTabView selectedTabViewItem]];
}
- (void)setTabViewIndex:(NSInteger)index {
    [drawerTabView selectTabViewItemAtIndex:index];
}

- (NSString *)mainNibName { return @"QSTriggersPrefPane";  }

- (void)didSelect {
    [optionsDrawer setParentWindow:[[self mainView] window]];
}

- (NSArray *)typeMenuItems { return [[typeMenu itemArray] valueForKey:@"representedObject"];  }

- (NSArray *)typeMenuNames { return [[typeMenu itemArray] valueForKey:@"title"];  }

- (BOOL)currentSetIsEnabled { return YES;  }

- (void)setCurrentSetIsEnabled:(BOOL)flag {}

- (void)populateTypeMenu {
	[typeMenu autorelease];
	typeMenu = [[NSMenu alloc] initWithTitle:@"Types"];

	NSMutableArray *menuItems = [NSMutableArray array];

	id groupItem = nil;
	NSDictionary *managers = [[QSTriggerCenter sharedInstance] triggerManagers];
	for (NSString *key in managers) {
		QSTriggerManager *manager = [managers objectForKey:key];
		NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:[manager name]
													   action:NULL
												keyEquivalent:@""] autorelease];

		[item setRepresentedObject:key];
		[item setImage:[manager image]];
		if ([key isEqualToString:@"QSGroupTrigger"])
			groupItem = item;
		else
			[menuItems addObject:item];
	}

	[menuItems sortUsingDescriptors:[NSSortDescriptor descriptorArrayWithKey:@"title" ascending:YES]];

	[typeMenu performSelector:@selector(addItem:) onObjectsInArray:menuItems returnValues:NO];

	// Make a copy for for the add button menu, and add the Group type there
	NSMenu *addMenu = [typeMenu copy];

	if (groupItem) {
		[addMenu addItem:[NSMenuItem separatorItem]];
		[addMenu addItem:groupItem];
	}

	for (id menuItem in [addMenu itemArray]) {
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
	[self buildTriggerSets];
    
    [addButton setKeyEquivalent:@"+"];
    [removeButton setKeyEquivalent:@"-"];
    [infoButton setKeyEquivalent:@"i"];
    for (NSButton *aButton in [NSArray arrayWithObjects:addButton,removeButton,infoButton, nil]) {
        [aButton setKeyEquivalentModifierMask:NSCommandKeyMask];
    }
    
	[triggerTable registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, QSTriggerDragType, nil]];
	[triggerTable setVerticalMotionCanBeginDrag: TRUE];
	[triggerTable setOutlineTableColumn:[triggerTable tableColumnWithIdentifier:@"command"]];
	[[[triggerTable tableColumnWithIdentifier:@"type"] dataCell] setArrowPosition:NSPopUpNoArrow];

	NSColor *color = [triggerSetsTable backgroundColor];
	CGFloat hue, saturation, brightness, alpha;
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

    [triggerTreeController addObserver:self
                            forKeyPath:@"selection.info.applicationScopeType"
                               options:0
                               context:nil];
    [triggerTreeController addObserver:self
                            forKeyPath:@"selection.info.applicationScope"
                               options:0
                               context:nil];
	NSSortDescriptor *aSortDesc = [[[NSSortDescriptor alloc] initWithKey:@"name"
															   ascending:YES
																selector:@selector(caseInsensitiveCompare:)] autorelease];
	[triggerArrayController setSortDescriptors:[NSArray arrayWithObject:aSortDesc]];
	[triggerArrayController rearrangeObjects];
	[self reloadFilters];

	/* Bind the trigger set list selection to our currentSet property */
	[self bind:@"currentSet"
	  toObject:triggerSetsController
   withKeyPath:@"selection.text"
	   options:nil];

	/* Bind the list of triggers to our triggerArray property */
	[self bind:@"triggerArray"
	  toObject:[QSTriggerCenter sharedInstance]
   withKeyPath:@"triggers"
	   options:nil];

	[self bind:@"selectedTrigger"
	  toObject:triggerTreeController
   withKeyPath:@"selection.self"
	   options:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath rangeOfString:@"selection.info"].location != NSNotFound) {
        [[QSTriggerCenter sharedInstance] triggerChanged:[self selectedTrigger]];
        return;
    }
}

- (IBAction)triggerChanged:(id)sender {
	[triggerSetsController rearrangeObjects];
	[triggerArrayController rearrangeObjects];
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
	QSTrigger *thisTrigger = [self selectedTrigger];

	id manager = [thisTrigger manager];
	NSView *settingsView = nil;

	if ([manager respondsToSelector:@selector(settingsView)])
		settingsView = [manager settingsView];

	if (!settingsView)
		settingsView = [[[NSView alloc] init] autorelease];

	[settingsItem setView:settingsView];

	if ([manager respondsToSelector:@selector(setCurrentTrigger:)])
		[manager setCurrentTrigger:thisTrigger];
}

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

- (void)editSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	QSCommand *command = [commandEditor representedCommand];
	QSTrigger *trigger = (QSTrigger *)contextInfo;
	if (command) {
        [trigger setCommand:command];
		[[QSTriggerCenter sharedInstance] triggerChanged:trigger];
	}
	[trigger release];
	[sheet orderOut:self];
}

- (void)addSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	QSCommand *command = [commandEditor representedCommand];
	QSTrigger *trigger = (QSTrigger*)contextInfo;
	if (command) {
		//		if (VERBOSE) NSLog(@"command %@", command);
		[trigger setCommand:command];
		[[QSTriggerCenter sharedInstance] triggerChanged:trigger];
	} else {
		[[QSTriggerCenter sharedInstance] removeTrigger:trigger];
//		[self updateTriggerArray];
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
	[self selectTrigger:nil];

	[triggerTable reloadData];

	if ([[trigger type] isEqualToString:@"QSGroupTrigger"]) {
		NSInteger row = [triggerTable selectedRow];
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
			NSInteger index = [triggerTable clickedRow];
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
			return [manager windowWillReturnFieldEditor:sender toObject:anObject];
	}
	return nil;
}

- (NSSortDescriptor *)sort { return sort; }

- (void)setSort:(NSSortDescriptor *)newSort {
	[sort release];
	sort = [newSort retain];
}

- (NSArray *)triggerArray { return triggerArray; }

- (void)setTriggerArray:(NSMutableArray *)newTriggerArray {
	[triggerArray release];
	triggerArray = [newTriggerArray retain];
}

- (IBAction)removeTrigger:(id)sender {
	if ([triggerTable selectedRow] < 0)
		return;
	QSTrigger *trigger = [self selectedTrigger];
	if ([trigger isPreset])
		[trigger setEnabled:NO];
	else
		[[QSTriggerCenter sharedInstance] removeTrigger:trigger];
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
}

- (void)showTriggerWithIdentifier:(NSString *)triggerID {
	[self showTrigger:[[QSTriggerCenter sharedInstance] triggerWithID:triggerID]];
}

- (void)showTriggerGroupWithIdentifier:(NSString *)groupID {
	[self setCurrentSet:groupID];
	[triggerSetsController setSelectionIndex:[[[self triggerSets] valueForKey:@"text"] indexOfObject:groupID]];
}

- (void)handleURL:(NSURL *)url { [self showTriggerWithIdentifier:[url fragment]]; }

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

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {return nil;}
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {return NO;}
- (NSInteger) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {return 0;}
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {return nil;}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(NSCell *)aCell forTableColumn:(NSTableColumn *)aTableColumn item:(id)item {
	QSTrigger *thisTrigger = [item representedObject];
	BOOL isGroup = [thisTrigger isGroup];

	if ([[aTableColumn identifier] isEqualToString: @"type"]) {
		if ([aCell isMemberOfClass:[NSPopUpButtonCell class]]) {
			NSString *type = [thisTrigger valueForKey:@"type"];
			[aCell setMenu:[[typeMenu copy] autorelease]];
			[(NSPopUpButtonCell*)aCell selectItemAtIndex:[(NSPopUpButtonCell*)aCell indexOfItemWithRepresentedObject:type]];

			[aCell setEnabled:!isGroup && ([typeMenu numberOfItems] >1 || ![type length])];
		}
	}
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)aTableColumn byItem:(id)item {
	QSTrigger *thisTrigger = [item representedObject];

	QSTriggerManager *manager = [thisTrigger manager];
	return ([manager respondsToSelector:@selector(descriptionCellForTrigger:)]) ? [manager descriptionCellForTrigger:thisTrigger] : nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)aTableColumn item:(id)item {
	QSTrigger *theSelectedTrigger = [item representedObject];
	if ([[aTableColumn identifier] isEqualToString:@"trigger"]) {
		id manager = [theSelectedTrigger manager];
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
	}
	return NO;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn byItem:(id)item {
	QSTrigger *thisTrigger = [item representedObject];

    if ([[aTableColumn identifier] isEqualToString: @"type"]) {

        NSInteger typeIndex = [anObject integerValue];
        if (typeIndex == -1)
			return;
        NSString *type = [[typeMenu itemAtIndex:typeIndex] representedObject];
        [thisTrigger setType:type];
        [triggerTable reloadData];
        [optionsDrawer open];

        [self selectTrigger:self];
    } else if ([[aTableColumn identifier] isEqualToString: @"trigger"]) {
        id manager = [thisTrigger manager];
        if ([manager respondsToSelector:@selector(trigger:setTriggerDescription:)])
            [manager trigger:[self currentTrigger] setTriggerDescription:anObject];
    }
	
    @try {
		[[QSTriggerCenter sharedInstance] triggerChanged:thisTrigger];
    }
    @catch (NSException *e) {
#if DEBUG
        NSLog(@"Exception while changing trigger %@ : %@", thisTrigger, e);
#endif
        NSBeep();
    }
}

// drag and drop
- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
    if([items count] == 0)
        return NO;

	[pboard declareTypes:[NSArray arrayWithObject:QSTriggerDragType] owner:self];
    NSArray *indexes = [items valueForKey:@"indexPath"];
    id data = [NSKeyedArchiver archivedDataWithRootObject:indexes];
	[pboard setData:data forType:QSTriggerDragType];
    NSLog(@"write %@", indexes);
	return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
	id realItem = item;
	item = [item representedObject];
    NSInteger dragOperation = (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) ? NSDragOperationCopy : NSDragOperationMove);

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

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index {
	//id treeItem = item;
	//NSIndexPath *indexPath = [item indexPath];
	item = [item representedObject];
    NSLog(@"drop on %@ - %@ at index %ld", item, [item identifier], (long)index);
    
	[triggerArrayController rearrangeObjects];
	[triggerTreeController rearrangeObjects];
	
	[triggerTable reloadData];
	[[QSTriggerCenter sharedInstance] triggerChanged:nil];
	
	return YES;
}

- (void)buildTriggerSets {
	NSMutableDictionary *registrySets = [[QSReg tableNamed:@"QSTriggerSets"] mutableCopy];

	NSMutableArray *sets = [[NSMutableArray alloc] initWithCapacity:[registrySets count] + 2];
	[sets addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					 @"Custom Triggers", @"text",
					 [NSImage imageNamed:@"Triggers"], @"image",
					 nil]];

	for (NSString *key in registrySets) {
		NSDictionary *set = [registrySets objectForKey:key];
		NSImage *icon = [QSResourceManager imageNamed:[set objectForKey:@"icon"]];
		[sets addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						 [set objectForKey:@"name"], @"text",
						 icon, @"image",
						 nil]];
	}
	[sets addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					 @"All Triggers", @"text",
					 [NSImage imageNamed:@"Pref-Triggers"], @"image",
					 nil]];
	[self setTriggerSets:sets];
}

- (NSMutableArray *)triggerSets {
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
	return NO;
}

@end
