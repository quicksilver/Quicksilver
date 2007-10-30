

#import "NSBundle_BLTRExtensions.h"


#import "QSCatalogPrefPane.h"
#import "QSPreferenceKeys.h"
#import "QSPreferencesController.h"

#import "QSObject.h"
#import "QSNotifications.h"
#import "QSObjectCell.h"

#import "QSObjectSource.h"
#import "QSResourceManager.h"
#import "QSController.h"
#import "QSImageAndTextCell.h"


#import "QSNotifications.h"

#import "QSHandledSplitView.h"
#define COLUMNID_NAME		@"name"
#define COLUMNID_ENABLED		@"enabled"
#define COLUMNID_TYPE	 	@"TypeColumn"
#define COLUMNID_STATUS	 	@"StatusColumn"
#define UNSTABLE_STRING		@"(Unstable Entry) "

//#import "KeyBroadcaster.h"

#import "QSTaskController.h"



#import "QSCatalogSwitchButtonCell.h"
//#import "QSFileSystemObjectSource.h"
#import "QSApp.h"
//#import "HotKeyCenter.h"

//#import "QSToolbarView.h"
#import "QSBackgroundView.h"

#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>

#include <unistd.h>

@interface QSObject (NSTreeNodePrivate)
- (NSIndexPath *)indexPath;
- (id)representedObject;
- (id)objectAtIndexPath:(NSIndexPath *)path;
@end
@implementation QSObject (NSTreeNodePrivate)
- (id)representedObject {return self;}
@end

@implementation QSCatalogPrefPane

+ (void)initialize {
	// [self setKeys:[NSArray arrayWithObject:@"currentItem"] triggerChangeNotificationsForDependentKey:@"selectedCatalogEntryIsEditable"];
    
}


static id _sharedInstance;
+ (id)sharedInstance {
    if (!_sharedInstance) _sharedInstance = [[[self class] allocWithZone:[self zone]] init];
    return _sharedInstance;
}
- (void)preferencesSplitView {
	return [sidebar superview];
}


- (id)init {
	//	self = [self initWithWindowNibName:@"Triggers"];
	
    self = [super initWithBundle:[NSBundle bundleForClass:[self class]]];
	if (!_sharedInstance) _sharedInstance = [self retain];
	if (self) {        
		defaults = [[NSUserDefaults standardUserDefaults]retain];
        librarian = QSLib;
        [self setCurrentItem:nil];
        currentItemContents = nil;
		
		
	}
	return self;
}
- (NSView *)loadMainView {
	NSView *oldMainView = [super loadMainView]; 	
	
	NSSplitView *splitView = [[QSHandledSplitView alloc]init];
	[splitView setVertical:YES];
	[splitView addSubview:sidebar];
	[splitView addSubview:oldMainView];
	
	_mainView = splitView;
	return _mainView;
}

- (NSString *)mainNibName {
	return @"QSCatalog";
}

- (void)paneLoadedByController:(id)controller {
	[itemContentsDrawer setParentWindow:[controller window]];
	[itemContentsDrawer setLeadingOffset:48];
	[itemContentsDrawer setTrailingOffset:24];
	[itemContentsDrawer setPreferredEdge:NSMaxXEdge];
	
}


- (void)willUnselect {
	[itemContentsDrawer close];
}




