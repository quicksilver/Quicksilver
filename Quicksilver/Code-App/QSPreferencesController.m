#import "QSPreferencesController.h"
#import "QSKeys.h"
#import "QSObject.h"
#import "QSRegistry.h"
#import "QSObjectSource.h"
#import "QSResourceManager.h"
#import "QSController.h"
#import "QSImageAndTextCell.h"
#define COLUMNID_NAME		@"name"
#define COLUMNID_TYPE	 	@"TypeColumn"
#define COLUMNID_STATUS	 	@"StatusColumn"
#define UNSTABLE_STRING		@"(Unstable Entry) "
#define QSPasteboardType @"QSPastebardType"
#import "QSTitleToolbarItem.h"
#import "QSNotifications.h"
#import "NTViewLocalizer.h"
#import "QSMacros.h"

#import "QSTableView.h"

#import "QSApp.h"
#import "QSBackgroundView.h"
#include <PreferencePanes/PreferencePanes.h>

#import "QSPreferencePane.h"
#import "NSBundle_BLTRExtensions.h"
#include <unistd.h>

@interface NSWindow (NSTrackingRectsPrivate)
- (void)_hideAllDrawers;
@end

id QSPrefs;
@implementation QSPreferencesController
+ (id)sharedInstance {
	if (!QSPrefs)
		QSPrefs = [[[self class] allocWithZone:[self zone]] init];
	return QSPrefs;
}

+ (void)initialize {
	[self setKeys:[NSArray arrayWithObject:@"currentItem"] triggerChangeNotificationsForDependentKey:@"selectedCatalogEntryIsEditable"];
}

+ (void)showPrefs {
	[NSApp activateIgnoringOtherApps:YES];
	[[self sharedInstance] showWindow:nil];
}

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification {
	float width = NSWidth([[[[aNotification object] subviews] objectAtIndex:0] frame]);
	//NSLog(@"width %f", width);
	[[NSUserDefaults standardUserDefaults] setFloat:width forKey:kQSPreferencesSplitWidth];
}

- (id)init {
	self = [super initWithWindowNibName:@"QSPreferences"];
	if (self) {
		modulesByID = [[NSMutableDictionary alloc] init];
		modules = [[NSMutableArray alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillRelaunch:) name:QSApplicationWillRelaunchNotification object:nil];
	}
	return self;
}

- (void)applicationWillRelaunch:(NSNotification *)notif {
	id theID;
	if (theID = [[[moduleController selectedObjects] lastObject] objectForKey:kItemID])
		setenv("QSVisiblePrefPane", [theID UTF8String] , YES);
}

- (void)awakeFromNib {
	[[self window] setDelegate:self];
	[loadingProgress setUsesThreadedAnimation:YES];

	[(QSTableView *)internalPrefsTable setOpaque:NO];
	[(QSTableView *)internalPrefsTable setHighlightColor:[NSColor grayColor]];
	[internalPrefsTable setBackgroundColor:[NSColor colorWithDeviceWhite:0.95 alpha:1.0]];
	[[internalPrefsTable enclosingScrollView] setDrawsBackground:NO];
	[self setWindowTitleWithInfo:nil];
	//[settingsSplitView setDrawsDivider:NO];
	[settingsSplitView setVertical:YES];
	[settingsSplitView addSubview:sidebarView];
	[settingsSplitView addSubview:settingsView];
	[settingsSplitView adjustSubviews];
	[self setShowSettings:YES];
}

- (void)preventEmptySelection {
	[externalPrefsTable setAllowsEmptySelection:NO];
	[moduleController setAvoidsEmptySelection:YES];
	if ([moduleController selectionIndex] == NSNotFound)
		[moduleController setSelectionIndex:0];
}

+ (QSPreferencePane *)showPaneWithIdentifier:(NSString *)identifier {
	return [[self sharedInstance] showPaneWithIdentifier:identifier];
}

