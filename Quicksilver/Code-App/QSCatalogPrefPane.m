#import "NSBundle_BLTRExtensions.h"
#import "QSCatalogPrefPane.h"
#import "QSPreferenceKeys.h"
#import "QSPreferencesController.h"
#import "QSObject.h"
#import "QSNotifications.h"
#import "QSObjectCell.h"
#import "QSRegistry.h"
#import "QSObjectSource.h"
#import "QSResourceManager.h"
#import "QSController.h"
#import "QSImageAndTextCell.h"
#import <QSFoundation/QSFoundation.h>
#import "QSNotifications.h"
#import "QSHandledSplitView.h"
#import "NSView+DisableSubviews.h"

#define COLUMNID_NAME		@"name"
#define COLUMNID_ENABLED	@"enabled"
#define COLUMNID_TYPE	 	@"TypeColumn"
#define COLUMNID_STATUS	 	@"StatusColumn"
#define UNSTABLE_STRING		@"(Unstable Entry) "

#import "QSTaskController.h"
//#import "QSCatalogSwitchButtonCell.h"
#import "QSFileSystemObjectSource.h"
#import "QSApp.h"
#import "QSBackgroundView.h"
#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>
#include <unistd.h>
#import "QSOutlineView.h"
#import "QSTableView.h"
#import "QSCatalogEntry_Private.h"

@interface QSObject (NSTreeNodePrivate)
//- (NSIndexPath *)indexPath;
- (id)observedObject;
//- (id)objectAtIndexPath:(NSIndexPath *)path;
@end
@implementation QSObject (NSTreeNodePrivate)
- (id)observedObject {return self;}
@end

@implementation QSCatalogPrefPane

static id _sharedInstance;

+ (id)sharedInstance {
	if (!_sharedInstance) _sharedInstance = [[[self class] alloc] init];
	return _sharedInstance;
}

- (id)preferencesSplitView { return [sidebar superview]; }

- (id)init {
	self = [super initWithBundle:[NSBundle bundleForClass:[self class]]];
	if (!_sharedInstance) _sharedInstance = self;
	if (self) {
		[self setCurrentItem:nil];
		currentItemContents = nil;
	}
	return self;
}

- (NSView *)loadMainView {
	NSView *oldMainView = [super loadMainView];
	
	NSSplitView *splitView = [[QSHandledSplitView alloc] init];
	[splitView setVertical:YES];
	[splitView addSubview:sidebar];
	[splitView addSubview:oldMainView];

	_mainView = splitView;
	return _mainView;
}

- (NSString *)mainNibName { return @"QSCatalog"; }

- (void)paneLoadedByController:(id)controller {
	[itemContentsDrawer setParentWindow:[controller window]];
	[itemContentsDrawer setLeadingOffset:48];
	[itemContentsDrawer setTrailingOffset:24];
	[itemContentsDrawer setPreferredEdge:NSMaxXEdge];
}

- (void)willUnselect { [itemContentsDrawer close]; }