- (void)awakeFromNib {
	
//		  NSColor *color = [catalogSetsTable backgroundColor];
//	float hue, saturation, brightness, alpha;
//	[color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
//	QSLog(@"hu %f %f %f %f", hue, saturation, brightness, alpha);

	   [catalogSetsTable setBackgroundColor:[NSColor colorWithCalibratedHue:.60277777777777777777f
																 saturation:0.070000f
																 brightness:0.970000f
																	  alpha:1.000000f]];
	 NSColor *highlightColor = [NSColor colorWithCalibratedHue:.60277777777777777777f
																saturation:0.740000f
																brightness:0.84f
																	 alpha:1.000000f];
	   
	
	   
   [catalogSetsTable setHighlightColor:highlightColor];
	   [itemTable setHighlightColor:highlightColor];
	   [itemContentsTable setHighlightColor:highlightColor];
	   
	   
	   
	//  [[self window] center];
	//  [[self window] setFrameAutosaveName: @"catalog"];
	// [[self window]addDocumentIconButton];
	
    //[[self window] setRepresentedFilename:[pCatalogSettings stringByStandardizingPath]];
    //[[[self window]standardWindowButton:NSWindowDocumentIconButton]setImage:[NSImage imageNamed:@"DocCatalog"]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(catalogCacheChanged:) name:@"CatalogCacheChanged" object:nil];
	
	//  [[itemViewSwitcher cell]setControlSize:NSSmallControlSize];
    NSMutableArray *sourceElements = [QSReg elementsForPointID:kQSObjectSources];
    
	
    // [NSArray arrayWithObjects:@"QSFileSystemObjectSource", kRecentAppsPreset, kRecentDocsPreset, kDockAppsPreset, kDockOthersPreset, kAddressBookPreset, kAllApplicationsPreset, nil];
    
	/// [sourcePopUp removeAllItems];
	//  [sourcePopUp addItemWithTitle:@"+"];
    
    //if (0) {
	//  sources = [NSArray arrayWithObjects:@"QSFileSystemObjectSource", @"QSGroupObjectSource", nil];
	//   [itemOptionsTabView removeTabViewItem:[itemOptionsTabView tabViewItemAtIndex:2]];
	//   [itemContentsTable removeTableColumn:[itemContentsTable tableColumnWithIdentifier:kItemEnabled]];
    //}
	//QSLog(@"sources %@", sources);
    NSMenuItem *item;
    NSImage *icon;

	[itemAddButton setMenu:[[[NSMenu alloc]initWithTitle:@"Sources"]autorelease]];

    for (BElement *element in sourceElements) {
		
		id source = [element elementInstance];
        NSString *theID = [element identifier];
		
		
		
		BOOL validSource = [source respondsToSelector:@selector(isVisibleSource)]
			 && [source isVisibleSource];
		
		if (!validSource) continue;  
		QSLog(@"vsource %@", source);
		NSString *title = [[NSBundle bundleForClass:[source class]]safeLocalizedStringForKey:theID value:theID table:@"QSObjectSource.name"];
		if ([title isEqualToString:theID]) title = [[NSBundle mainBundle]safeLocalizedStringForKey:theID value:theID table:@"QSObjectSource.name"];
        item = [[[NSMenuItem alloc]initWithTitle:title action:nil keyEquivalent:@""]autorelease];
        [item setRepresentedObject:theID];
        [item setTarget:self];
        [item setAction:@selector(addSource:)];
        icon = [[source iconForEntry:nil]copy];
        [icon setScalesWhenResized:YES];
        [icon setSize:NSMakeSize(16, 16)];
        [item setImage:icon];
		 if ([theID isEqualToString:@"QSFileSystemObjectSource"]) {
            [[itemAddButton menu]insertItem:item atIndex:0];
            [[itemAddButton menu]insertItem:[NSMenuItem separatorItem] atIndex:1];  
        } else {
            [[itemAddButton menu]addItem:item];
        }
        
		
    }

    [itemTable setAutoresizesOutlineColumn:NO];

    [itemTable setAllowsMultipleSelection:NO];  
	// ***warning   * You need to get this working eventually.....
    [itemTable selectRow:0 byExtendingSelection:NO];

    [self updateCurrentItemContents];

    /*
     [librarian catalog] = [[NSMutableArray alloc] initWithContentsOfFile:[p stringByStandardizingPath]];
     if (![librarian catalog]) {
         [librarian catalog] = [[NSMutableArray alloc]initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"Items" ofType:@"plist"]];
     }
     if (![librarian catalog])
     [librarian catalog] = [[NSMutableArray alloc]initWithCapacity:1];
     */
    // NSTableColumn *tableColumn = nil;


    //NSImageCell *imageCell = nil;
    [itemTable reloadData];
    [itemTable setVerticalMotionCanBeginDrag: TRUE];
    [itemTable setAction:@selector(tableViewAction:)];
    [itemTable setDoubleAction:@selector(tableViewDoubleAction:)];
    // [itemTable setGridStyleMask:NSTableViewSolidHorizontalGridLineMask];
    [itemTable setRowHeight:17];

 //   QSImageAndTextCell *imageAndTextCell = [[[QSImageAndTextCell alloc]initTextCell:@""]autorelease];
//	[imageAndTextCell setEditable: YES];
//    [imageAndTextCell setWraps:NO];
//
//    [[itemTable tableColumnWithIdentifier: kItemName] setDataCell:imageAndTextCell];

    [itemTable registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, QSCodedCatalogEntryPasteboardType, nil]];
    [[[itemTable tableColumnWithIdentifier: kItemName]dataCell] setFont:[NSFont systemFontOfSize:11]];
    [[[itemTable tableColumnWithIdentifier: kItemPath]dataCell] setFont:[NSFont systemFontOfSize:11]];


    NSButtonCell *buttonCell = [[[QSCatalogSwitchButtonCell alloc] init] autorelease];
    [buttonCell setButtonType:NSSwitchButton];
    [buttonCell setImagePosition:NSImageOnly];
    [buttonCell setTitle:@""];
    [buttonCell setControlSize:NSSmallControlSize];
    [buttonCell setAllowsMixedState:YES];
    [[itemTable tableColumnWithIdentifier: kItemEnabled]setDataCell:buttonCell];
    [[itemTable tableColumnWithIdentifier: @"searched"]setDataCell:buttonCell];

    // [[[itemTable tableColumnWithIdentifier: kItemEnabled]dataCell]setAllowsMixedState:YES];

	[itemContentsTable setTarget:self];
	[itemContentsTable setDoubleAction:@selector(selectContentsItem:)];
    [itemContentsTable setRowHeight:34];

    QSObjectCell *objectCell = [[[QSObjectCell alloc] init] autorelease];

    //imageAndTextCell = [[[QSImageAndTextCell alloc] init] autorelease];
	//  [imageAndTextCell setWraps:NO];
    [[itemContentsTable tableColumnWithIdentifier: kItemName] setDataCell:objectCell];
    [[[itemContentsTable tableColumnWithIdentifier: kItemName]dataCell] setFont:[NSFont systemFontOfSize:11]];
    [[[itemContentsTable tableColumnWithIdentifier: kItemPath]dataCell] setFont:[NSFont labelFontOfSize:9]];
    [[[itemContentsTable tableColumnWithIdentifier: kItemPath]dataCell] setWraps:NO];


	//  if (0) [self hideCatalogOptions];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(catalogChanged:) name:QSCatalogEntryChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(catalogIndexed:) name:QSCatalogEntryIndexed object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateEntrySelection) name:NSOutlineViewSelectionDidChangeNotification object:nil];


    [itemTable reloadData];

    [itemTable selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
    [self updateEntrySelection];
}




- (IBAction)restoreDefaultCatalog:(id)sender {
    if (NSRunAlertPanel(@"Restore Defaults?", @"This will replace your current catalog setup with the default items", @"Replace", @"Cancel", nil) ) {
        [librarian loadDefaultCatalog];
        [itemTable reloadData];
        [itemTable deselectAll:sender];
    }
}