- (QSPreferencePane *)showPaneWithIdentifier:(NSString *)identifier {
	[NSApp activateIgnoringOtherApps:YES];
	[self showWindow:nil];
	[self selectPaneWithIdentifier:identifier];
//	int index = [[modules valueForKey:kItemID] indexOfObject:identifier];
//	if (index == NSNotFound) {
//		NSLog(@"%@ not found", identifier);
//	} else {
//		[moduleController setSelectionIndex:index];
//		return [self currentPane];
//	}
	//	[internalPrefsTable selectRow:index byExtendingSelection:NO];
	//[win makeKeyAndOrderFront:win];
	return nil;
}

- (void)reloadPlugInInfo:(NSNotification *)notif {
	reloading = YES;
	[self loadPlugInInfo:notif];
	reloading = NO;
}

- (void)loadPlugInInfo:(NSNotification *)notif {
	//	NSString *currentPaneID = nil;
	//	if ([modules count] && [internalPrefsTable selectedRow] >= 0)
	//		currentPaneID = [[modules objectAtIndex:[internalPrefsTable selectedRow]]objectForKey:kItemID];

	//	NSArray *loadedPanes = [modules valueForKey:kItemID];
//	[QSReg printRegistry:nil];
	NSDictionary *plugInPanes = [QSReg tableNamed:kQSPreferencePanes];
//	NSLog(@"plug %@", plugInPanes);
	for(NSString *paneKey in plugInPanes) {
		if ([modulesByID objectForKey:paneKey]) continue;
		//if ([loadedPanes containsObject:paneKey]) continue;
		NSMutableDictionary *paneInfo = [[[plugInPanes objectForKey:paneKey] mutableCopy] autorelease];
		if ([paneInfo isKindOfClass:[NSString class]]) {
			//NSLog(@"Not Loading Old-Style Prefs: %@", paneInfo);
			continue;
		}

		NSString *imageName = [paneInfo objectForKey:@"icon"];
		NSImage *image = [[QSResourceManager imageNamed:imageName] copy];
		if (image) {
			[image createIconRepresentations];
			[paneInfo setObject:image forKey:@"image"];
		}
		[image release];
		if ([paneInfo objectForKey:@"name"])
			[paneInfo setObject:[paneInfo objectForKey:@"name"] forKey:@"text"];
		[paneInfo setObject:paneKey forKey:kItemID];
		//	NSPreferencePane * obj = [QSReg getClassInstance:paneClass];
		if (paneInfo) {
			[modulesByID setObject:paneInfo forKey:paneKey];
			//[newModules addObject:paneInfo];
		}
	}

	NSSortDescriptor *nameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
	NSSortDescriptor *orderDescriptor = [[NSSortDescriptor alloc] initWithKey:@"priority" ascending:NO];
	NSMutableArray *sidebarModules = [[[[modulesByID allValues] sortedArrayUsingDescriptors:[NSArray arrayWithObjects:orderDescriptor, nameDescriptor, nil]] mutableCopy] autorelease];
	[nameDescriptor release]; [orderDescriptor release];
	[sidebarModules filterUsingPredicate:[NSPredicate predicateWithFormat:@"not type like[cd] 'toolbar'"]];
	[sidebarModules filterUsingPredicate:[NSPredicate predicateWithFormat:@"not type like[cd] 'hidden'"]];
	NSArray *plugInModules = [sidebarModules filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"not type like[cd] 'main'"]];
	[sidebarModules removeObjectsInArray:plugInModules];

	[sidebarModules addObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"separator"]];
	[sidebarModules addObjectsFromArray:plugInModules];
	id mSidebarModules = [sidebarModules mutableCopy];
	[self setModules:mSidebarModules];
	[mSidebarModules release];
	//	int index = [[modules valueForKey:kItemID] indexOfObject:currentPaneID];
	//	if (index != NSNotFound) [internalPrefsTable selectRow:index byExtendingSelection:NO];
	//
	//	[internalPrefsTable reloadData];
	//	[self selectModule:self];
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectModule:) name:NSTableViewSelectionDidChangeNotification object:internalPrefsTable];
	//	NSCell *imageAndTextCell;
	//	[internalPrefsTable setRowHeight:17];
	//	imageAndTextCell = [[[QSImageAndTextCell alloc] init] autorelease];
	//	[[internalPrefsTable tableColumnWithIdentifier: kItemName] setDataCell:imageAndTextCell];
	//	[[[internalPrefsTable tableColumnWithIdentifier: kItemName] dataCell] setFont:[NSFont systemFontOfSize:11]];
	//
	//[self mainViewDidLoad];

}
- (BOOL)windowShouldClose:(id)sender {
	//		NSLog(@"shouldClose");
	[[NSUserDefaults standardUserDefaults] synchronize];
	[(NSPreferencePane *)currentPane willUnselect];
	return YES;
}