- (void)awakeFromNib {
	[catalogSetsTable setBackgroundColor:[NSColor colorWithCalibratedHue:.60277777777777777777f saturation:0.070000f brightness:0.970000f alpha:1.000000f]];
	NSColor *highlightColor = [NSColor colorWithCalibratedHue:.60277777777777777777f saturation:0.740000f brightness:0.84f alpha:1.000000f];

	[(QSTableView *)catalogSetsTable setHighlightColor:highlightColor];
	[(QSOutlineView *)itemTable setHighlightColor:highlightColor];
	[(QSTableView *)itemContentsTable setHighlightColor:highlightColor];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(catalogCacheChanged:) name:@"CatalogCacheChanged" object:nil];
	NSArray *sources = [[[QSReg objectSources] allKeys] copy];

	NSMenuItem *item;
	NSImage *icon;
	NSMenu *itemAddButtonMenu = [[NSMenu alloc] initWithTitle:@"Sources"];
	[itemAddButton setMenu:itemAddButtonMenu];

    [itemAddButton setKeyEquivalent:@"+"];
    [itemRemoveButton setKeyEquivalent:@"-"];
    [infoButton setKeyEquivalent:@"i"];
    [refreshButton setKeyEquivalent:@"r"];
    for (NSButton *aButton in [NSArray arrayWithObjects:itemAddButton,itemRemoveButton,infoButton,refreshButton, nil]) {
        [aButton setKeyEquivalentModifierMask:NSCommandKeyMask];
    }
    
	for (NSString *theID in sources) {
		id source = [[QSReg objectSources] objectForKey:theID];
		if (!([source respondsToSelector:@selector(isVisibleSource)]
			  && [source isVisibleSource]))
			continue;
		NSString *title = [[NSBundle bundleForClass:[source class]] safeLocalizedStringForKey:theID value:theID table:@"QSObjectSource.name"];
		if ([title isEqualToString:theID])
			title = [[NSBundle mainBundle] safeLocalizedStringForKey:theID value:theID table:@"QSObjectSource.name"];
		item = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
		[item setRepresentedObject:theID];
		[item setTarget:self];
		[item setAction:@selector(addSource:)];
		icon = [[source iconForEntry:nil] copy];
		[icon setSize:QSSize16];
		[item setImage:icon];
		 if ([theID isEqualToString:@"QSFileSystemObjectSource"]) {
			[[itemAddButton menu] insertItem:item atIndex:0];
			[[itemAddButton menu] insertItem:[NSMenuItem separatorItem] atIndex:1];
		} else {
			[[itemAddButton menu] addItem:item];
		}
	}


	[itemTable setAutoresizesOutlineColumn:NO];
	[itemTable setAllowsMultipleSelection:NO];
	[itemTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    //[itemTable selectRow:0 byExtendingSelection:NO];

/*[self updateCurrentItemContents];*/[itemContentsTable reloadData];

//	[itemTable reloadData];
	[itemTable setVerticalMotionCanBeginDrag:TRUE];
	[itemTable setRowHeight:17];

	[itemTable registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, QSCodedCatalogEntryPasteboardType, nil]];
	[[[itemTable tableColumnWithIdentifier: kItemName] dataCell] setFont:[NSFont systemFontOfSize:11]];
	[[[itemTable tableColumnWithIdentifier: kItemPath] dataCell] setFont:[NSFont systemFontOfSize:11]];

//	NSButtonCell *buttonCell = [[QSCatalogSwitchButtonCell alloc] init];
	NSButtonCell *buttonCell = [[NSButtonCell alloc] init];
	[buttonCell setButtonType:NSSwitchButton];
	[buttonCell setImagePosition:NSImageOnly];
	[buttonCell setTitle:@""];
	[buttonCell setControlSize:NSSmallControlSize];
	[buttonCell setAllowsMixedState:YES];
	[[itemTable tableColumnWithIdentifier:kItemEnabled] setDataCell:buttonCell];
	[[itemTable tableColumnWithIdentifier:@"searched"] setDataCell:buttonCell];

	[itemContentsTable setTarget:self];
	[itemContentsTable setDoubleAction:@selector(selectContentsItem:)];
	[itemContentsTable setRowHeight:34];

	QSObjectCell *objectCell = [[QSObjectCell alloc] init];
	[[itemContentsTable tableColumnWithIdentifier:kItemName] setDataCell:objectCell];
	[[[itemContentsTable tableColumnWithIdentifier:kItemName] dataCell] setFont:[NSFont systemFontOfSize:11]];
	[[[itemContentsTable tableColumnWithIdentifier:kItemPath] dataCell] setFont:[NSFont labelFontOfSize:9]];
	[[[itemContentsTable tableColumnWithIdentifier:kItemPath] dataCell] setWraps:NO];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(catalogChanged:) name:QSCatalogEntryChangedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(catalogIndexed:) name:QSCatalogEntryIndexedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateEntrySelection) name:NSOutlineViewSelectionDidChangeNotification object:nil];

	[itemTable reloadData];
    
    // !!! Andre Berg 20091015:  an empty index set will deselect everything? Is this intended here?
	//[itemTable selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
	[self updateEntrySelection];
}


