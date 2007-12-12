#import "QSPlugInsPrefPane.h"
#import "QSPreferencesController.h"
#import "QSRegistry.h"
#import "QSApp.h"
#import "QSHelp.h"
#import "QSPlugIn.h"
#import "QSHandledSplitView.h"
#import <QSCore/QSResourceManager.h>
#import <WebKit/WebKit.h>
#import "QSPlugInManager.h"
#import "QSTableView.h"
#import "QSObject.h"

@interface QSObject (NSTreeNodePrivate)
//- (NSIndexPath *)indexPath;
- (id)observedObject;
//- (id)objectAtIndexPath:(NSIndexPath *)path;
@end

@implementation QSPlugInsPrefPane

- (id)preferencesSplitView {
	return [sidebar superview];
}

+ (void)getMorePlugIns {
	[NSApp activateIgnoringOtherApps:YES];
	[(QSPlugInsPrefPane *)[QSPreferencesController showPaneWithIdentifier:@"QSPlugInsPrefPane"] setViewMode:2];
	//	[[self sharedInstance] setViewMode:2];
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

- (id)init {
	self = [super initWithBundle:[NSBundle bundleForClass:[QSPlugInsPrefPane class]]];
	if (self) {
		//		if (!_sharedInstance) _sharedInstance = [self retain];
		plugInArray = [[NSMutableArray alloc] init];
		plugins = [[NSMutableArray alloc] init];
		viewMode = 2;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadPlugInsList:) name:QSPlugInInstalledNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadPlugInsList:) name:QSPlugInLoadedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadPlugInsList:) name:QSPlugInInfoLoadedNotification object:nil];
#if 0
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(installStatusChanged:) name:@"QSUpdateControllerStatusChanged" object:nil];
#endif
		[self reloadPlugInsList:nil];
	}
	return self;
}

#if 0
- (void)installStatusChanged:(NSNotification *)notif {
	//	float progress = [[QSUpdateController sharedInstance] downloadProgress];
	//	[installProgress setDoubleValue:progress];
	//	[installProgress displayIfNeeded];
	//
	//	if (progress == 1) {
	//		//[installProgress setDoubleValue:progress];
	//		[self setDownloadComplete:YES];
	//		[installProgress setHidden:YES];
	//		[installTextField setStringValue:@"Download Complete"];
	//	}
}
#endif

- (id)manager {
	return [QSPlugInManager sharedInstance];
}
- (void)awakeFromNib {
	[pluginSetsTable setBackgroundColor:[NSColor colorWithCalibratedHue:0.75f saturation:0.10000f brightness:0.970000f alpha:1.000000f]];
	NSColor *highlightColor = [NSColor colorWithCalibratedHue:0.75f saturation:0.500000f brightness:0.8500000f alpha:1.000000f];
	[(QSTableView *)pluginSetsTable setHighlightColor:highlightColor];
	[(QSTableView *)plugInTable setHighlightColor:highlightColor];

	NSSortDescriptor* aSortDesc = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
	[arrayController setSortDescriptors:[NSArray arrayWithObject: aSortDesc]];
	[aSortDesc release];
	[arrayController rearrangeObjects];

////	[plugInTable setTarget:self];
	//	[plugInTable setDoubleAction:@selector(tableDoubleAction:)];
////	[plugInTable setAction:@selector(tableAction:)];
	//[plugInText setTextContainerInset:NSMakeSize(8, 8)];
	//[plugInText changeDocumentBackgroundColor:[NSColor clearColor]];
	[[plugInText preferences] setDefaultTextEncodingName:@"utf-8"];
	//[plugInText setDrawsBackground:NO];
	[plugInText setPolicyDelegate:self];
	[plugInText setResourceLoadDelegate:self];
	//[plugInTable removeColumn:[plugInTable columnWithIdentifier:@"status"]];
	//[self tableViewSelectionDidChange:nil];
	[[plugInText window] useOptimizedDrawing:NO];
	[arrayController addObserver:self forKeyPath:@"selectedObjects" options:0 context:nil];
	[setsArrayController addObserver:self forKeyPath:@"selectedObjects" options:0 context:nil];
	[pluginSetsTable selectRow:0 byExtendingSelection:NO];
}

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id)listener {
	if ([[[request URL] scheme] isEqualToString:@"applewebdata"] || [[[request URL] scheme] isEqualToString:@"about"]) {
		[listener use];
	} else {
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
		[listener ignore];
	}
}

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource {
	if ([[[request URL] scheme] isEqualToString:@"resource"]) {
		NSString *path = [[request URL] resourceSpecifier];
		request = [[request mutableCopy] autorelease];
		[(NSMutableURLRequest *)request setURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:[path stringByDeletingPathExtension] ofType:[path pathExtension]]]];
	}
	return request;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (object == setsArrayController) {
		NSArray *selection = [setsArrayController performSelector:@selector(selectedObjects)];
		NSDictionary *dict = [selection lastObject];
		if ([dict objectForKey:@"viewMode"]) {
			[self setViewMode:[[dict objectForKey:@"viewMode"] intValue]];
		}
		//if ([dict objectForKey:@"category"]) {
			[self setCategory:[dict objectForKey:@"category"]];
		//}
	} else {
		NSArray *selection = [arrayController selectedObjects];
		if ([selection count] == 1) {
			[[plugInText mainFrame] loadHTMLString:[[selection objectAtIndex:0] infoHTML] baseURL:nil];
		} else {
			[[plugInText mainFrame] loadHTMLString:@"" baseURL:nil];
		}
	}
}

