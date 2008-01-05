#import "QSTriggersPrefPane.h"
#import "QSTriggerCenter.h"

#import "QSTrigger.h"

@implementation QSTriggersArrayController
- (void) prepareContent {
}

@end 

@interface QSTriggersPrefPane (Private)
- (void) showTrigger:(QSTrigger*)trigger;

@end

@implementation QSTriggersPrefPane
#pragma mark -
#pragma mark Class Methods
+ (QSTriggersPrefPane *) sharedInstance {
	static QSTriggersPrefPane *_sharedInstance = nil;
	if (!_sharedInstance){
		_sharedInstance = [[[self class] allocWithZone:[self zone]] init];
	}
	return _sharedInstance;
}

#pragma mark -
#pragma mark Lifetime
//- (id) init {
//    self = [super initWithBundle:[NSBundle bundleForClass:[self class]]];
//	
//	if (self) {        
//		lastRow = -1;
//        
//		commandEditor = [[QSCommandBuilder alloc] init];
//        
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerChanged:) name:QSTriggerChangedNotification object:nil];
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(populateTypeMenu) name:QSPlugInLoadedNotification object:nil];
//		
//		[self setCurrentSet:@"Custom Triggers"];
//	}
//	return self;
//}
//
//- (void) dealloc {
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    
//    [triggerSetsController removeObserver:self forKeyPath:@"selection"];    
//    [triggerTreeController removeObserver:self forKeyPath:@"selectedObjects"];
//    
//    [commandEditor release], commandEditor = nil;
//    
//    [super dealloc];
//}

#pragma mark -
#pragma mark NSPreferencePane overrides

- (NSString *) mainNibName {
  
  NSLog(@"mainview"); 

	return @"CatalystPref";
}

- (void) mainViewDidLoad {
  NSLog(@"mainview"); 
}
//- (NSView *) loadMainView {
///*	NSView *oldMainView = [super loadMainView];	
//	
//	splitView = [[QSHandledSplitView alloc] init];
//	[splitView setVertical:YES];
//	[splitView addSubview:sidebar];
//	[splitView addSubview:[self mainView]];
//	
//    [self setMainView:splitView];
//    
//	return splitView;*/
//    return splitView;
//}
//
//- (void) mainViewDidLoad {
//    [splitView setVertical:YES];
//	[splitView addSubview:sidebar];
//	[splitView addSubview:mainView];
//    [splitView setNeedsDisplay:YES];
//    
//	typeMenu = nil;
//	[self populateTypeMenu];
//	[triggerTable registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, @"QSTriggerDragType", nil]];
//	
//    [triggerTable setVerticalMotionCanBeginDrag:YES];
//    
//    //[[self window] setRepresentedFilename:[pTriggerSettings stringByStandardizingPath]];
//    //[[[self window] standardWindowButton:NSWindowDocumentIconButton] setImage:[NSImage imageNamed:@"DocTriggers"]];
//    
//    [triggerTable setAction:@selector(outlineClicked:)];
//    [triggerTable setTarget:self];
//    [triggerTable setOutlineTableColumn:[triggerTable tableColumnWithIdentifier:@"command"]];
//    [[[triggerTable tableColumnWithIdentifier:@"type"] dataCell] setArrowPosition:NSPopUpNoArrow];
//    
//    //   QSImageAndTextCell *imageAndTextCell = [[[QSImageAndTextCell alloc] initTextCell:@""] autorelease];
//    //	   [imageAndTextCell setEditable: YES];
//    //	   [imageAndTextCell setWraps:NO];
//    //	   [imageAndTextCell setFont:[[[triggerTable tableColumnWithIdentifier: @"command"] dataCell] font]];
//    //	   [[triggerTable tableColumnWithIdentifier: @"command"] setDataCell:imageAndTextCell];
//    
//    NSColor *color = [triggerSetsTable backgroundColor];
//    float hue, saturation, brightness, alpha;
//    [color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
//    //  QSLog(@"hu %f %f %f %f", hue, saturation, brightness, alpha);
//    
//    
//    [triggerSetsTable setBackgroundColor:[NSColor colorWithCalibratedHue:0.15f
//                                                              saturation:0.1f
//                                                              brightness:0.980000f
//                                                                   alpha:1.000000f]];
//    NSColor *highlightColor = [NSColor colorWithCalibratedHue:0.11944444444
//                                                   saturation:0.88f
//                                                   brightness:1.000000f
//                                                        alpha:1.000000f];
//    
//    [triggerSetsTable setHighlightColor:highlightColor];
//    [triggerTable setHighlightColor:highlightColor];
//    
//    //[[triggerTable tableColumnWithIdentifier: @"command"] bind:@"objectValue"
//    //                                                  toObject:triggerTreeController
//    //                                               withKeyPath:@"arrangedObjects" 
//    //                                                   options:0];
//    
//    //NSView *border=[[optionsDrawer _drawerWindow] _borderView];
//    //NSView *background=[[QSBackgroundView alloc] initWithFrame:NSMakeRect(0,0,200,200)];
//    
//    //[border addSubview:background];
//    //QSLog(@"%@",[[optionsDrawer _drawerWindow] _borderView]);
//    //QSLog(@"%@",[triggerTable columnWithIdentifier:@"type"]);
//    //[[[triggerTable columnWithIdentifier:@"type"] dataCell] setMenu:nil];   
//    
//    NSSortDescriptor* aSortDesc = [[NSSortDescriptor alloc] 
//                                   initWithKey:@"name" ascending:YES
//                                   selector:@selector(caseInsensitiveCompare:)];
//    [triggerArrayController setSortDescriptors:[NSArray arrayWithObject: aSortDesc]];
//    [triggerArrayController rearrangeObjects];
//    [aSortDesc release];
//    
//    [self reloadFilters];
//    
//    [triggerSetsController addObserver:self
//                            forKeyPath:@"selection"
//                               options:0
//                               context:triggerSetsController];
//    
//    [triggerTreeController addObserver:self
//                            forKeyPath:@"selectedObjects"
//                               options:0
//                               context:nil];
//    
//}