- (IBAction)removeItem:(id)sender {
//    remove the item from the tree controller
    [treeController remove:sender];
//    Write the catalog to save the changes
    [QSLib writeCatalog:sender];
}

- (IBAction)restoreDefaultCatalog:(id)sender {
	if (NSRunAlertPanel(@"Restore Defaults?", @"This will replace your current catalog setup with the default items", @"Replace", @"Cancel", nil) ) {
		[[QSLibrarian sharedInstance] loadDefaultCatalog];
		[itemTable reloadData];
		[itemTable deselectAll:nil];
	}
}

- (void)showOptionsDrawer {
	[itemOptionsTabView selectTabViewItemWithIdentifier:@"sourceoptions"];
	[itemContentsDrawer open:nil];
}

- (void)handleURL:(NSURL *)url {
	[[self class] showEntryInCatalog:[[QSLibrarian sharedInstance] entryForID:[url fragment]]];
}

+ (void)showEntryInCatalog:(QSCatalogEntry *)entry {
	[NSApp activateIgnoringOtherApps:YES];
	[QSPreferencesController showPaneWithIdentifier:@"QSCatalogPrefPane"];
	[[self sharedInstance] selectEntry:entry];
}

+ (void)addEntryForCatFile:(NSString *)path {
	[[self sharedInstance] addEntryForCatFile:path];
}

- (void)addEntryForCatFile:(NSString *)path {
	QSCatalogEntry *entry = [self entryForCatFile:path];
	[[[[QSLibrarian sharedInstance] entryForID:@"QSCatalogCustom"] children] addObject:entry];
	[itemTable reloadData];
	[QSCatalogPrefPane showEntryInCatalog:entry];
}

- (void)selectIndexPath:(NSIndexPath *)ipath {
	[[itemTable window] makeFirstResponder:itemTable];
	[treeController setSelectionIndexPath:ipath];
}

- (void)selectEntry:(QSCatalogEntry *)entry {
	id section;
	NSArray *ancestors = [entry ancestors];
	if ([ancestors count] > 1)
		section = [ancestors objectAtIndex:1];
	else
		section = entry;
	[catalogSetsController setSelectedObjects:[NSArray arrayWithObject:section]];
	[self selectIndexPath:[entry catalogSetIndexPath]];
}

- (IBAction)addSource:(id)sender {
	NSString *sourceString;
	if (sender == itemAddButton)
		sourceString = @"QSFileSystemObjectSource";
	else
		sourceString = [sender representedObject];
	QSCatalogEntry *parentEntry = [[treeController selectedObjects] lastObject];
	if (!parentEntry || [parentEntry isPreset] || ![parentEntry isGroup] || [parentEntry isCatalog]) {
		parentEntry = [[QSLibrarian sharedInstance] catalogCustom];
		[catalogSetsController setSelectedObjects:[NSArray arrayWithObject:parentEntry]];
	}

	NSMutableDictionary *childDict = [NSMutableDictionary dictionaryWithCapacity:5];
	[childDict setObject:[NSString uniqueString] forKey:kItemID];
	[childDict setObject:[NSNumber numberWithBool:YES] forKey:kItemEnabled];
 	NSString *title = [[NSBundle bundleForClass:NSClassFromString(sourceString)] safeLocalizedStringForKey:sourceString value:sourceString table:@"QSObjectSource.name"];
	if ([title isEqualToString:sourceString])
		title = [[NSBundle mainBundle] safeLocalizedStringForKey:sourceString value:sourceString table:@"QSObjectSource.name"];

	[childDict setObject:title forKey:kItemName];
	[childDict setObject:sourceString forKey:kItemSource];

	if ([sourceString isEqualToString:@"QSGroupObjectSource"])
		[childDict setObject:[NSMutableArray arrayWithCapacity:0] forKey:kItemChildren];

	QSCatalogEntry *childEntry = [QSCatalogEntry entryWithDictionary:childDict];
	[[parentEntry children] addObject:childEntry];
    [self reloadData];
	[self selectEntry:childEntry];

	if ([sourceString isEqualToString:@"QSFileSystemObjectSource"]) {
		if (![(QSFileSystemObjectSource *)[QSReg sourceNamed:sourceString] chooseFile]) {
			[[parentEntry children] removeObject:childEntry];

			[treeController rearrangeObjects];
			[itemTable reloadData];
			return;
		} else {
			[childEntry scanForced:YES];
		}
	}

	if (![sourceString isEqualToString:@"QSGroupObjectSource"])
		[self showOptionsDrawer];

	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogStructureChanged object:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryChangedNotification object:childEntry];
}