- (void)paneLoadedByController:(id)controller {
	[infoDrawer setParentWindow:[controller window]];
	[infoDrawer setLeadingOffset:48];
	[infoDrawer setTrailingOffset:24];
	[infoDrawer setPreferredEdge:NSMaxXEdge];
}

#if 0
- (void)tableAction:(id)sender {
	if ([sender clickedRow] <0) return;
	//if ([sender clickedColumn] == 3) {
	//	NSBundle *bundle = [plugInArray objectAtIndex:[sender clickedRow]];
	//	[self showInfoForPlugIn:bundle];
	//}
	//	NSLog(@"double %d", [sender clickedColumn]);
}
#endif

- (NSString *)helpPage {return @"PlugIns Preferences";}

- (int) viewMode { return viewMode;  }
- (void)setViewMode:(int)newViewMode {
	viewMode = newViewMode;
	[self reloadFilters];
	[plugInTable scrollRowToVisible:0];
}

- (void)reloadPlugInsList:(NSNotification *)notif {
//	NSArray *newPlugIns = [[QSPlugInManager sharedInstance] knownPlugInsWithWebInfo];
//	NSLog(@"loaded %d plugins", [newPlugIns count]);
	[self setPlugins:(NSMutableArray *)[[QSPlugInManager sharedInstance] knownPlugInsWithWebInfo]];
}

- (IBAction)showHelp:(id)sender {
	foreach(plugin, [self selectedPlugIns]) {
		QSShowHelpPage([plugin helpPage]);
	}
}

- (NSString *)mainNibName {
	return @"QSPlugInsPrefPane";
}

- (IBAction)showPlugInsFolder:(id)sender {
	[[NSFileManager defaultManager] createDirectoriesForPath:psMainPlugInsLocation];
	[[NSWorkspace sharedWorkspace] openFile:psMainPlugInsLocation];
}

- (NSArray *)selectedPlugIns {
	NSIndexSet *indexes = [plugInTable selectedRowIndexes];
	if (!indexes) return nil;
	NSMutableArray *bundles = [NSMutableArray array];
	int index;
	for (index = [indexes firstIndex]; index != NSNotFound; index = [indexes indexGreaterThanIndex:index]) {
		[bundles addObject:[[arrayController arrangedObjects] objectAtIndex:index]];
		if (index == [indexes lastIndex]) break;
	}
	return bundles;
}