- (void)setWindowTitleWithInfo:(NSDictionary *)info {
	NSImage *image = info?[QSResourceManager imageNamed:[info objectForKey:kItemIcon]]:nil;
	NSString *string = [info objectForKey:kItemName];
	NSString *path = [info objectForKey:kItemPath];
	if (!string) string = @"Preferences";
	if (!image) image = [QSResourceManager imageNamed:@"prefsGeneral"];
	if (!path) path = @"~/Library/Preferences/com.blacktree.Quicksilver.plist";
	[[self window] setTitle:string];
	[[self window] setRepresentedFilename:[path stringByStandardizingPath]];
	[[[self window] standardWindowButton:NSWindowDocumentIconButton] setImage:[image duplicateOfSize:QSSize16]];
}

- (void)windowDidLoad {
	NSWindow *win = [self window];
	[win center];
	[win setFrameAutosaveName:@"preferences"];

	[win setFrame:constrainRectToRect([win frame], [[win screen] frame]) display:YES];
	NSRect frame = [win frame];
	frame = constrainRectToRect(frame, [[win screen] visibleFrame]);
	[win setFrame:frame display:YES];

	// Set the window to be visible on all spaces
	[win setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadPlugInInfo:) name:QSPlugInLoadedNotification object:nil];
	[moduleController addObserver:self forKeyPath:@"selectedObjects" options:0 context:nil];

	[self loadPlugInInfo:nil];

	toolbar = [[NSToolbar alloc] initWithIdentifier:@"preferencesToolbar"];
	[toolbar setDelegate:self];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration: YES];
	[toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
//	[toolbar setSelectedItemIdentifier:@"QSSettingsPanePlaceholder"];

	// if ([[toolbar class] instancesRespondToSelector:@selector(setSelectedItemIdentifier:)])
	//	 [toolbar performSelector:@selector(setSelectedItemIdentifier:) withObject:[[toolbarTabView selectedTabViewItem] identifier]];

	[win setToolbar:toolbar];
	if (defaultBool(@"QSSkipGuide") ) {
		[self selectPaneWithIdentifier:@"QSSettingsPanePlaceholder"];
	} else {
		[toolbar setSelectedItemIdentifier:@"QSMainMenuPrefPane"];
		[self selectPaneWithIdentifier:@"QSMainMenuPrefPane"];
	}
	[toolbar release];
}

- (BOOL)relaunchRequested {
	return relaunchRequested;
}
- (void)setRelaunchRequested:(BOOL)flag {
	relaunchRequested = flag;
}

//Outline Methods

//- (int) numberOfRowsInTableView:(NSTableView *)tableView {
//	if (tableView == internalPrefsTable) {
//		return [modules count];
//	}
//	return 0;
//}
//
//- (id)tableView:(NSTableView *)aTableView
//objectValueForTableColumn:(NSTableColumn *)aTableColumn
//			row:(int) rowIndex
// {
//	if (aTableView == internalPrefsTable) {
//		return [[modules objectAtIndex:rowIndex] objectForKey:kItemName];
//
//	}
//	return nil;
//}