- (IBAction)saveItem:(id)sender {
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setNameFieldLabel:@"Save Catalog:"];
	[savePanel setCanCreateDirectories:YES];
	[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"qscatalogentry"]];
	[savePanel runModal];
	if ([savePanel URL]){
		NSMutableDictionary *item = [currentItem mutableCopy];
		[item removeObjectForKey:kItemID];
		[[NSArray arrayWithObject:item] writeToURL:[savePanel URL] atomically:NO];
	}
}

//Outline Methods

#if 0
- (void)updateCurrentItemContents {
	return;
	//NSLog(@"update contents");
	NSMutableArray *contents = [[[currentItem valueForKey:@"contents"] mutableCopy] autorelease];
	NSSortDescriptor *nameDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES] autorelease];
	[contents sortUsingDescriptors:[NSArray arrayWithObject:nameDescriptor]];
	[self setCurrentItemContents:contents];
	[itemContentsTable reloadData];
}
#endif

- (IBAction)selectContentsItem:(id)sender {
    if ([itemContentsTable clickedRow] == -1) {
        return;
    }
    if ([itemContentsTable clickedRow] < (NSInteger)[(NSArray *)[contentsController arrangedObjects] count]) {
        [QSCon receiveObject:[[contentsController arrangedObjects] objectAtIndex:[itemContentsTable clickedRow]]];
    }
}

- (BOOL)selectedCatalogEntryIsEditable {
	id source = [currentItem source];
	if ([source respondsToSelector:@selector(usesGlobalSettings)] && [source performSelector:@selector(usesGlobalSettings)])
		return YES;
	else
		return (![currentItem isPreset]);
}

- (void)updateEntrySelection {
	if ([itemTable numberOfSelectedRows] == 1) {
        [infoButton setEnabled:YES];
        [refreshButton setEnabled:YES];
		id newItem = nil;
		if ([itemTable selectedRow] >= 0)
			newItem = [[treeController selectedObjects] lastObject];
		if (currentItem != newItem) {
			[self setCurrentItem:newItem];
/* [self updateCurrentItemContents];*/ [itemContentsTable reloadData];
			[self populateCatalogEntryFields];
			id source = [currentItem source];
			NSView *settingsView = nil;
			currentItemHasSettings = NO;
			if ([source respondsToSelector:@selector(settingsView)])
				currentItemHasSettings = nil != (settingsView = [source settingsView]);

			// Make the object source edit the currently selected entry
			// The various names are here because of back-compat
			if ([source respondsToSelector:@selector(setSelectedEntry:)]) {
				[source setSelectedEntry:currentItem];
			} else if ([source respondsToSelector:@selector(setSelection:)]) {
				[source setSelection:currentItem];
			} else if ([source respondsToSelector:@selector(setCurrentEntry:)]) {
				[source setCurrentEntry:[currentItem info]];
			}

			if ([source respondsToSelector:@selector(populateFields)])
				[source populateFields];
			if (settingsView) {
                [settingsView disableSubviews:![currentItem isEditable]];
				[itemOptionsView setContentView:settingsView];
			} else {
				[messageTextField setStringValue:@"No Options"];
				[itemOptionsView setContentView:messageView];
			}
		}
	} else {
		[self setCurrentItem:nil];
		if ([itemTable numberOfSelectedRows] > 1) {
            [infoButton setEnabled:NO];
            [refreshButton setEnabled:YES];
			[messageTextField setStringValue:@"Multiple Items Selected"];
        }
		else {
			[messageTextField setStringValue:@"No Selection"];
            [infoButton setEnabled:NO];
            [refreshButton setEnabled:NO];
        }

//		/*[self updateCurrentItemContents];*/[itemContentsTable reloadData];
		[self populateCatalogEntryFields];
		[itemOptionsView setContentView:messageView];
	}
}