//
//- (void) didSelect {
//	[optionsDrawer setParentWindow:[[self mainView] window]];
//}
//
//- (void) willUnselect {
//	[optionsDrawer close];
//}
//
//#pragma mark -
//#pragma mark KVO
//- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//	if (context == triggerSetsController) {
//		//	QSLog(@"trig %@",keyPath);
//		NSArray *selection = [triggerSetsController selectedObjects];
//		[self setCurrentSet:[[selection lastObject] objectForKey:@"text"]];
//	} else if (context == triggerTreeController) {
//		//	QSLog(@"trig2 %@",keyPath);
//		NSArray *selection = [triggerTreeController selectedObjects];
//		[self setSelectedTrigger:[selection lastObject]];
//	}
//}
//
//#pragma mark -
//#pragma mark Triggers
//- (QSTrigger *) currentTrigger {
//	NSArray *triggers = [triggerArrayController selectedObjects];	
//	//	QSLog(@"trig %@ %@",triggerArrayController,triggers);
//	if ([triggers count] != 1) {
//		return nil;
//	}	
//	return [triggers lastObject];
//}
//
//- (QSTrigger *) selectedTrigger {
//    return [[selectedTrigger retain] autorelease];
//}
//
//- (void) setSelectedTrigger:(QSTrigger *)newSelectedTrigger
//{
//    if (selectedTrigger != newSelectedTrigger) {
//        [selectedTrigger release];
//        selectedTrigger = [newSelectedTrigger retain];
//		[self selectTrigger:selectedTrigger];
//    }
//}
//
//- (BOOL) editTriggerCommand:(QSTrigger *)trigger callback:(SEL)aSelector {
//	//[[optionsDrawer contentView]window]//
//	[commandEditor setCommand:[trigger command]];
//	
//    [NSApp beginSheet:[commandEditor window]
//	   modalForWindow:[[self mainView] window]
//		modalDelegate:self
//	   didEndSelector:aSelector
//		  contextInfo:[trigger retain]];
//    
//	return YES;	
//}
//
//- (void) editSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
//	QSCommand *command = [commandEditor representedCommand];
//	QSTrigger *trigger = (QSTrigger*)contextInfo;
//	if (command) {
//		[trigger setObject:command forKey:@"command"];
//		[[QSTriggerCenter sharedInstance] triggerChanged:trigger];
//	}
//	//QSLog(@"command %@",command);
//	[trigger release];
//	[sheet orderOut:self];
//}
//
//- (void) addSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
//	QSCommand *command = [commandEditor representedCommand];
//	QSTrigger *trigger = (QSTrigger*)contextInfo;
//	if (command) {
//		//		if (VERBOSE)QSLog(@"command %@",command);
//		[trigger setObject:command forKey:@"command"];
//		[[QSTriggerCenter sharedInstance] triggerChanged:trigger];
//		
//	} else {
//		[[QSTriggerCenter sharedInstance] removeTrigger:trigger];
//		[self updateTriggerArray];
//	}
//    [trigger release];
//	[sheet orderOut:self];
//}
//
//- (void) showTriggerWithIdentifier:(NSString *)triggerID{
//	QSTrigger *trigger = [[QSTriggerCenter sharedInstance] triggerWithID:triggerID];
//	[self showTrigger:trigger];
//}
//
//- (void) updateTriggerArray {
//	[self setTriggerArray:[[[[[QSTriggerCenter sharedInstance] triggersDict] allValues] mutableCopy] autorelease]];
//	[triggerArrayController rearrangeObjects];
//	[triggerTreeController rearrangeObjects];
//	[triggerTable reloadData];
//}
//
//- (NSArray *) triggerArray { return [[[QSTriggerCenter sharedInstance] triggersDict] allValues]; }
//
//- (void) setTriggerArray:(NSArray *)newTriggerArray {
//	[triggerArray release];
//	triggerArray = [newTriggerArray mutableCopy];
//}
//
//- (void) showTriggerGroupWithIdentifier:(NSString *)groupID {
//	[self setCurrentSet:groupID];
//	
//	int index = [[[self triggerSets] valueForKey:@"text"] indexOfObject:groupID];
//	QSLog(@"index %d",index);
//	[triggerSetsController setSelectionIndex:index];
//}
//
//- (void) showTrigger:(QSTrigger *)trigger {
//	NSString *set = [trigger triggerSet];
//	[self showTriggerGroupWithIdentifier:set];
//	QSLog(@"trig %@ %@", trigger, set);
//}
//
//- (void) handleURL:(NSURL *)url {
//	[self showTriggerWithIdentifier:[url fragment]];
//}
//
//- (NSArray *) triggerSets { 
//    NSDictionary *sets = [QSReg elementsByIDForPointID:@"QSTriggerSets"];
//    
//    NSMutableArray *setDicts = [NSMutableArray array];
//    NSDictionary *dict;
//    dict = [NSDictionary dictionaryWithObjectsAndKeys:
//            @"Custom Triggers",                @"text",
//            [NSImage imageNamed:@"Triggers"],  @"image",
//            nil];
//    [setDicts addObject:dict];
//    
//    foreachkey(key, set, sets) {
//        dict = [NSDictionary dictionaryWithObjectsAndKeys:
//                [set objectForKey:@"name"],                                   @"text",
//                [QSResourceManager imageNamed:[set objectForKey:@"icon"]],    @"image",
//                nil];
//        [setDicts addObject:dict];
//    }
//    dict = [NSDictionary dictionaryWithObjectsAndKeys:
//            @"All Triggers",                        @"text",
//            [NSImage imageNamed:@"Pref-Triggers"],  @"image",
//            nil];
//    [setDicts addObject:dict];
//    
//    //QSLog(@"sets %@",setDicts);
//    return [[setDicts copy] autorelease];
//}
//
//- (void)setTriggerSets:(NSArray *)newTriggerSets {
//    if (triggerSets != newTriggerSets) {
//        [triggerSets release];
//        triggerSets = [newTriggerSets copy];
//    }
//}
//
//- (void)paneLoadedByController:(id)controller {
//	[optionsDrawer setParentWindow:[controller window]];
//	[optionsDrawer setLeadingOffset:48];
//	[optionsDrawer setTrailingOffset:24];
//	[optionsDrawer setPreferredEdge:NSMaxXEdge];
//	[[[optionsDrawer contentView] window] setDelegate:self];
//}
//
//- (int)tabViewIndex {
//    return [drawerTabView indexOfTabViewItem:[drawerTabView selectedTabViewItem]];
//}
//
//- (void)setTabViewIndex:(int)index {
//    [drawerTabView selectTabViewItemAtIndex:index];
//}
//
//- (NSArray *)typeMenuItems {
//	return [[typeMenu itemArray] valueForKey:@"representedObject"];
//}
//
//- (NSArray *)typeMenuNames {
//	return [[typeMenu itemArray] valueForKey:@"title"];
//}
//
//- (NSArray *)setNames {
//	NSMutableArray *sets = [[[[NSSet setWithArray:[[[[QSTriggerCenter sharedInstance] triggersDict] allValues] valueForKey:@"triggerSet"]] allObjects] mutableCopy] autorelease];
//	[sets removeObject:[NSNull null]];
//	//	[sets addObject:@"- "];
//	[sets addObject:@"All Triggers"];
//	[sets addObject:@"Custom"];
//	return sets;
//}
//
//- (BOOL)currentSetIsEnabled {
//	return YES;
//}
//
//- (void)setCurrentSetIsEnabled:(BOOL)flag {}
//
//- (void)populateTypeMenu {
//	[typeMenu autorelease];
//	typeMenu = [[NSMenu alloc] initWithTitle:@"Types"];
//	
//	NSMenu *addMenu = [[NSMenu alloc] initWithTitle:@"Types"];
//	
//	//QSLog(@"add %@ %@",addButton, typeMenu);
//	id item;
//	
//	NSDictionary *managers = [QSReg loadedElementsByIDForPointID:@"QSTriggerManagers"];
//	
//	//	QSLog(@"populate %@",managers);
//	NSEnumerator *e = [managers keyEnumerator];
//	NSString *key;
//	id manager = nil;
//	NSMutableArray *items = [NSMutableArray array];
//	
//	id groupItem = nil;
//	while((key = [e nextObject])) {
//		manager = [managers objectForKey:key];
//		item = [[[NSMenuItem alloc] initWithTitle:[manager name]
//                                           action:NULL
//                                    keyEquivalent:@""] autorelease];
//		[item setRepresentedObject:key];
//		[item setImage:[manager image]];
//        
//		if ([key isEqualToString:@"QSGroupTrigger"]) {
//			groupItem = item;
//		} else {
//			[items addObject:item];
//		}
//	}
//	
//	[items sortUsingDescriptors:[NSSortDescriptor descriptorArrayWithKey:@"title" ascending:YES]];
//	
//	[typeMenu performSelector:@selector(addItem:) onObjectsInArray:items returnValues:NO];
//	
//	// Make a copy for addMenu
//	//QSLog(@"items %@",items);
//	items = [items valueForKeyPath:@"copy.autorelease"];
//	
//	[addMenu performSelector:@selector(addItem:) onObjectsInArray:items returnValues:NO];
//	
//	if (groupItem) {
//		[addMenu addItem:[NSMenuItem separatorItem]];
//		[addMenu addItem:groupItem];	
//	}
//	
//	foreach(menuItem, [addMenu itemArray]) {
//		[menuItem setTarget:self];	
//		[menuItem setAction:@selector(addTrigger:)];
//	}
//	
//	[addButton setMenu:addMenu];
//}
//
//- (NSView*) preferencesSplitView {
//	return [sidebar superview];
//}
//
////- (void)outlineView:(NSOutlineView *)outlineView didClickTableColumn:(NSTableColumn *)tableColumn{
////QSLog()	
////}
//
////- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
////	// theValue = 
////	NSDictionary *thisTrigger=rowIndex<0?nil:[triggerArray objectAtIndex:rowIndex];
////	id manager=[QSReg instanceForKey:[thisTrigger objectForKey:@"type"] inTable:QSTriggerManagers];
////	
////	if ([[aTableColumn identifier] isEqualToString: @"command"]){
////		return [thisTrigger name];
//////		NSMutableParagraphStyle *style = [[[NSMutableParagraphStyle alloc]init] autorelease];
//////        [style setLineBreakMode:NSLineBreakByTruncatingTail];
//////        NSMutableAttributedString *truncString = [[[NSMutableAttributedString alloc] initWithString:[command description]]autorelease];
//////        [truncString addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, [truncString length])];
//////        return truncString;
////	}else  if ([[aTableColumn identifier] isEqualToString: @"trigger"]){
////		return [thisTrigger description];
////    }else {
////		return [thisTrigger objectForKey:[aTableColumn identifier]];        
////	}
////	return nil;
////}
//
///*
// + (NSString*)_stringForModifiers: (long)modifiers
// {
//	 static long modToChar[4][2] =
// {
// { cmdKey, 		 },
// { optionKey,	 },
// { controlKey,	 },
// { shiftKey,		 }
// };
//	 
//	 NSString* str;
//	 NSString* charStr;
//	 long i;
//	 
//	 str = [NSString string];
//	 
//	 for( i = 0; i < 4; i++ )
//	 {
//		 if( modifiers & modToChar[i][0] )
//		 {
//			 charStr = [NSString stringWithCharacters: (const unichar*)&modToChar[i][1] length: 1];
//			 str = [str stringByAppendingString: charStr];
//		 }
//	 }
//	 
//	 return str;
// }
// */
//
//- (NSArray *) applications {
//	return [[[NSWorkspace sharedWorkspace] launchedApplications] valueForKey:@"NSApplicationName"];
//}
//
//- (id) windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject {
//	if (anObject == triggerTable) {
//		if ([triggerTable clickedColumn] == [triggerTable columnWithIdentifier:@"trigger"] || [triggerTable editedColumn] == [triggerTable columnWithIdentifier:@"trigger"]) {
//			NSArray *triggers = [triggerArrayController arrangedObjects];
//			int index = [triggerTable clickedRow];
//			if (index < 0)
//                return nil;
//            
//			QSTrigger *thisTrigger = [triggers objectAtIndex:index];
//			id manager = [thisTrigger manager];
//			//QSLog(@"othereditor %@ %@",manager, thisTrigger);
//			if ([manager respondsToSelector:@selector(windowWillReturnFieldEditor:toObject:)])
//				return [manager windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject];
//			//if (VERBOSE)QSLog(@"No Editor");
//		}
//	} else if ([anObject isDescendantOf:[optionsDrawer contentView]]) {
//		id manager = [[self currentTrigger] manager];
//		if ([manager respondsToSelector:@selector(windowWillReturnFieldEditor:toObject:)])
//			return [manager windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject];
//	}
//	
//	return nil;
//}
//
//- (NSSortDescriptor *) sort { return sort; }
//
//- (void) setSort:(NSSortDescriptor *)newSort {
//	[sort release];
//	sort = [newSort retain];
//}
//
//- (NSString *) currentSet {
//    return [[currentSet retain] autorelease];
//}
//
//- (void) setCurrentSet:(NSString *)value {
//    if (currentSet != value) {
//        [currentSet release];
//        currentSet = [value copy];
//		[self reloadFilters];
//    }
//}
//
//- (void) reloadFilters {
//	NSPredicate *predicate = nil;
//	NSPredicate *rootPredicate = [NSPredicate predicateWithFormat:@"parentID == NULL"];
//    
//	if (![currentSet length] || [currentSet isEqual:@"Custom Triggers"]) {
//		predicate = [NSPredicate predicateWithFormat:@"triggerSet == NULL", currentSet];
//		predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:predicate, rootPredicate, nil]];
//	} else if ([currentSet isEqual:@"All Triggers"]) {
//	} else {
//		predicate = [NSPredicate predicateWithFormat:@"triggerSet == %@", currentSet];
//	}
//    
//	if ([search length]) {
//		NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"name like[cd] %@", [NSString stringWithFormat:@"*%@*", search]];
//		if (predicate)
//			predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:predicate, searchPredicate, nil]];
//		else
//			predicate = searchPredicate;
//	}
////	QSLog(@"arranged %@",[triggerArrayController arrangedObjects]);
//	[triggerArrayController setFilterPredicate:predicate];
//}
//
//
//- (NSString *) search {
//    return [[search retain] autorelease];
//}
//
//- (void) setSearch:(NSString *)newSearch {
//    [search autorelease];
//    search = [newSearch retain];
//	[self reloadFilters];
//}
//
//#pragma mark -
//#pragma mark Interface Builder actions
//- (IBAction) changeHotkey:(id)sender {
//#if 0
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults]
//    KeyCombo *keyCombo = [KeyCombo keyComboWithKeyCode:[[defaults objectForKey:kHotKeyCode] shortValue]
//                                          andModifiers:[[defaults objectForKey:kHotKeyModifiers] shortValue]];
//    
//    CGSConnection conn = _CGSDefaultConnection();
//    CGSSetGlobalHotKeyOperatingMode(conn, CGSGlobalHotKeyDisable);
//    NSEvent *theEvent = [NSApp nextEventMatchingMask:NSKeyDownMask
//                                           untilDate:[NSDate dateWithTimeIntervalSinceNow:10.0]
//                                              inMode:NSDefaultRunLoopMode
//                                             dequeue:YES];
//    CGSSetGlobalHotKeyOperatingMode(conn, CGSGlobalHotKeyEnable);
//    
//    //[[HotKeyCenter sharedCenter] removeHotKey:kActivationHotKey];
//    
//    if (theEvent) {
//        if (VERBOSE) QSLog(@"got event: %@", theEvent);
//        BOOL success;
//        
//        //QSLog(@"[%c]",KeyCodeToAscii([theEvent keyCode]));
//        keyCombo = nil;
//        if (1) {
//            keyCombo = [KeyCombo keyComboWithKeyCode:[theEvent keyCode]
//                                        andModifiers:[KeyBroadcaster cocoaToCarbonModifiers:[theEvent modifierFlags]]];
//            
//            [hotKeyButton setTitle:[keyCombo userDisplayRep]];
//            
//            [hotKeyButton setState:NSOffState];
//            [hotKeyButton setNeedsDisplay:YES];
//            [defaults setObject:[NSNumber numberWithShort:[keyCombo keyCode]] forKey:kHotKeyCode];
//            [defaults setObject:[NSNumber numberWithShort:[keyCombo modifiers]] forKey:kHotKeyModifiers];
//            
//            success = [[HotKeyCenter sharedCenter] addHotKey:kActivationHotKey
//                                                       combo:keyCombo
//                                                      target:[NSApp delegate]
//                                                      action:@selector(activateInterface:)];
//            if (success) {
//                if (VERBOSE) QSLog(@"success");
//            } else {
//                QSLog(@"Error: couldn't register hot key!");
//                [hotKeyButton setTitle:@"Error!"];
//            }
//        }     
//    }
//#endif
//}     
//
//- (IBAction) removeTrigger:(id)sender {
//	if ([triggerTable selectedRow] < 0)
//        return;
//    
//	foreach(trigger, [triggerTreeController selectedObjects]) {
//		//QSLog(@"trig %@",trigger);
//		if ([trigger isPreset]) {
//			[trigger setEnabled:NO];
//		} else {
//			[[QSTriggerCenter sharedInstance] removeTrigger:trigger];
//		}
//	}
//	[self updateTriggerArray];
//}
//
//- (IBAction) addTrigger:(id)sender {
//	
//	if (!mOptionKeyIsDown)
//		[self setCurrentSet:@"Custom Triggers"];
//	
//	NSMutableDictionary *info;
//	if (mOptionKeyIsDown) {
//		id selectedTrigger = [[triggerArrayController selectedObjects] lastObject];
//		info = [[selectedTrigger info] mutableCopy];
//		
//		[info setObject:[NSNumber numberWithBool:NO] forKey:kItemEnabled];
//	} else {
//		id command = [[[NSApp delegate] interfaceController] currentCommand];
//		info = [NSMutableDictionary dictionaryWithCapacity:5];
//        
//		[info setObject:[sender representedObject] forKey:@"type"];
//		[info setObject:[NSNumber numberWithBool:YES] forKey:kItemEnabled];
//		
//		if (command) {
//			[info setObject:command forKey:@"command"];
//		}
//	}
//	[info setObject:[NSString uniqueString] forKey:kItemID];
//	
//	QSTrigger *trigger = [QSTrigger triggerWithInfo:info];
//	[trigger initializeTrigger];
//	[[QSTriggerCenter sharedInstance] addTrigger:trigger];
//	[self updateTriggerArray];
//	//[triggerTreeController setSelectedObjects:[NSArray arrayWithObject:trigger]];
//	[self selectTrigger:nil];
//	
//	[triggerTable reloadData];
//	
//	if ([[trigger type] isEqualToString:@"QSGroupTrigger"]) {
//		int row = [triggerTable selectedRow];
//		//QSLog(@"row %d %@",row,[[triggerArrayController selectedObjects]lastObject]);
//		[triggerTable editColumn:[triggerTable columnWithIdentifier:@"command"]
//							 row:row
//                       withEvent:[NSApp currentEvent]
//                          select:YES];
//	} else if (!mOptionKeyIsDown) {
//		[self editTriggerCommand:trigger
//						callback:@selector(addSheetDidEnd:returnCode:contextInfo:)];
//	}
//}
//
//- (IBAction) editTrigger:(id)sender {
//	QSLog(@"edit");
//	if ([triggerTable selectedRow] >= 0) {
//		[self editTriggerCommand:[triggerArray objectAtIndex:[triggerTable selectedRow]]
//						callback:@selector(editSheetDidEnd:returnCode:contextInfo:)];
//	}
//}
//
//- (IBAction) outlineClicked:(id)sender {
//	NSTableColumn *col = [[triggerTable tableColumns] objectAtIndex:[triggerTable clickedColumn]];
//	id item = [triggerTable itemAtRow:[triggerTable clickedRow]];
//	item = [item observedObject];
//    //	QSLog(@"%@ %@ %d %d",item,[col identifier],lastRow,[triggerTable clickedRow]);
//	
//	
//	if (lastRow == [triggerTable clickedRow] && [sender clickedRow] >= 0) {
//		if ([[NSApp currentEvent]clickCount] > 1) return;
//		if ([[col identifier] isEqualToString:@"command"]) {
//			id selectedTrigger = item;//[[triggerArrayController arrangedObjects]objectAtIndex:[sender clickedRow]];
//			if ([selectedTrigger isPreset]) return;
//			[[triggerTable window] setAcceptsMouseMovedEvents:YES];
//			NSEvent *theEvent = [NSApp nextEventMatchingMask:NSLeftMouseDownMask|NSKeyDownMask|NSLeftMouseDraggedMask|NSMouseMovedMask untilDate:[NSDate dateWithTimeIntervalSinceNow:[NSEvent doubleClickTime]] inMode:NSDefaultRunLoopMode dequeue:NO];
//			
//			if (!theEvent)
//				[sender editColumn:[sender clickedColumn] row:[sender clickedRow] withEvent:[NSApp currentEvent] select:YES];
//			[[triggerTable window] setAcceptsMouseMovedEvents:NO];
//		}
//	}
//	
//	lastRow = [triggerTable clickedRow];
//}
//
//- (IBAction) triggerChanged:(id)sender {
//	[triggerTable reloadData];
//}
//
//- (IBAction) editCommand:(id)sender {
//	[self editTriggerCommand:selectedTrigger
//					callback:@selector(addSheetDidEnd:returnCode:contextInfo:)];
//}
//
//- (IBAction) selectTrigger:(id)sender {
//	
//	NSArray *triggers = [triggerTreeController selectedObjects];
//	
//	if ([triggers count] != 1) {
//		[settingsItem setView:[[[NSView alloc] init] autorelease]];
//		return;
//	}
//    
//	QSTrigger *thisTrigger = [triggers lastObject];
//	
//	//	QSLog(@"trig %@",thisTrigger);
//	
//	id manager = [thisTrigger manager];
//	NSView *settingsView = nil;
//	
//	if ([manager respondsToSelector:@selector(settingsView)])
//		settingsView = [manager settingsView];
//	
//	if (!settingsView) settingsView = [[[NSView alloc] init] autorelease];
//	
//	[settingsItem setView:settingsView];
//	
//	if ([manager respondsToSelector:@selector(setCurrentTrigger:)])
//		[manager setCurrentTrigger:thisTrigger];
//}
//
//#pragma mark -
//#pragma mark NSOutlineView Delegate
//- (BOOL) outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index {
//	//id treeItem=item;
//	//NSIndexPath *indexPath=[item indexPath];
//	item = [item observedObject];
//	//QSLog(@"drop on %@ - %@",item,[item identifier]);
//	//	if (!item) item=[QSLib entryForID:@"QSCatalogCustom"];
//	//NSMutableArray *insertionArray=nil;//(NSMutableArray *)[item childrenArray];
//	
//	//	BOOL shouldShowOptions=NO;
//	NSArray *objects = nil;
//	if ([info draggingSource] == outlineView) {
//		objects = draggedEntries;
//		//[NSUnarchiver unarchiveObjectWithData:data];
//		//		if (![item isPreset] || [info draggingSourceOperationMask]==NSDragOperationCopy)
//		//			objects=[objects valueForKey:@"uniqueCopy"];
//		
//		//	}else{ 
//		//		// ***warning   * support dragging of multiple items
//		//		QSCatalogEntry *entry=[self entryForDraggedFile:
//		//			[[[[info draggingPasteboard]propertyListForType:NSFilenamesPboardType]objectAtIndex:0]stringByAbbreviatingWithTildeInPath]
//		//			];
//		//		if (!entry){
//		//			NSBeep();	
//		//			return NO;
//		//		}
//		//		objects=[NSArray arrayWithObject:entry];
//		//		
//		//		[entry scanForced:YES];
//		//		shouldShowOptions=YES;
//		}
//	//	
//	//	
//	//	if (index>0 && [[insertionArray subarrayWithRange:NSMakeRange(0,index)]containsObject:[draggedEntries lastObject]])
//	//		index--;
//	
//	//	//QSLog(@"mast %d",[info draggingSourceOperationMask]);
//	if ([info draggingSourceOperationMask] == NSDragOperationMove && [info draggingSource] == triggerTable) {
//		
//		[draggedEntries setValue:[item identifier] forKey:@"parentID"];	
//		
//		//QSLog(@"dragged %@",[draggedEntries valueForKey:@"parentID"]);
//		//	[treeController removeObjectsAtArrangedObjectIndexPaths:draggedIndexPaths];	
//	}
//	//	
//	//	//	QSLog(@"objects %@",objects);
//	//	insertionArray=(NSMutableArray *)[item children];
//	//	//	[treeController insertObject:[objects lastObject] atArrangedObjectIndexPath:indexPath];
//	//	
//	//	if (index>=0) [insertionArray replaceObjectsInRange:NSMakeRange(index,0) withObjectsFromArray:objects];
//	//	else [insertionArray addObjectsFromArray:objects];
//	//	
//	[triggerArrayController rearrangeObjects];
//	[triggerTreeController rearrangeObjects];
//	//	
//	//	
//	[triggerTable reloadData];
//	[[QSTriggerCenter sharedInstance] triggerChanged:nil];
//	//	
//	//	
//	//	//[treeController setSelectionIndexPath:indexPath];
//	//	
//	//	[self selectEntry:[objects lastObject]];
//	//if (shouldShowOptions){
//	//		[self showOptionsDrawer];
//	//	}
//	//	
//	//	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogStructureChanged object:nil];
//	return YES;
//}
//
//
//- (id) outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item { return nil; }
//- (BOOL) outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item { return NO; }
//- (int) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item { return 0; }
//- (id) outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item { return nil; }
//
//- (BOOL) outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
//	draggedIndexPaths = [items valueForKey:@"indexPath"];
//	items = [items valueForKey:@"observedObject"];
//	draggedEntries = items;
//	
//	//	if ([[items lastObject]isSeparator]) return NO;    
//	
//	//	if ([[items objectAtIndex:0]isPreset]&& 
//	//		!([[NSApp currentEvent]modifierFlags]&NSAlternateKeyMask) && !DEBUG)
//	//		return NO;
//	[pboard declareTypes:[NSArray arrayWithObject:@"QSTriggerDragType"] owner:self];
//	//[pboard setData:[NSArchiver archivedDataWithRootObject:draggedIndexPaths] forType:QSCodedCatalogEntryPasteboardType];
//	//QSLog(@"write, %@",items);
//	return YES;
//}
//
//
//- (NSDragOperation) outlineView:(NSOutlineView *)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index {
//	id realItem = item;
//	item = [item observedObject];
//	//	return NSDragOperationMove;
//	//	//NSString *theID=[item identifier];
//	//	if ([item isSeparator]) return NO;  
//	//	if ([item isPreset])
//	//		return NSDragOperationNone;
//	
//	if ((!item && index != 0) || [item isGroup]) {
//		
//		[outlineView setDropItem:realItem dropChildIndex:NSOutlineViewDropOnItemIndex];
//		return NSDragOperationMove;
//		//if (index>0)return NSDragOperationMove;
//		if ([info draggingSource] == triggerTable) {
//			foreach(entry, draggedEntries) {
//				//	QSLog(@"%@ %@", [[item path]componentsJoinedByString:@"/"],[[entry path]componentsJoinedByString:@"/"]);
//				//	if ([[item path]hasPrefix:[entry path]])
//				//		return NSDragOperationNone;
//			}
//			
//			if ([draggedEntries containsObject:item])
//				return NSDragOperationNone;
//			
//			//		if ([[NSSet setWithArray:[item ancestors]]intersectsSet:[NSSet setWithArray:draggedEntries]])
//			//			return NSDragOperationNone;
//			
//			//		if ([[draggedEntries objectAtIndex:0] isPreset])
//			//			return ([[NSApp currentEvent]modifierFlags]&NSAlternateKeyMask)?NSDragOperationCopy:NSDragOperationNone;
//		}
//		
//		return NSDragOperationMove;
//	}
//	return NSDragOperationNone;
//}
//
//
//- (void) outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn item:(id)item {
//	item = [item observedObject];
//	
//	//- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{	
//	QSTrigger *thisTrigger = item; //[[triggerArrayController arrangedObjects] objectAtIndex:rowIndex];
//	BOOL isGroup = [thisTrigger isGroup];
//	
//	//	if ([[aTableColumn identifier] isEqualToString: @"command"]){		
//	//		
//	//		
//	//		if ([aCell isHighlighted]){
//	//			[aCell setTextColor:[NSColor selectedTextColor]];
//	//			QSLog(@"white");
//	//		}else{
//	//			[aCell setTextColor:[NSColor textColor]];
//	//			QSLog(@"black");
//	//		}
//	//		if (![aCell isEnabled]){
//	//			[aCell setTextColor:[[aCell textColor]colorWithAlphaComponent:0.5]];
//	//			QSLog(@"gray");
//	//		}
//	//		
//	//	}
//	
//	if ([[aTableColumn identifier] isEqualToString: @"type"]) {
//		if ([aCell isMemberOfClass:[NSPopUpButtonCell class]]) {
//			NSString *type = [thisTrigger valueForKey:@"type"];
//            
//			[aCell setMenu:[[typeMenu copy] autorelease]];
//			[aCell selectItemAtIndex:[aCell indexOfItemWithRepresentedObject:type]];
//			[aCell setEnabled:!isGroup && ([typeMenu numberOfItems] > 1 || ![type length])];
//		}
//	} else if ([[aTableColumn identifier] isEqualToString: @"enabled"]) {
//		[aCell setTransparent:isGroup];
//	} else if ([[aTableColumn identifier] isEqualToString: @"trigger"]) {	
//		[aCell setStringValue:[item triggerDescription]];
//		[aCell setRepresentedObject:item];		
//	}
//}
//
//- (NSCell *) outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)aTableColumn byItem:(id)item {
//	
//	//- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{	
//	QSTrigger *thisTrigger = [item observedObject]; //[[triggerArrayController arrangedObjects] objectAtIndex:rowIndex];
//	//QSLog(@"cell for %@",item);
//	
//	id manager = [thisTrigger manager];
//	NSCell *cell = nil;
//	if ([manager respondsToSelector:@selector(descriptionCellForTrigger:)]) {
//		cell = [manager descriptionCellForTrigger:thisTrigger];
//	}
//	return cell;
//}
//
//- (void) outlineView:(NSOutlineView *)outlineView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn byItem:(id)item {
//	//- (void)outlineView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
//	item = [item observedObject];
//	QSTrigger *thisTrigger = item;//[[triggerArrayController arrangedObjects] objectAtIndex:rowIndex];
//    
//    if ([[aTableColumn identifier] isEqualToString: @"type"]) {
//        //QSLog(@"anobject %@",anObject);
//        
//        int typeIndex = [anObject intValue];
//        if (typeIndex == -1) return;
//        NSString *type = [[typeMenu itemAtIndex:typeIndex] representedObject];
//        [thisTrigger setType:type];
//        [triggerTable reloadData];
//        [optionsDrawer open];
//        
//        [self selectTrigger:self];
//        //	}else if ([[aTableColumn identifier] isEqualToString: @"command"]){
//        //		if (![(NSString *)anObject length])anObject=nil;
//        //		[thisTrigger setName:anObject];
//        //		[aTableView reloadData];
//        
//    } else if ([[aTableColumn identifier] isEqualToString: @"trigger"]) {
//        //QSLog(@"setdescrip %@",anObject);
//        id manager = [thisTrigger manager];
//        if ([manager respondsToSelector:@selector(trigger:setTriggerDescription:)])
//            [manager trigger:[self currentTrigger] setTriggerDescription:anObject];
//        
//    } else if ([[aTableColumn identifier] isEqualToString: @"enabled"]) {
//        return;
//    }
//    //else {
//    //		[thisTrigger setValue:anObject forKey:[aTableColumn identifier]];        
//    //	}
//    //	
//    NS_DURING
//    [[QSTriggerCenter sharedInstance] triggerChanged:thisTrigger];
//    NS_HANDLER
//    NSBeep();
//    NS_ENDHANDLER
//    
//    return;
//}
//
//- (BOOL) outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)aTableColumn item:(id)item {
//	//- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
//	item = [item observedObject];
//	id selectedTrigger = item; //[[triggerArrayController selectedObjects]lastObject];
//	if ([[aTableColumn identifier] isEqualToString:@"trigger"]) {
//		
//		id manager = [selectedTrigger manager];
//		//QSLog(@"othereditor %@ %@",manager, thisTrigger);
//		//	if ([manager respondsToSelector:@selector(shouldEditTrigger:)])
//		//			shouldEdit=[manager shouldEditTrigger:selectedTrigger];
//		//		
//		//		if (!shouldEdit)
//		[optionsDrawer open];
//		
//		if ([manager respondsToSelector:@selector(triggerDoubleClicked:)])
//			[manager triggerDoubleClicked:selectedTrigger];
//		
//		return NO;   
//	} else if ([[aTableColumn identifier] isEqualToString:@"command"] || [[aTableColumn identifier] isEqualToString:@"icon"]) {
//		if ([selectedTrigger usesPresetCommand])
//			return NO;
//		if ([[NSApp currentEvent] type] == NSKeyDown) {
//			[outlineView reloadData];
//			
//			[[outlineView window] makeFirstResponder:outlineView];
//			return YES;
//		}
//		if ([[selectedTrigger type] isEqualToString:@"QSGroupTrigger"])
//            return YES;
//		
//		[self editTriggerCommand:selectedTrigger
//						callback:@selector(editSheetDidEnd:returnCode:contextInfo:)];
//		return NO;  
//	} else if ([[aTableColumn identifier] isEqualToString: @"type"]) {
//		//QSLog(@"edit type");
//		
//		return NO;
//	}
//    return NO;
//}
//
//#pragma mark -
//#pragma mark NSTokenField Delegate
//- (NSString *) tokenField:(NSTokenField *)tokenField editingStringForRepresentedObject:(id)representedObject {
//	NSString *path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:representedObject];
//	return  [[path lastPathComponent] stringByDeletingPathExtension];
//}
//
//- (NSString *) tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject {
//	NSString *path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:representedObject];
//	return  [[path lastPathComponent] stringByDeletingPathExtension];
//}
//
//- (id) tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString {
//	NSString *path = [[NSWorkspace sharedWorkspace] fullPathForApplication:editingString];
//    return [[NSBundle bundleWithPath:path] bundleIdentifier];
//}
//
//- (NSTokenStyle) tokenField:(NSTokenField *)tokenField styleForRepresentedObject:(id)representedObject {
//	return ([representedObject hasPrefix:@"."] ? NSPlainTextTokenStyle : NSRoundedTokenStyle);
//}
//
//- (BOOL) tokenField:(NSTokenField *)tokenField hasMenuForRepresentedObject:(id)representedObject {
//	//if ([representedObject hasPrefix:@"'"] || [representedObject hasPrefix:@"."])return NO;
//	return NO;
//}