- (BOOL)selectedPlugInsHaveInfo {
	[self selectedPlugIns];
	NSMutableArray *array = [[[self selectedPlugIns] valueForKeyPath:@"infoDictionary.QSPlugIn.infoFile"] mutableCopy];
	[array removeObject:[NSNull null]];
	BOOL result = [array count];
	[array release];
	return result;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem { return YES;  }

- (IBAction)deleteSelection:(id)sender {
	[[QSPlugInManager sharedInstance] deletePlugIns:[self selectedPlugIns] fromWindow:[plugInTable window]];
}

- (IBAction)revealSelection:(id)sender { [[self selectedPlugIns] valueForKey:@"reveal"];  }

- (IBAction)copyInstallURL:(id)sender {
	NSString *string = [NSString stringWithFormat:@"qsinstall:id=%@", [[[self selectedPlugIns] valueForKey:@"identifier"] componentsJoinedByString:@", "]];
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	[pb declareTypes:[NSArray arrayWithObjects:NSURLPboardType, NSStringPboardType, nil] owner:self];
	[[NSURL URLWithString:string] writeToPasteboard:pb];
	[pb setString:string forType:NSStringPboardType];
}

- (IBAction)installSelectedPlugIns:(id)sender {
	[[self selectedPlugIns] setValue:[NSNumber numberWithBool:YES] forKey:@"enabled"];
}

- (IBAction)downloadInBrowser:(id)sender {
	[[NSWorkspace sharedWorkspace] openURLs:[[self selectedPlugIns] valueForKey:@"downloadURL"] withAppBundleIdentifier:nil options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifiers:nil];
}

- (BOOL)showInfoForPlugIn:(QSPlugIn *)aPlugin {
	NSBundle  *bundle; NSString *helpFile;
	if((bundle = [aPlugin bundle]) && (helpFile = [[bundle objectForInfoDictionaryKey:@"QSPlugIn"] objectForKey:@"infoFile"]))
		if([helpFile length]){
			[[NSWorkspace sharedWorkspace] openFile:[[[bundle bundlePath] stringByAppendingPathComponent:@"Contents/Resources/"] stringByAppendingPathComponent:helpFile]];
			return YES;
		}
	return NO;
}

- (IBAction)getInfo:(id)sender {
	NSEnumerator *e = [[self selectedPlugIns] objectEnumerator];
	QSPlugIn *bundle;
	BOOL filesOpened = NO;
	while (bundle = [e nextObject]) filesOpened |= [self showInfoForPlugIn:bundle];
	if (!filesOpened) NSBeep();
}

- (IBAction)updatePlugIns:(id)sender { [[QSPlugInManager sharedInstance] checkForPlugInUpdates];  }

#if 0
- (IBAction)showPlugInsRSS:(id)sender {
	feed://qs0.blacktree.com/quicksilver/pluginsrss.php?feature=Daedalus
}
#endif

- (IBAction)reloadPlugIns:(id)sender { [[QSPlugInManager sharedInstance] downloadWebPlugInInfoIgnoringDate];  }

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	if ([[aTableColumn identifier] isEqualToString:@"enabled"]) {
		NSArray *array = [arrayController arrangedObjects];
		//if ([array count] <rowIndex) return;
		id object = [array objectAtIndex:rowIndex];
		//	NSLog(@"%d!!!", [object canBeDisabled]);
		[aCell setEnabled:[object canBeDisabled]];
	}
	if ([[aTableColumn identifier] isEqualToString:@"CFBundleName"]) {
		BOOL selected = [[aTableView selectedRowIndexes] containsIndex:rowIndex];
		NSArray *array = [arrayController arrangedObjects];
		id object = [array objectAtIndex:rowIndex];
		if (selected)
			[aCell setTextColor:[NSColor textColor]];
		else if ([object isHidden])
			[aCell setTextColor:[NSColor redColor]];
		else if ([object isInstalled])
			[aCell setTextColor:[NSColor textColor]];
		else
			[aCell setTextColor:[NSColor grayColor]];
	}
}