- (NSInteger) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item { return 0; }

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item {
	if ([[NSApp currentEvent] type] == NSLeftMouseDragged) {
		return (![[item respondsToSelector:@selector(representedObject)] ? [item representedObject] : [item observedObject] isPreset]);
	}
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)aTableView itemIsSeparator:(id)item { return NO; }

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item { return NO; }

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item { return nil; }

- (QSCatalogEntry *)catalog { return [[QSLibrarian sharedInstance] catalog]; }

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn*)tableColumn byItem:(id)item { return nil; }

- (QSCatalogEntry *)entryForCatFile:(NSString *)path {
	return [QSCatalogEntry entryWithDictionary: [[NSArray arrayWithContentsOfFile:[path stringByStandardizingPath]]lastObject]];
}

- (QSCatalogEntry *)entryForDraggedFile:(NSString *)path {
	if ([[path pathExtension] isEqualToString:@"qscatalogentry"])
		return [self entryForCatFile:path];
	else {
		NSMutableDictionary *settingsDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:path, kItemPath, nil];

		BOOL isDirectory; // Folders should have depth added automatically
		[[NSFileManager defaultManager] fileExistsAtPath:[path stringByStandardizingPath] isDirectory:&isDirectory];
		if (isDirectory && ![[NSWorkspace sharedWorkspace] isFilePackageAtPath:path]) {
			[settingsDict setObject:[NSNumber numberWithInteger:1] forKey:@"folderDepth"];
			[settingsDict setObject:@"QSDirectoryParser" forKey:@"parser"];
		}
		return [QSCatalogEntry entryWithDictionary:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSString uniqueString], kItemID, [NSNumber numberWithBool:YES], kItemEnabled, @"QSFileSystemObjectSource", kItemSource, settingsDict, kItemSettings, [[NSFileManager defaultManager] displayNameAtPath:path], kItemName, nil]];
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index {
	item = [item respondsToSelector:@selector(representedObject)] ?[item representedObject] :[item observedObject];
	if (!item)
		item = [[QSLibrarian sharedInstance] entryForID:@"QSCatalogCustom"];

	NSMutableArray *insertionArray = (NSMutableArray *)[item children];
	if (!insertionArray) {
		insertionArray = [NSMutableArray arrayWithCapacity:0];
		[item setObject:insertionArray forKey:kItemChildren];
	}
	BOOL shouldShowOptions = NO;
	NSArray *objects = nil;
	if ([info draggingSource] == outlineView) {
		objects = draggedEntries;
		if (![item isPreset] || [info draggingSourceOperationMask] == NSDragOperationCopy)
			objects = [objects valueForKey:@"uniqueCopy"];
	} else {
		// FIXME: ***warning  * support dragging of multiple items
		QSCatalogEntry *entry = [self entryForDraggedFile:[[[[info draggingPasteboard] propertyListForType:NSFilenamesPboardType] objectAtIndex:0] stringByAbbreviatingWithTildeInPath]];
		if (!entry) {
			NSBeep();
			return NO;
		}
		objects = [NSArray arrayWithObject:entry];
		[entry scanForced:YES];
		shouldShowOptions = YES;
	}

	if (index>0 && [[insertionArray subarrayWithRange:NSMakeRange(0, index)] containsObject:[draggedEntries lastObject]])
		index--;

	if ([info draggingSourceOperationMask] == NSDragOperationMove
		 && [info draggingSource] == outlineView
		 && ![[draggedEntries objectAtIndex:0] isPreset]) {
		[treeController removeObjectsAtArrangedObjectIndexPaths:draggedIndexPaths];
	}

	insertionArray = (NSMutableArray *)[item children];

	if (index >= 0) [insertionArray replaceObjectsInRange:NSMakeRange(index, 0) withObjectsFromArray:objects];
	else [insertionArray addObjectsFromArray:objects];

	[treeController rearrangeObjects];
	[outlineView reloadData];

	[self selectEntry:[objects lastObject]];
	if (shouldShowOptions)
		[self showOptionsDrawer];

	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogStructureChanged object:nil];
	return YES;
}