- (void)showOptionsDrawer {
    [itemOptionsTabView selectTabViewItemWithIdentifier:@"sourceoptions"];
    
    [itemContentsDrawer open:self];
}

- (void)handleURL:(NSURL *)url {
	[[self class] showEntryInCatalog:[QSLib entryForID:[url fragment]]];
}

+ (void)showEntryInCatalog:(QSCatalogEntry *)entry {
    [NSApp activateIgnoringOtherApps:YES];
	[QSPreferencesController showPaneWithIdentifier:@"QSCatalogPrefPane"];
	[[self sharedInstance]selectEntry:entry];
	
}

+ (void)addEntryForCatFile:(NSString *)path {
	[[self sharedInstance]addEntryForCatFile:path];
}
- (void)addEntryForCatFile:(NSString *)path {
	QSCatalogEntry *entry = [self entryForCatFile:path];
  
	NSMutableArray *insertionArray =  [[QSLib entryForID:@"QSCatalogCustom"] children];
  [insertionArray addObject:entry];
	[itemTable reloadData];
	[QSCatalogPrefPane showEntryInCatalog:entry];
}

- (void)selectIndexPath:(NSIndexPath *)ipath {
	[[itemTable window]makeFirstResponder:itemTable];
	[treeController setSelectionIndexPath:ipath];
}

- (void)selectEntry:(QSCatalogEntry *)entry {
	//if (VERBOSE)
	QSLog(@"entry %@ %@ %@", self, [entry catalogSetIndexPath], [entry catalogIndexPath]);
	id section = nil;
	NSArray *ancestors = [entry ancestors];
	if ([ancestors count] > 1)
		section = [ancestors objectAtIndex:1];
	else
		section = entry;
	QSLog(@"section %@", section);
	
	[catalogSetsController setSelectedObjects:[NSArray arrayWithObject:section]];
	
	[self selectIndexPath:[entry catalogSetIndexPath]];
}





- (IBAction)addSource:(id)sender {
    
    NSString *sourceString = nil;
    if (sender == itemAddButton)
        sourceString = @"QSFileSystemObjectSource";
    else if (sender == itemAddGroupButton)
        sourceString = @"QSGroupObjectSource";
    else
        sourceString = [sender representedObject];
    
    QSCatalogEntry *parentEntry = [[treeController selectedObjects]lastObject];
    if (!parentEntry || [parentEntry isPreset] || ![parentEntry isGroup] || [parentEntry isCatalog]) {
		
        parentEntry = [QSLib catalogCustom];
		[catalogSetsController setSelectedObjects:[NSArray arrayWithObject:parentEntry]];
	}
    
	//if (parentEntry) [parentEntry isPreset];
  //  QSLog(@"adding to %@", parentEntry);
//	NSIndexPath *ipath = [parentEntry catalogIndexPath];
	
    NSMutableDictionary *childDict = [NSMutableDictionary dictionaryWithCapacity:5];
    [childDict setObject:[NSString uniqueString] forKey:kItemID];
    [childDict setObject:[NSNumber numberWithBool:YES] forKey:kItemEnabled];
  	NSString *title = [[NSBundle bundleForClass:NSClassFromString(sourceString)]safeLocalizedStringForKey:sourceString value:sourceString table:@"QSObjectSource.name"];
	if ([title isEqualToString:sourceString]) title = [[NSBundle mainBundle]safeLocalizedStringForKey:sourceString value:sourceString table:@"QSObjectSource.name"];
	
	[childDict setObject:title forKey:kItemName];
    [childDict setObject:sourceString forKey:kItemSource];
    
    if ([sourceString isEqualToString:@"QSGroupObjectSource"])
        [childDict setObject:[NSMutableArray arrayWithCapacity:0] forKey:kItemChildren];
    
	QSCatalogEntry *childEntry = [QSCatalogEntry entryWithDictionary:childDict];
	[[parentEntry children]addObject:childEntry];
	[treeController rearrangeObjects];
    [itemTable reloadData];
	[self selectEntry:childEntry];
	
	// [self outlineView:itemTable addChild:childEntry toItem:parentEntry atIndex:-1];
	//  [treeController insertObject:childEntry atArrangedObjectIndexPath:[treeController selectionIndexPath]];
    // [librarian writeCatalog:self];
	
//    int row = [itemTable rowForItem:childEntry];
//    [itemTable selectRow:row byExtendingSelection:NO];
//    [itemTable scrollRowToVisible:row];
//    
    if ([sourceString isEqualToString:@"QSFileSystemObjectSource"]) {
        if (![(id)[QSReg sourceNamed:sourceString] chooseFile]) {
            [[parentEntry children]removeObject:childEntry];  
			
			[treeController rearrangeObjects];
            [itemTable reloadData];
            return;
        } else {
            [childEntry scanForced:YES];
        }
    }
	
    if (![sourceString isEqualToString:@"QSGroupObjectSource"])
        [self showOptionsDrawer];
	
    
	// [itemTable editColumn:0 row:row withEvent:nil select:NO];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogStructureChanged object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryChanged object:childEntry];
    
	//  [[itemTable window] makeFirstResponder:itemNameField];
    
    
	// ***warning   ** should i start editing this row?
	//	[self selectIndexPath:[ipath indexPathByAddingIndex:[[parentEntry children]count]-1]];
	// [itemTable selectRow:[[librarian catalog] count]-1 byExtendingSelection:NO];
    // [itemTable scrollRowToVisible:[[librarian catalog] count]-1];
}
- (IBAction)saveItem:(id)sender {
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	// QSLog(@"sub %@", [content subviews]);
	
	[savePanel setNameFieldLabel:@"Save Catalog:"];
	[savePanel setCanCreateDirectories:YES];
	[savePanel setRequiredFileType:@"qscatalogentry"];
	//if (![openPanel runModalForDirectory:oldFile file:nil types:nil]) return;
	//  beginSheetForDirectory:file:types:modalForWindow:modalDelegate:didEndSelector:contextInfo:
	NSMutableDictionary *item = [[currentItem mutableCopy]autorelease];
	[item removeObjectForKey:kItemID];
	[savePanel runModal];
	if ([savePanel filename])
		[[NSArray arrayWithObject:item] writeToFile:[savePanel filename] atomically:NO]; 	
}