- (float) tableView:(NSTableView *)tableView heightOfRow:(int)row {
	return ([[modules objectAtIndex:row] objectForKey:@"separator"]) ? 8 : 16;
	//return [[[modules objectAtIndex:row] objectForKey:@"type"] isEqualToString:@"Main"] ?32:16;
}

- (BOOL)tableView:(NSTableView *)aTableView rowIsSeparator:(int)rowIndex {
	if (aTableView == internalPrefsTable)
		return nil != [[modules objectAtIndex:rowIndex] objectForKey:@"separator"];
	else
		return NO;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex {
	return (aTableView == internalPrefsTable) ? ![self tableView:aTableView rowIsSeparator:rowIndex] : NO;
}

- (BOOL)tableView:(NSTableView *)tableView shouldShowCellExpansionForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	return NO;
}

//- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
//	//  NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
//	//  NSFileManager *manager = [NSFileManager defaultManager];
//	if (aTableView == internalPrefsTable) {
//		NSImage *icon = [[modules objectAtIndex:rowIndex] objectForKey:kItemIcon];
//		[icon createRepresentationOfSize:NSMakeSize(16, 16)];
//		[icon setSize:NSMakeSize(16, 16)];
//		[(QSImageAndTextCell*)aCell setImage:icon];
//		return;
//	}
//}
//

- (NSView *)viewForModule:(QSPreferencePane *)module {
	NSView *view = [module mainView];
	if (!view) {
		//id obj = [module objectForKey:@"instance"];
		view = [module loadMainView];
        if( view == nil )
            NSLog( @"Failed loading view for Preference Module %@", module );
		//[module setObject:view forKey:@"view"];
		//[module setObject:[NSNumber numberWithFloat:NSHeight([view frame])] forKey:@"height"];
		if ([module respondsToSelector:@selector(paneLoadedByController:)])
			[module paneLoadedByController:self];
	}
	return view;
}

//- (IBAction)selectModule:(id)sender {}

- (NSRect) windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame {
	return NSMakeRect(16, 16, 536, NSHeight(defaultFrame) -32);
}

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject {
	return ([currentPane respondsToSelector:@selector(windowWillReturnFieldEditor:toObject:)]) ? [currentPane windowWillReturnFieldEditor:sender toObject:anObject] : nil;
}