- (IBAction)copyPreset:(id)sender {
	QSCatalogEntry *newItem = [currentItem uniqueCopy];
	[[[[QSLibrarian sharedInstance] catalogCustom] children] addObject:newItem];
	[currentItem setEnabled:NO];
    [self reloadData];
	[self selectEntry:newItem];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogStructureChanged object:nil];
}

-(void)reloadData {
    [treeController rearrangeObjects];
    QSGCDMainAsync(^{
        [itemTable reloadData];
    });
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
	draggedIndexPaths = [items valueForKey:@"indexPath"];
	items = ([items count] && [[items lastObject] respondsToSelector:@selector(representedObject)])?[items valueForKey:@"representedObject"] : [items valueForKey:@"observedObject"];
	draggedEntries = items;
	if ([[items lastObject] isSeparator])
		return NO;
	//	if ([[items objectAtIndex:0] isPreset] &&
	//		!([[NSApp currentEvent] modifierFlags] &NSAlternateKeyMask) && !DEBUG)
	//		return NO;
	[pboard declareTypes:[NSArray arrayWithObject:QSCodedCatalogEntryPasteboardType] owner:self];
//	[pboard setData:[NSArchiver archivedDataWithRootObject:draggedIndexPaths] forType:QSCodedCatalogEntryPasteboardType];
//	NSLog(@"write, %@", items);
	return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
	item = [item respondsToSelector:@selector(representedObject)] ? [item representedObject] : [item observedObject];
	if ([item isSeparator])
		return NO;
	else if ([item isPreset])
		return NSDragOperationNone;
	else if ((!item && index != 0) || [item isGroup]) {
		if ([info draggingSource] == outlineView) {
			if ([draggedEntries containsObject:item])
				return NSDragOperationNone;
			if ([[NSSet setWithArray:[item ancestors]] intersectsSet:[NSSet setWithArray:draggedEntries]])
				return NSDragOperationNone;
			if ([[draggedEntries objectAtIndex:0] isPreset])
				return ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) ? NSDragOperationCopy : NSDragOperationNone;
		}
		return NSDragOperationMove;
	}
	return NSDragOperationNone;
}

- (void)populateCatalogEntryFields {
	
#ifdef DEBUG
	[itemIconField setEnabled:YES];
#endif
	
	[itemIconField setEnabled:(currentItem && ![currentItem isPreset])];
	[itemIconField setImage:[currentItem icon]];
}

- (IBAction)setValueForSenderForCatalogEntry:(id)sender {
	if (sender == itemIconField) {
        currentItem.icon = [sender image];
		[itemTable reloadData];
	}
}

- (void)catalogChanged:(NSNotification *)notification {
    QSGCDMainAsync(^{
        [itemTable reloadData];
    });
}

- (void)catalogIndexed:(NSNotification *)notification {
    QSGCDMainAsync(^{
        [itemContentsTable reloadData];
        [itemTable reloadData];
    });
}

- (IBAction)rescanCurrentItem:(id)sender {
	if (currentItem) {
        QSGCDAsync(^{
            [currentItem scanForced:YES];
        });
	}
}

- (BOOL)windowShouldClose:(id)sender {
	// NSLog(@"eep");
	[[NSUserDefaults standardUserDefaults] synchronize];

	return YES;
}

- (IBAction)applySettings:(id)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryChangedNotification object:nil];
	[(QSController *)[NSApp delegate] rescanItems:sender];
}

//- (NSArray *)currentItemContents { return [currentItemContents count] ?[NSArray arrayWithObject:[NSArray arrayWithObject:[currentItemContents lastObject]]] :nil;  }

- (NSArray *)currentItemContents { return currentItemContents;  }
- (void)setCurrentItemContents:(NSArray *)newCurrentItemContents {
	currentItemContents = newCurrentItemContents;
}

- (QSCatalogEntry *)currentItem { return currentItem;  }

- (void)setCurrentItem:(QSCatalogEntry *)newCurrentItem {
	currentItem = newCurrentItem;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