//- (IBAction)removeItem:(id)sender {
//	
//    if ([[itemTable window]firstResponder] == itemTable && [itemTable numberOfSelectedRows]) {
//        
//        [self outlineView:itemTable removeRows:[itemTable selectedRowIndexes]];
//        [itemTable reloadData];
//		
//        [[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogStructureChanged object:nil];
//		//  [[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryChanged object:nil];
//        
//        [self updateEntrySelection];
//    }
//}

//- (NSIndexSet *)xoutlineView:(NSOutlineView *)outlineView rowIndexesForItems:(NSArray *)items {
//    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
//    int i;
//    for (i = 0; i < [items count]; i++) {
//        int index = [outlineView rowForItem:[items objectAtIndex:i]];
//        if (index >= 0)
//            [indexSet addIndex:index];
//    }
//    return indexSet;
//}
//
//- (BOOL)xoutlineView:(NSOutlineView *)outlineView removeVisibleItems:(NSArray *)items {
//    
//    return [self outlineView:outlineView removeRows:[self outlineView:outlineView rowIndexesForItems:items]];
//}
//
//
//- (id)xxoutlineView:(NSOutlineView *)outlineView parentOfRow:(int)row childIndex:(int *)index {
//    int level = [outlineView levelForRow:row];
//    int childIndex = 0;
//    int i;
//    for (i = row-1; i >= 0 && [outlineView levelForRow:i]>(level-1); i--) { // count sibling rows till hit parent row
//        if ([outlineView levelForRow:i] == level)
//            childIndex++;
//    }
//    
//    if (index) *index = childIndex;
//    
//    //        QSLog(@"%d %d", childIndex, i);
//    if (i < 0) return nil;
//    return [outlineView itemAtRow:i];  
//}
//
//- (BOOL)xoutlineView:(NSOutlineView *)outlineView removeRows:(NSIndexSet *)rows {
//    int row = [rows lastIndex];
//    int childIndex = 0;
//    
//    id parent = nil;
//    while(row != NSNotFound) {
//        parent = [self outlineView:outlineView parentOfRow:row childIndex:&childIndex];
//        [self outlineView:outlineView removeChild:childIndex ofItem:parent];
//        row = [rows indexLessThanIndex:row];
//    }    
//    return YES;
//}




//Outline Methods

- (int) numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == itemTable);
	//return [[librarian catalog] children]count];
    else if (tableView == itemContentsTable) {
        return [[self currentItemContents]count];
    }
    return 0;
}

- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(int) rowIndex
{
	//QSLog(@"tree %@", [treeController valueForKeyPath:@"selection.contents"]);
	if ([[aTableColumn identifier] isEqualToString: kItemEnabled]) {
		return [NSNumber numberWithBool:![QSLib itemIsOmitted:[[contentsController arrangedObjects] objectAtIndex:rowIndex]]];
		
    } else if ([[aTableColumn identifier] isEqualToString: kItemName]) {
		[(QSObject *)[[contentsController arrangedObjects] objectAtIndex:rowIndex]loadIcon];
		return [[contentsController arrangedObjects] objectAtIndex:rowIndex];
	}        
    return nil;  
}
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex {
	//    QSLog(@"select?");
	//    return NO;  
	return YES;
}
- (BOOL)tableView:(NSTableView *)aTableView rowIsSeparator:(int)rowIndex {
    return NO;
}

- (void)tableView:(NSTableView *)aTableView
   setObjectValue:anObject
   forTableColumn:(NSTableColumn *)aTableColumn
              row:(int) rowIndex
{
	
	if ([[aTableColumn identifier] isEqualToString: kItemEnabled]) {
		[QSLib setItem:[[contentsController arrangedObjects] objectAtIndex:rowIndex] isOmitted:![anObject boolValue]];
    }
    return;
}





- (void)updateCurrentItemContents {
	return;
    //QSLog(@"update contents");
    NSMutableArray *contents = [[[currentItem valueForKey:@"contents"]mutableCopy]autorelease];
    NSSortDescriptor *nameDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES] autorelease];
    [contents sortUsingDescriptors:[NSArray arrayWithObject:nameDescriptor]];
	
	
    [self setCurrentItemContents:contents];
    [itemContentsTable reloadData];
    //  int count = [currentItemContents count];
    // [currentItemContentsButton setEnabled:count];
    //[currentItemContentsButton setTitle:[NSString stringWithFormat:@"%d object%@", count, ESS(count)]];
}
- (IBAction)selectContentsItem:(id)sender {
	int row = [itemContentsTable clickedRow];
	id object = [[contentsController arrangedObjects]objectAtIndex:row];
	[QSCon receiveObject:object];
	//    if ([sender clickedRow] < 0) return;
	//    // [self updateEntrySelection];
	//    
	//    
	//	// ***warning   * this should use the true click delay!
	//    if ([[[[sender tableColumns]objectAtIndex:[sender clickedColumn]]identifier]isEqualToString:kItemName]) {
	//        NSEvent *theEvent = [NSApp nextEventMatchingMask:NSLeftMouseDownMask untilDate:[NSDate dateWithTimeIntervalSinceNow:0.5] inMode:NSDefaultRunLoopMode dequeue:YES];
	//        
	//        if (theEvent)
	//            //   [itemContentsDrawer open:self];
	//            [sender editColumn:[sender clickedColumn] row:[sender clickedRow] withEvent:[NSApp currentEvent] select:YES];
	//        
	//    }
}