- (NSMutableArray *)plugins { return plugins; }
- (void)setPlugins:(NSMutableArray *)newPlugins {
	if(newPlugins != plugins){
		[plugins release];
		plugins = [newPlugins retain];
	}
}

- (NSString *)search { return search;  }
- (void)setSearch:(NSString *)newSearch {
	if(newSearch != search){
		[search release];
		search = [newSearch retain];
		[self reloadFilters];
	}
}

- (NSString *)category { return category;  }
- (void)setCategory:(NSString *)newCategory {
	if(newCategory != category){
		if ([newCategory isEqual:@"All Categories"])
			newCategory = nil;
		[category release];
		category = [newCategory retain];
		[self reloadFilters];
	}
}

- (void)reloadFilters { [self reloadFiltersIgnoringViewMode:NO];  }

- (NSMutableArray *)plugInSets {
	NSMutableArray *setDicts = [NSMutableArray array];
	[setDicts addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:2] , @"viewMode", @"Recommended", @"text", [NSImage imageNamed:@"QSPlugIn"] , @"image", nil]];
	[setDicts addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1] , @"viewMode", @"Installed Plug-ins", @"text", [NSImage imageNamed:@"QSPlugIn"] , @"image", nil]];
	[setDicts addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:4] , @"viewMode", @"Uninstalled Plug-ins", @"text", [NSImage imageNamed:@"QSPlugIn"] , @"image", nil]];
	NSArray *categories = [NSArray arrayWithObjects:@"Applications", @"Calendar", @"Contacts", @"Development", @"Files", @"Images", @"Interfaces", @"Mail & Chat", @"Miscellaneous", @"Music", @"Quicksilver", @"Search", @"System", @"Text", @"Web", nil];
	NSMutableArray *categoryDicts = [NSMutableArray array];
	[setDicts addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:3] , @"viewMode", categoryDicts, @"children", @"All Plug-ins", @"text", [NSImage imageNamed:@"QSPlugIn"] , @"image", nil]];

	foreach(categoryName, categories)
		[categoryDicts addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:3] , @"viewMode", categoryName, @"category", categoryName, @"text", @"category", @"type", nil]];

	return setDicts;
}

- (BOOL)isItemExpanded:(id)item {return YES;}

- (float)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
	if ([[[item respondsToSelector:@selector(representedObject)] ? [item representedObject] : [(QSObject *)item observedObject] objectForKey:@"type"] isEqualToString:@"category"])
		return 16;
	return 32;
}

- (void)reloadFiltersIgnoringViewMode:(BOOL)ignoreView {
	NSMutableArray *predicates = [NSMutableArray array];
	if (!ignoreView) {
		switch (viewMode) {
			case 1: //installed
				[predicates addObject:[NSPredicate predicateWithFormat:@"installed == YES"]];
				break;
			case 2: //Recommended
				[predicates addObject:[NSPredicate predicateWithFormat:@"installed == YES || isRecommended == YES"]];
				break;
			case 3: //All
				[predicates addObject:[NSPredicate predicateWithFormat:@"meetsFeature == YES"]];
				break;
			case 4: //UnInstalled
				[predicates addObject:[NSPredicate predicateWithFormat:@"isInstalled <= 0"]];
				break;
			case 5: //New
			default:
				break;
		}
	}
	if (search)
		[predicates addObject:[NSPredicate predicateWithFormat:@"name contains[cd] %@", search]];
	if (category)
		[predicates addObject:[NSPredicate predicateWithFormat:@"%@ IN SELF.categories", category]];
	if (!mOptionKeyIsDown)
		[predicates addObject:[NSPredicate predicateWithFormat:@"isHidden == 0"]];

	NSPredicate *filterPredicate = nil;
	if ([predicates count])
		filterPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
	[arrayController setFilterPredicate:filterPredicate];
	if (!ignoreView && ![[arrayController arrangedObjects] count]) {
		[self reloadFiltersIgnoringViewMode:YES];
	}
}

@end