- (NSMutableArray *)modules { return modules;  }
- (void)setModules:(NSMutableArray *)newModules {
	if(newModules != modules){
		[modules release];
		modules = [newModules retain];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	NSArray *selection = [object selectedObjects];
	if (!reloading) {
		[self setPaneForInfo:[selection count] ? [selection lastObject] : nil switchSection:NO];
	}
}

//Toolbar
- (void)selectPane:(id)sender {
//	NSMutableDictionary *info = [modulesByID objectForKey:identifier];
	[self selectPaneWithIdentifier:[sender itemIdentifier]];
}

- (void)selectPaneWithIdentifier:(NSString *)identifier {
	NSMutableDictionary *info = [modulesByID objectForKey:identifier];
	if (info) {
		[self setPaneForInfo:info switchSection:YES];
	} else if ([identifier isEqualToString:@"QSSettingsPanePlaceholder"]) {
		[self selectSettingsPane:nil];
		[toolbar setSelectedItemIdentifier:@"QSSettingsPanePlaceholder"];
		[self preventEmptySelection];
	}
}

- (void)selectSettingsPane:(id)sender {
	NSArray *selection = [moduleController selectedObjects];
	if (![selection count]) {
		[moduleController setSelectionIndex:0];
		selection = [moduleController selectedObjects];
	}
	[self selectPaneWithIdentifier:[[selection lastObject] objectForKey:kItemID]];
}

- (void)setPaneForInfo:(NSMutableDictionary *)info switchSection:(BOOL)switchSection {
	[self setCurrentPaneInfo:info];
	//NSLog(@"setfor %@", info);
	//	[[self window] disableScreenUpdatesUntilFlush];
	if (!info) return;
	NSString *type = [info objectForKey:@"type"];
	BOOL isToolbar = type && ![type caseInsensitiveCompare:@"Toolbar"];
	//NSLog(@"%d %@", isToolbar, [info objectForKey:kItemID]);
	if (isToolbar) {
		[toolbar setSelectedItemIdentifier:[info objectForKey:kItemID]];
	} else {
		[toolbar setSelectedItemIdentifier:@"QSSettingsPanePlaceholder"];
		[moduleController setSelectedObjects:[NSArray arrayWithObject:info]];
	}

	[self setWindowTitleWithInfo:isToolbar?info:nil];
	if (switchSection)
		[self setShowSettings:!isToolbar];

	id instance = [info objectForKey:@"instance"];
	if (!instance) {
		instance = [[[[QSReg getClass:[info objectForKey:@"class"]] alloc] init] autorelease];
		if (instance) {
			if ([instance respondsToSelector:@selector(setInfo:)])
				[instance setInfo:info];
			[info setObject:instance forKey:@"instance"];
		}
	}

	prefsBox = isToolbar?toolbarPrefsBox:settingsPrefsBox;

	[[NSUserDefaults standardUserDefaults] synchronize];

	id newPane = instance;
	id oldPane = currentPane;

	if (oldPane == newPane) {
		[newPane didReselect];
		return;
	}
	[newPane willSelect];
	[oldPane willUnselect];

	[[self window] _hideAllDrawers];

// Help button
	[helpButton setEnabled:[newPane respondsToSelector:@selector(showPaneHelp:)]];
	[helpButton setTarget:newPane];
	[helpButton setAction:@selector(showPaneHelp:)];

	NSView *newView = [newPane mainView];

	if (!newView) {
		[iconView setHidden:YES];
		[toolbarTitleView display];
		[loadingProgress setHidden:NO];
		[loadingProgress startAnimation:nil];

		//[iconView display];
//		[nameView display];
//		[descView display];
//		[prefsBox display];

		newView = [self viewForModule:newPane];

	}

	float height = [[newPane mainView] frame].size.height;
	BOOL dynamicSize = height >= 384;

	[prefsBox setContentView:nil];
	[self setCurrentPane:instance];

	if (settingsPrefsBox == prefsBox) {

	if (dynamicSize) {
			NSRect prefsFrame = [prefsBox frame];
			prefsFrame.origin.y = 22; //prefsFrame.size.height-height;
			prefsFrame.size.height = NSHeight([[prefsBox superview] frame]) -22;
			[prefsBox setFrame:prefsFrame];

			NSRect fillerFrame = [fillerBox frame];
			fillerFrame.size.height = 40;
			[fillerBox setFrame:fillerFrame];
			[[fillerBox superview] setNeedsDisplay:YES];

			[prefsBox setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
			[fillerBox setAutoresizingMask:NSViewWidthSizable];
		} else {
			NSRect prefsFrame = [prefsBox frame];
		//logRect(prefsFrame);
			prefsFrame.origin.y += prefsFrame.size.height-height;
			prefsFrame.size.height = height;
			[prefsBox setFrame:prefsFrame];
			//logRect([[prefsBox superview] frame]);
			NSRect fillerFrame = [fillerBox frame];
			fillerFrame.size.height = NSMinY(prefsFrame) -fillerFrame.origin.y+3;
			[fillerBox setFrame:fillerFrame];
			[[fillerBox superview] setNeedsDisplay:YES];

			[prefsBox setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
			[fillerBox setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		}
	}

	[prefsBox setContentView:newView];
	if ([newPane respondsToSelector:@selector(preferencesSplitView)]) {
		NSSplitView *split = [newPane performSelector:@selector(preferencesSplitView)];
		[self matchSplitView:split];
		[split setDelegate:self];
	}

	NSResponder *firstResponder = [newView nextKeyView];
	if (firstResponder)
		[[self window] makeFirstResponder:firstResponder];

	[oldPane didUnselect];
	[newPane didSelect];
	[[self window] display];
	[iconView setHidden:NO];
	[loadingProgress setHidden:YES];
	[toolbarTitleView display];
	[loadingProgress stopAnimation:nil];
}

- (void)matchSplitView:(NSSplitView *)split {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(splitViewDidResizeSubviews:) name:NSSplitViewDidResizeSubviewsNotification object:split];

	NSArray *subviews = [split subviews];
	NSRect frame0 = [[subviews objectAtIndex:0] frame];
	NSRect frame1 = [[subviews objectAtIndex:1] frame];
	float width = 160; //[[NSUserDefaults standardUserDefaults] floatForKey:kQSPreferencesSplitWidth];
	if (width>0) {
	float change = width-NSWidth(frame0);
		//NSLog(@"setWidth %f %f %f %f", width, NSWidth(frame0), NSWidth(frame1), change);

	NSRect newFrame0 = frame0;
	NSRect newFrame1 = frame1;
	newFrame0.size.width += change;

	newFrame1.size.width -= change;
	newFrame1.origin.x += change;

	//newFrame0.size.width = MIN(MAX(newFrame0.size.width, min), max);

	[[subviews objectAtIndex:0] setFrame:newFrame0];
	[[subviews objectAtIndex:1] setFrame:newFrame1];
	//[split adjustSubviews];
	}
}

//- (IBAction)next:(id)sender {}

- (void)handleURL:(NSURL *)url { [self showPaneWithIdentifier:[url fragment]];  }

- (QSPreferencePane *)currentPane { return currentPane;  }
- (void)setCurrentPane:(QSPreferencePane *)newCurrentPane {
	if(newCurrentPane != currentPane){
		[currentPane release];
		currentPane = [newCurrentPane retain];
	}
}

- (BOOL)respondsToSelector:(SEL)aSelector {
	return ([super respondsToSelector:aSelector]) ? YES : [currentPane respondsToSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
	if ([currentPane respondsToSelector:[invocation selector]])
		[invocation invokeWithTarget:currentPane];
	else
		[self doesNotRecognizeSelector:[invocation selector]];
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)sel {
	NSMethodSignature *sig = [[self class] instanceMethodSignatureForSelector:sel];
	return (sig) ? sig : [currentPane methodSignatureForSelector:sel];
}

- (NSMutableDictionary *)currentPaneInfo { return currentPaneInfo;  }
- (void)setCurrentPaneInfo:(NSMutableDictionary *)newCurrentPaneInfo {
	if (newCurrentPaneInfo && currentPaneInfo != newCurrentPaneInfo) {
		[currentPaneInfo release];
		currentPaneInfo = [newCurrentPaneInfo retain];
	}
}

- (void)setShowSettings:(BOOL)flag {
	if (showingSettings == flag) return;
	if (!showingSettings) { // show them
		//NSLog(@"show %d", flag);
		[mainBox setContentView:settingsSplitView];
		[self matchSplitView:settingsSplitView];
		showingSettings = YES;
	} else { // hide them
		  //			NSLog(@"hide %d", flag);
		  //		[prefsBox removeFromSuperview];
		[mainBox setContentView:nil]; //settingsPrefsBox];
		showingSettings = NO;
	}
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
	if ([itemIdentifier isEqualToString:@"QSSettingsPanePlaceholder"]) {
		NSToolbarItem *newItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
		[newItem setLabel:@"Preferences"];
		[newItem setPaletteLabel:@"Preferences"];
		[newItem setImage:[QSResourceManager imageNamed:@"Pref-Settings"]];
		[newItem setToolTip:@"Application and Plug-in Preferences"];
		[newItem setTarget:self];
		[newItem setAction:@selector(selectSettingsPane:)];
		return [newItem autorelease];
	}
//	if ([itemIdentifier isEqualToString:@"QSToolbarHistoryView"]) {
//		NSToolbarItem *newItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
//		[newItem setPaletteLabel:@"History"];
//
//		[newItem setMinSize:[[historyView superview] frame] .size];
//		[newItem setView:[historyView superview]];
//		[newItem setEnabled:YES];
//		return newItem;
//	}
	else if ([itemIdentifier isEqualToString:@"QSToolbarTitleView"]) {
		QSTitleToolbarItem *newItem = [[QSTitleToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
		[newItem setLabel:@"Title"];
		[newItem setPaletteLabel:@"Location"];
		[newItem setView:toolbarTitleView];
		[newItem setMinSize:NSMakeSize(128, 32)];
		[newItem setMaxSize:NSMakeSize(512, 48)];
		[newItem setEnabled:YES];
		//[toolbarTitleView setColor:[NSColor whiteColor]];
		return [newItem autorelease];
	}

	NSDictionary *info = [modulesByID objectForKey:itemIdentifier];
	//int index = [toolbarTabView indexOfTabViewItemWithIdentifier:itemIdentifier];
	//if (index == NSNotFound) return nil;
	//NSTabViewItem *tabViewItem = [toolbarTabView tabViewItemAtIndex:index];
	//NSLog(@"tool %@", info);
	NSToolbarItem *newItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	[newItem setLabel:[info objectForKey:@"name"]];
	[newItem setPaletteLabel:[info objectForKey:@"name"]];
	[newItem setImage:[QSResourceManager imageNamed:[info objectForKey:@"icon"]]];
	[newItem setToolTip:[info objectForKey:@"description"]];
	[newItem setTarget:self];
	[newItem setAction:@selector(selectPane:)];
	return [newItem autorelease];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
	return [NSArray arrayWithObjects:@"QSToolbarTitleView", @"QSMainMenuPrefPane", NSToolbarSeparatorItemIdentifier, @"QSSettingsPanePlaceholder", @"QSTriggersPrefPane", @"QSCatalogPrefPane", @"QSPlugInsPrefPane", nil];
//	return [self toolbarAllowedItemIdentifiers:toolbar];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)theToolbar {
	return [self toolbarAllowedItemIdentifiers:theToolbar];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
	NSMutableArray *array = [NSMutableArray array];
	NSArray *theModules = [[modulesByID allValues] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type like[cd] 'toolbar'"]];
	//[array addObject:@"QSToolbarHistoryView"];
	[array addObject:@"QSSettingsPanePlaceholder"];
	[array addObject:@"QSToolbarTitleView"];
	[array addObjectsFromArray:[theModules valueForKey:kItemID]];
	[array addObject:NSToolbarFlexibleSpaceItemIdentifier];
	[array addObject:NSToolbarSeparatorItemIdentifier];
	[array addObject:NSToolbarSpaceItemIdentifier];
	return array;
}

- (BOOL)validateToolbarItem:(NSToolbarItem*)toolbarItem {
	return YES; //[[self toolbarStandardItemIdentifiers:nil] containsObject:[toolbarItem itemIdentifier]];
}

//- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize;

- (float) splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)offset {
	// return proposedMax-36;
	return proposedMax - 384;
}

- (float) splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)offset {
	return (offset) ? NSWidth([sender frame]) / 2 : 160;
}

- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize {
	NSArray *subviews = [sender subviews];
//	NSRect newFrame0 = [[subviews objectAtIndex:0] frame];
	NSRect newFrame1 = [[subviews objectAtIndex:1] frame];
	float change = NSWidth([sender frame]) -oldSize.width;
	newFrame1.size.width += change;
//	[[subviews objectAtIndex:0] setFrame:newFrame0];
	[[subviews objectAtIndex:1] setFrame:newFrame1];
	[sender adjustSubviews];
}

//- (void)splitViewWillResizeSubviews:(NSNotification *)notification;
//- (void)splitViewDidResizeSubviews:(NSNotification *)notification;
- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview { return NO;  }
//- (float) splitView:(NSSplitView *)splitView constrainSplitPosition:(float)proposedPosition ofSubviewAt:(int)index {
//
//}

@end