//
- (BOOL)selectedCatalogEntryIsEditable {
	id source = [currentItem source];
	if ([source respondsToSelector:@selector(usesGlobalSettings)] && [source performSelector:@selector(usesGlobalSettings)])
		return YES;

	//  QSLog(@"isPreset? %d %d", DEBUG, [librarian entryIsPreset:currentItem]);
    return (![currentItem isPreset] || DEBUG);
}
- (void)updateEntrySelection {
    
    if ([itemTable numberOfSelectedRows] == 1) {
        id newItem = nil;
        
        if ([itemTable selectedRow] >= 0)
            newItem = [[treeController selectedObjects]lastObject]; //[itemTable itemAtRow:[itemTable selectedRow]];
			
			if (currentItem != newItem) {
				[librarian writeCatalog:self];
				[self setCurrentItem:newItem];
				// NSString *name = [currentItem objectForKey:kItemName];
				
				[self updateCurrentItemContents];
				[self populateCatalogEntryFields];
				
				//    NSString *theID = [currentItem objectForKey:kItemID];
				//   BOOL isPreset = theID && [theID hasPrefix:@"QSPreset"];
				
				id source = [currentItem source];
				
				NSView *settingsView = nil;
				currentItemHasSettings = NO;
				if ([source respondsToSelector:@selector(settingsView)])
					currentItemHasSettings = nil != (settingsView = [source settingsView]);
				if ([source respondsToSelector:@selector(setCurrentEntry:)])
					[source setCurrentEntry:[currentItem info]];
				if ([source respondsToSelector:@selector(setSelection:)])
					[source setSelection:currentItem];
				if ([source respondsToSelector:@selector(populateFields)])
					[source populateFields];
				
				
				if (settingsView) {
					[itemOptionsView setContentView:settingsView];
				} else {
					[messageTextField setStringValue:@"No Options"]  ;  
					[itemOptionsView setContentView:messageView];
				}
				//   [self populateItemFields];
			}
    }            
    else {
        [self setCurrentItem:nil];
        if ([itemTable numberOfSelectedRows] > 1)
            [messageTextField setStringValue:@"Multiple Items Selected"]   ;  
        else
            [messageTextField setStringValue:@"No Selection"]  ;  
        
        [self updateCurrentItemContents];
        [self populateCatalogEntryFields];
        
        [itemOptionsView setContentView:messageView];
    }  
    
    
	
    
    // [itemNameField setEnabled:!isPreset || DEBUG];
    //[itemIconField setEnabled:!isPreset || DEBUG];
    
    //[currentItemAddButton setEnabled:!isPreset || DEBUG];
    
    //  [currentItemDeleteButton setEnabled:(!isPreset || DEBUG) && [itemTable numberOfSelectedRows]];
    
    
}




- (int) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	return 0;
}
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item {
    if ([[NSApp currentEvent]type] == NSLeftMouseDragged) {
        return (![[item representedObject] isPreset]);
    }
    
    return YES;
}
//- (BOOL)xoutlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
//	
//    return  ![self outlineView:outlineView itemIsSeparator:item];  
//}
- (BOOL)outlineView:(NSOutlineView *)aTableView itemIsSeparator:(id)item {
	//int row = [aTableView rowForItem:item];
	//QSLog(@"%@", item);
	//QSLog(@"%@", [item indexPath]);
	//QSLog(@"%@", [[treeController arrangedObjects]objectAtIndexPath:[item indexPath]]);
	return NO;
    return [[[treeController arrangedObjects]objectAtIndexPath:[item indexPath]]isSeparator]; //[item valueForKey:@"isSeparator"];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {return NO;}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item {return nil;}
- (QSCatalogEntry *)catalog {
	return [librarian catalog];
}

//- (BOOL)xoutlineView:(NSOutlineView *)outlineView addChild:(id)childItem toItem:(id)item atIndex:(int)index {
//    if (![outlineView isItemExpanded:item]) {
//        item = [self outlineView:outlineView parentOfRow:[itemTable rowForItem:item] childIndex:&index];
//        //QSLog(@"redirecting to %@", item);
//    }
//    if (!item) item = [librarian catalog];
//    
//    NSMutableArray *childArray = [item children];
//    if (index >= 0 && index<[childArray count])
//        [childArray insertObject:childItem atIndex:index+1];
//    else
//        [childArray addObject:childItem];
//    
//    return YES;
//}
//
//- (BOOL)xoutlineView:(NSOutlineView *)outlineView removeChild:(int)index ofItem:(id)item {
//    if (!item) item = [librarian catalog];
//    if ([item isGroup]) {
//        [[item children]removeObjectAtIndex:index];
//    }
//    if (item != [librarian catalog])
//        [outlineView reloadItem:item reloadChildren:YES];
//    else
//        [outlineView reloadData];
//    return YES;
//}
//

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn*)tableColumn byItem:(id)item {
	return nil;
}