@end


//Disabling "Return moves editing to next cell" in TableView (NSTableView->General)
//When you edit cells in a tableview, pressing return, tab, or shift-tab will end the current editing (which is good), and starts editing the next cell. But of times you don't want that to happen - the user wants to edit an attribute of a given row, but it doesn't ever want to do batch changes to everything.
//To make editing end, you need to subclass NSTableView and add code to catch the textDidEndEditing delegate notification, massage the text movement value to be something other than the return and tab text movement, and then let NSTableView handle things.
//
//// make return and tab only end editing, and not cause other cells to edit
//
//- (void) textDidEndEditing: (NSNotification *) notification
//{
//    NSDictionary *userInfo = [notification userInfo];
//	
//    int textMovement = [[userInfo valueForKey:@"NSTextMovement"] intValue];
//	
//    if (textMovement == NSReturnTextMovement
//        || textMovement == NSTabTextMovement
//        || textMovement == NSBacktabTextMovement) {
//		
//        NSMutableDictionary *newInfo;
//        newInfo = [NSMutableDictionary dictionaryWithDictionary: userInfo];
//		
//        [newInfo setObject: [NSNumber numberWithInt: NSIllegalTextMovement]
//					forKey: @"NSTextMovement"];
//		
//        notification =
//            [NSNotification notificationWithName: [notification name]
//										  object: [notification object]
//										userInfo: newInfo];
//		
//    }
//	
//    [super textDidEndEditing: notification];
//    [[self window] makeFirstResponder:self];
//	
//} // textDidEndEditing