//- (void)xoutlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
//    if ([[tableColumn identifier] isEqualToString: kItemEnabled]) {
//        
//		//  QSLog(@"set value %@", object);
//        BOOL shouldBeEnabled = [object intValue]; / /= =-1);
//												// NSString *theID = [item objectForKey:kItemID];
//        if ([[NSApp currentEvent]modifierFlags]&NSAlternateKeyMask)  
//            [item setDeepEnabled:shouldBeEnabled];
//        else
//            [item setEnabled:shouldBeEnabled];
//		
//		
//        [item scanForced:NO];
//        [outlineView reloadData];
//		[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryChanged object:item];
//    }
//    else if ([[tableColumn identifier] isEqualToString: kItemName]) {
//        if ([object hasPrefix:@"QSPreset"]) {
//            if (DEBUG) {
//                [item setObject:object forKey:kItemID];
//                [item removeObjectForKey:kItemName];
//            }
//            
//        } else {
//            [item setObject:object forValue:[tableColumn identifier]];
//        }
//        
//    }
//    else
//        [item setObject:object forValue:[tableColumn identifier]];
//} 
//
//
//
//- (void)oxutlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
//	// theValue = [item objectForKey:[aTableColumn identifier]];
//	BOOL restricted = [item isRestricted];
//	
//	if ([[tableColumn identifier] isEqualToString: kItemName]) {
//		
//		NSString *theID = [item identifier];
//		
//		if (!iconCache)
//			iconCache = [[NSMutableDictionary alloc]init];
//		
//		NSImage *image = [iconCache objectForKey:theID];
//		
//		if (!image) {
//			image = [item icon];
//			[image createRepresentationOfSize:NSMakeSize(16, 16)];
//			[image setSize:NSMakeSize(16, 16)];
//			if (image && theID) [iconCache setObject:image forKey:theID];
//		}
//		
//		[(QSImageAndTextCell*)cell setImage: image];
//		
//		//  [cell setDrawsBackground:YES];
//		NSColor *textColor = [NSColor blackColor];
//		if ([item isPreset])
//			textColor = [textColor blendedColorWithFraction:0.5 ofColor:[NSColor blueColor]];
//		[cell setTextColor:textColor];
//		[cell setFont:([theID hasPrefix:@"QSPreset"]?[NSFont boldSystemFontOfSize:11]:[NSFont systemFontOfSize:11])];
//		
//		if (restricted) {
//			[cell setStringValue:UNSTABLE_STRING];
//			[cell setTextColor:[textColor blendedColorWithFraction:0.80 ofColor:[NSColor whiteColor]]];
//		}
//		
//		[cell setEnabled:!restricted];
//		
//	}
//	if ([[tableColumn identifier] isEqualToString: kItemEnabled] || [[tableColumn identifier] isEqualToString: @"count"]) {
//		
//		id parent;
//		int row = [outlineView rowForItem:item];
//		BOOL enabled = !restricted;
//		while ((parent = [self outlineView:outlineView parentOfRow:row childIndex:nil]) && enabled) {
//			row = [outlineView rowForItem:parent];
//			enabled = enabled && [parent isEnabled];
//		}
//		enabled = enabled && !restricted;
//		if ([[tableColumn identifier] isEqualToString: kItemEnabled])
//			[cell setEnabled:enabled];
//		if ([[tableColumn identifier] isEqualToString: @"count"])
//			[cell setTextColor:(enabled?[NSColor blackColor]:[NSColor grayColor])];
//		
//		
//		//     NSString *theID = [item objectForKey:kItemID];
//		
//		if ([[tableColumn identifier] isEqualToString: kItemEnabled] )
//			[cell setFalseMixedState:![item hasEnabledChildren]];
//		
//		
//		//   [[[itemTable tableColumnWithIdentifier: kItemEnabled]dataCell]setControlSize:[outlineView levelForItem:item]];
//		
//		
//		
//	}
//}
//
//
//
//- (BOOL)xoutlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
//	NSString *theID = [item identifier];
//	if ([theID hasPrefix:@"QSPreset"]) return (DEBUG);
//	
//	return YES;
//}


- (QSCatalogEntry *)entryForCatFile:(NSString *)path {
	return [QSCatalogEntry entryWithDictionary: [[NSArray arrayWithContentsOfFile:[path stringByStandardizingPath]]lastObject]];
}

- (QSCatalogEntry *)entryForDraggedFile:(NSString *)path {
	
	if ([[path pathExtension]isEqualToString:@"qscatalogentry"]) {
		return [self entryForCatFile:path];
		
	} else {
		NSMutableDictionary *settingsDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:path, kItemPath, nil];
		
		BOOL isDirectory; // Folders should have depth added automatically
		[[NSFileManager defaultManager]fileExistsAtPath:[path stringByStandardizingPath] isDirectory:&isDirectory];
		if (isDirectory && ![[NSWorkspace sharedWorkspace]isFilePackageAtPath:path]) {
			[settingsDict setObject:[NSNumber numberWithInt:1] forKey:@"folderDepth"];
			[settingsDict setObject:@"QSDirectoryParser" forKey:@"parser"];
		}
		
		NSMutableDictionary *entryDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
			[NSString uniqueString], kItemID,
			[NSNumber numberWithBool:YES], kItemEnabled,
			@"QSFileSystemObjectSource", kItemSource,
			settingsDict, kItemSettings,
			[[NSFileManager defaultManager] displayNameAtPath:path], kItemName,
			nil];
		return [QSCatalogEntry entryWithDictionary:entryDict];
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index {
	//id treeItem = item;
	//NSIndexPath *indexPath = [item indexPath];
	item = [item representedObject];
	//QSLog(@"item %@", item);
	if (!item)
		item = [QSLib entryForID:@"QSCatalogCustom"];
	
	
	
	NSMutableArray *insertionArray = (NSMutableArray *)[item children];
	if (!insertionArray) {
		insertionArray = [NSMutableArray arrayWithCapacity:0];
		[item setObject:insertionArray forKey:kItemChildren];
	}
	BOOL shouldShowOptions = NO;
	NSArray *objects = nil;
	if ([info draggingSource] == outlineView) {
		objects = draggedEntries; //[NSUnarchiver unarchiveObjectWithData:data];
		if (![item isPreset] || [info draggingSourceOperationMask] == NSDragOperationCopy)
			objects = [objects valueForKey:@"uniqueCopy"];
	} else { 
		// ***warning   * support dragging of multiple items
		QSCatalogEntry *entry = [self entryForDraggedFile:
			[[[[info draggingPasteboard]propertyListForType:NSFilenamesPboardType]objectAtIndex:0]stringByAbbreviatingWithTildeInPath]
			];
		if (!entry) {
			NSBeep(); 	
			return NO;
		}
		objects = [NSArray arrayWithObject:entry];
		
		[entry scanForced:YES];
		shouldShowOptions = YES;
	}
	
	
	if (index > 0 && [[insertionArray subarrayWithRange:NSMakeRange(0, index)]containsObject:[draggedEntries lastObject]])
		index--;
	
	//QSLog(@"mast %d", [info draggingSourceOperationMask]);
	if ([info draggingSourceOperationMask] == NSDragOperationMove
		 && [info draggingSource] == outlineView
		 && ![[draggedEntries objectAtIndex:0]isPreset]) {
		//	QSLog(@"dragged %@", draggedIndexPaths);
		[treeController removeObjectsAtArrangedObjectIndexPaths:draggedIndexPaths]; 	
	}
	
	//	QSLog(@"objects %@", objects);
	insertionArray = (NSMutableArray *)[item children];
	//	[treeController insertObject:[objects lastObject] atArrangedObjectIndexPath:indexPath];
	
	if (index >= 0) [insertionArray replaceObjectsInRange:NSMakeRange(index, 0) withObjectsFromArray:objects];
	else [insertionArray addObjectsFromArray:objects];
	
	[treeController rearrangeObjects];
	
	
	[outlineView reloadData];
	
	
	//[treeController setSelectionIndexPath:indexPath];
	
	[self selectEntry:[objects lastObject]];
	if (shouldShowOptions) {
		[self showOptionsDrawer];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogStructureChanged object:nil];
	return YES;
}


- (IBAction)copyPreset:(id)sender {
	NSMutableArray *insertionArray = [[QSLib catalogCustom] children];
	
	QSCatalogEntry *newItem = [currentItem uniqueCopy];
	[insertionArray addObject:newItem];
	
	[currentItem setEnabled:NO];
	[itemTable reloadData];
	[treeController rearrangeObjects];
	[self selectEntry:newItem];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogStructureChanged object:nil];
}




- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
	draggedIndexPaths = [items valueForKey:@"indexPath"];
	items = [items valueForKey:@"representedObject"];
	draggedEntries = items;
	
	if ([[items lastObject]isSeparator]) return NO;  
	
	//	if ([[items objectAtIndex:0]isPreset]&& 
	//		!([[NSApp currentEvent]modifierFlags]&NSAlternateKeyMask) && !DEBUG)
	//		return NO;
	
	[pboard declareTypes:[NSArray arrayWithObject:QSCodedCatalogEntryPasteboardType] owner:self];
	//[pboard setData:[NSArchiver archivedDataWithRootObject:draggedIndexPaths] forType:QSCodedCatalogEntryPasteboardType];
	// QSLog(@"write, %@", items);
	
	return YES;
	
}


- (NSDragOperation) outlineView:(NSOutlineView *)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index {
	item = [item representedObject];
	//NSString *theID = [item identifier];
	if ([item isSeparator]) return NO;  
	if ([item isPreset])
		return NSDragOperationNone;
	
	if ((!item && index != 0) || [item isGroup]) {
		if ([info draggingSource] == outlineView) {
			if ([draggedEntries containsObject:item])
				return NSDragOperationNone;
			
			if ([[NSSet setWithArray:[item ancestors]]intersectsSet:[NSSet setWithArray:draggedEntries]])
				return NSDragOperationNone;
			
			if ([[draggedEntries objectAtIndex:0] isPreset])
				return ([[NSApp currentEvent]modifierFlags]&NSAlternateKeyMask) ?NSDragOperationCopy:NSDragOperationNone;
		}
		
		return NSDragOperationMove;
	}
	return NSDragOperationNone;
}




- (void)populateCatalogEntryFields {
	//id source = [currentItem source];
	
	NSImage *image = [currentItem icon];
	
	//NSString *theID = [currentItem identifier];
	BOOL isPreset = [currentItem isPreset];
	
	
	[itemNameField setEnabled:(currentItem && !isPreset) || DEBUG];
	[itemIconField setEnabled:(currentItem && !isPreset) || DEBUG];
	
	// [currentItemAddButton setEnabled:!isPreset || DEBUG];
		[currentItemDeleteButton setEnabled:currentItem && (!isPreset || DEBUG)];
	
	if ([currentItem isRestricted]) {
		[itemNameField setStringValue:UNSTABLE_STRING];
	} else if (currentItem) {
		[itemNameField setStringValue:[currentItem name]];
	} else {
		[itemNameField setStringValue:@"No Selection"];
	}
	[itemIconField setImage:image];
} 

- (IBAction)setValueForSenderForCatalogEntry:(id)sender {
	if (sender == itemNameField) {
		if (0 && ([[NSApp currentEvent]modifierFlags] & NSAlternateKeyMask) )
			[[currentItem info] setObject:[sender stringValue] forKey:kItemSource];
		else    
			[[currentItem info] setObject:[sender stringValue] forKey:kItemName];
		[itemTable reloadData];
	}
	else if (sender == itemIconField) {
		
		NSData *imageData = [[sender image]TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:0];
		[[currentItem info] setObject:imageData forKey:kItemIcon];
		[itemTable reloadData];
	}
	//   else if (sender == searchRankModePopUp) {
	//       [defaults setInteger:[[sender selectedItem]tag] forKey:kRankMode];
	//   }
	
}




- (void)catalogChanged:(NSNotification *)notification {
	[itemTable reloadData];
}

- (void)catalogIndexed:(NSNotification *)notification {
	//QSLog(@"notobj:%@", [notification object]);
	
	if ([notification object] == currentItem);
	[self updateCurrentItemContents];
	
	[itemTable reloadItem:[notification object]];
	
	//int row = [itemTable rowForItem:[notification object]];
	//id parent = nil;
	//	while(row != NSNotFound) {
	//	parent = [self outlineView:itemTable parentOfRow:row childIndex:nil];
	//		if (parent) {
	//			[itemTable reloadItem:parent reloadChildren:NO];
	//			row = [itemTable rowForItem:parent];
	//		} else {
	//			row = NSNotFound;
	//		}
	//	}    
	
	// ***warning   * should update a group whose child changed
}

- (IBAction)rescanCurrentItem:(id)sender {
	[[itemTable window] makeFirstResponder:[itemTable window]];
	if (currentItem) {
		[currentItem scanForced:YES];
		[NSThread detachNewThreadSelector:@selector(scanForcedInThread:)
								 toTarget:currentItem withObject:self];
//		[[QSTaskController sharedInstance] removeTask:@"Scan"];
	} else {
		//[[QSLib catalog]scanForced:YES];
//		[NSThread detachNewThreadSelector:@selector(scanForcedInThread:)
//								 toTarget:currentItem withObject:self];
//		[QSLib startThreadedAndForcedScan];
	}
}

- (BOOL)windowShouldClose:(id)sender {
	//  QSLog(@"eep");
	[defaults synchronize];
	
	return YES;
}


- (IBAction)applySettings:(id)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryChanged object:nil];
	[(QSController *)[NSApp delegate]rescanItems:sender];
}







// Split view
//
//
//- (float) splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)offset {
//	//QSLog(@"constrainMax: %f, %d", proposedMax, offset);
//	return proposedMax-256;
//}
//
//- (float) splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)offset {
//	// QSLog(@"constrainMin: %f, %d", proposedMin, offset);  
//	return 256;
//}
//
//- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview {
//	return subview == [[sender subviews]lastObject];
//}
//
//- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize {
//	// QSLog(@"adjust with size %f", oldSize.width);
//	
//	[sender adjustSubviews];
//}
//
//- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification {
//	//     QSLog(@"split %f", NSWidth([[[catalogSplitView subviews]lastObject]frame]) /NSWidth([catalogSplitView frame]));
//	//    [defaults setObject:[NSNumber numberWithFloat:] forKey:@"CatalogEntryOptionsSplitSize"];
//}
//setAutoresizesSubviews
//
//
//-(IBAction)toggleCatalogOptions:(id)sender {
//	NSView *optionsView = [[catalogSplitView subviews]lastObject];
//	if ([optionsView frame].size.width  < 128) [self showCatalogOptions];
//	else [self hideCatalogOptions];
//}
//
//-(void)hideCatalogOptions {
//	//  [catalogSplitView _resizeViewsForOffset:1 coordinate:1000.0];
//	return;
//	//[catalogSplitView setAutoresizesSubviews:NO];
//	NSSize splitViewSize = [catalogSplitView frame].size;
//	NSView *tableView = [[catalogSplitView subviews]objectAtIndex:0];
//	NSView *optionsView = [[catalogSplitView subviews]lastObject];
//	float divider = [catalogSplitView dividerThickness];  
//	[tableView  setFrameSize:NSMakeSize(splitViewSize.width-divider, splitViewSize.height)];
//	
//	//[catalogSplitView replaceSubview:optionsView with:[[[NSView alloc]init]autorelease]];
//	//    [catalogSplitView adjustSubviews];
//	[optionsView setFrameOrigin:NSMakePoint(splitViewSize.width, 0)]; //NSMakeSize(0, splitViewSize.height)];
//	[catalogSplitView display];
//	
//}
//
//
//
//
//-(void)showCatalogOptions {
//    NSSize splitViewSize = [catalogSplitView frame].size;
//    float divider = [catalogSplitView dividerThickness];
//    NSView *optionsView = [[catalogSplitView subviews]lastObject];
//    //  float i;
//    
//    //  float oldWidth = [optionsView frame].size.width;
//    
//    float newWidth = 256;
//    [itemTable setFrameSize:NSMakeSize(splitViewSize.width-divider-newWidth, splitViewSize.height)];
//    [optionsView setFrameSize:NSMakeSize(newWidth, splitViewSize.height)];
//    [catalogSplitView adjustSubviews];
//    [catalogSplitView display];
//    
//}
//
//
//


//- (NSArray *)currentItemContents { return [currentItemContents count]?[NSArray arrayWithObject:[NSArray arrayWithObject:[currentItemContents lastObject]]]:nil;  }

- (NSArray *)currentItemContents { return [[currentItemContents retain] autorelease];  }

- (void)setCurrentItemContents:(NSArray *)newCurrentItemContents {
	//	QSLog(@"netcont %@", newCurrentItemContents);
    [currentItemContents release];
    currentItemContents = [newCurrentItemContents retain];
}


- (QSCatalogEntry *)currentItem { return currentItem;  }

- (void)setCurrentItem:(QSCatalogEntry *)newCurrentItem {
    [currentItem release];
    currentItem = [newCurrentItem retain];
}


//- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
//	[itemViewSwitcher selectItemAtIndex: [tabView indexOfTabViewItem:tabViewItem]];
//}


@end
