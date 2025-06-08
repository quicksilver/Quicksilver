#import "QSPlugInsPrefPane.h"
#import "QSPreferencesController.h"
#import "QSRegistry.h"
#import "QSApp.h"
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

@synthesize plugInName;

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

		
		[self reloadPlugInsList:nil];
	}
	return self;
}

- (id)manager {
	return [QSPlugInManager sharedInstance];
}

- (void)deepObjectCount {
	
}

- (void)awakeFromNib {

	NSSortDescriptor* aSortDesc = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
	[arrayController setSortDescriptors:[NSArray arrayWithObject: aSortDesc]];
	[arrayController rearrangeObjects];

    [infoButton setKeyEquivalent:@"i"];
    [refreshButton setKeyEquivalent:@"r"];
    for (NSButton *aButton in [NSArray arrayWithObjects:infoButton,refreshButton, nil]) {
		[aButton setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
    }

	[[plugInText preferences] setDefaultTextEncodingName:@"utf-8"];
	[plugInText setPolicyDelegate:self];
	[plugInText setResourceLoadDelegate:self];
    

	[arrayController addObserver:self forKeyPath:@"selectedObjects" options:0 context:nil];
	[setsArrayController addObserver:self forKeyPath:@"selectedObjects" options:0 context:nil];
	NSNumber *selectedIndex = [[NSUserDefaults standardUserDefaults] objectForKey:@"QSPluginSelectedView"];
	NSIndexSet *iSet = nil;
	if (selectedIndex) {
		NSUInteger val = [selectedIndex unsignedIntegerValue];
		if ([(NSArray *)[setsArrayController content] count] > val) {
			iSet = [NSIndexSet indexSetWithIndex:val];
		}
	}
	if (!selectedIndex) {
		iSet = [NSIndexSet indexSetWithIndex:0];
	}
	[pluginSetsTable selectRowIndexes:iSet byExtendingSelection:NO];

	// update the list of plugins to match the selected category
	NSArray *selection = [setsArrayController performSelector:@selector(selectedObjects)];
	NSDictionary *dict = [selection lastObject];
	if ([dict objectForKey:@"viewMode"]) {
		[self setViewMode:[[dict objectForKey:@"viewMode"] integerValue]];
	}
}

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id)listener {
	if ([[[request URL] path] containsString:[[[NSBundle mainBundle] resourceURL] path]] || [[[request URL] scheme] isEqualToString:@"about"] || [[[request URL] scheme] isEqualToString:@"resource"]) {
		[listener use];
	} else {
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
		[listener ignore];
	}
}

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource {
	if ([[[request URL] scheme] isEqualToString:@"resource"]) {
		NSString *path = [[request URL] resourceSpecifier];
		request = [request mutableCopy];
		[(NSMutableURLRequest *)request setURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:[path stringByDeletingPathExtension] ofType:[path pathExtension]]]];
	}
	return request;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (object == setsArrayController) {
		NSArray *selection = [setsArrayController performSelector:@selector(selectedObjects)];
		NSDictionary *dict = [selection lastObject];
		if ([dict objectForKey:@"viewMode"]) {
			[self setViewMode:[[dict objectForKey:@"viewMode"] integerValue]];
		}
		//if ([dict objectForKey:@"category"]) {
			[self setCategory:[dict objectForKey:@"category"]];
		//}
		NSIndexPath *selectedPath = [setsArrayController performSelector:@selector(selectionIndexPath)];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithUnsignedInteger:[selectedPath indexAtPosition:0]] forKey:@"QSPluginSelectedView"];
	} else {
		NSArray *selection = [arrayController selectedObjects];
		NSString *htmlString;
		NSString *defaultTitle = NSLocalizedString(@"Plugin Documentation", nil);
		if ([selection count] == 1) {
            [infoButton setEnabled:YES];
            [docsButton setEnabled:YES];
			[self setPlugInName:[NSString stringWithFormat:@"%@: %@", defaultTitle, [(QSPlugIn *)[selection objectAtIndex:0] name]]];
			htmlString = [[selection objectAtIndex:0] infoHTML];
		} else {
            [infoButton setEnabled:NO];
            [docsButton setEnabled:NO];
			[self setPlugInName:defaultTitle];
			htmlString = @"";
		}
        QSGCDMainSync(^{
            [[self->plugInText mainFrame] loadHTMLString:htmlString baseURL:[[NSBundle mainBundle] resourceURL]];
        });
	}
}

- (void)paneLoadedByController:(id)controller {
	[infoDrawer setParentWindow:[controller window]];
	[infoDrawer setLeadingOffset:48];
	[infoDrawer setTrailingOffset:24];
	[infoDrawer setPreferredEdge:NSMaxXEdge];
}

- (void)willUnselect
{
	[infoDrawer close];
	[pluginInfoPanel close];
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

- (NSString *)helpPage {return NSLocalizedString(@"PlugIns Preferences", nil);}

- (NSInteger) viewMode { return viewMode;  }
- (void)setViewMode:(NSInteger)newViewMode {
	viewMode = newViewMode;
	[self reloadFilters];
	[plugInTable scrollRowToVisible:0];
}

- (void)reloadPlugInsList:(NSNotification *)notif {
	QSGCDMainSync(^{
		[self setPlugins:[[QSPlugInManager sharedInstance] knownPlugInsWithWebInfo]];
	});
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
	NSUInteger index;
	for (index = [indexes firstIndex]; index != NSNotFound; index = [indexes indexGreaterThanIndex:index]) {
		[bundles addObject:[[arrayController arrangedObjects] objectAtIndex:index]];
		if (index == [indexes lastIndex]) break;
	}
	return bundles;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem { return YES;  }

- (IBAction)deleteSelection:(id)sender {
	[[QSPlugInManager sharedInstance] deletePlugIns:[self selectedPlugIns] fromWindow:[plugInTable window]];
	[[QSPlugInManager sharedInstance] downloadWebPlugInInfoIgnoringDate:nil];
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

- (IBAction)getInfo:(id)sender
{
	[pluginInfoPanel makeKeyAndOrderFront:sender];
}

- (IBAction)updatePlugIns:(id)sender { [[QSPlugInManager sharedInstance] checkForPlugInUpdates:nil];  }

#if 0
- (IBAction)showPlugInsRSS:(id)sender {
	feed://qs0.blacktree.com/quicksilver/pluginsrss.php?feature=Daedalus
}
#endif

- (IBAction)reloadPlugIns:(id)sender { [[QSPlugInManager sharedInstance] downloadWebPlugInInfoIgnoringDate:nil];  }

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(NSTextFieldCell*)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	if ([[aTableColumn identifier] isEqualToString:@"enabled"]) {
		NSArray *array = [arrayController arrangedObjects];
		QSPlugIn *object = [array objectAtIndex:rowIndex];
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
- (void)setPlugins:(NSArray *)newPlugins {
	if(newPlugins != plugins) {
        [self willChangeValueForKey:@"plugins"];
		plugins = [newPlugins mutableCopy];
        [self didChangeValueForKey:@"plugins"];
	}
}

- (NSString *)search { return search;  }
- (void)setSearch:(NSString *)newSearch {
	if(newSearch != search){
		search = newSearch;
		[self reloadFilters];
	}
}

- (NSString *)category { return category;  }
- (void)setCategory:(NSString *)newCategory {
	if(newCategory != category){
		if ([newCategory isEqual:@"All Categories"])
			newCategory = nil;
		category = newCategory;
		[self reloadFilters];
	}
}

- (void)reloadFilters { [self reloadFiltersIgnoringViewMode:NO];  }

- (NSMutableArray *)plugInSets {
	NSMutableArray *setDicts = [NSMutableArray array];
	[setDicts addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:2] , @"viewMode", NSLocalizedString(@"Recommended", "Recommended: Plugin category name in the sidebar of the 'Plugins' preference pane"), @"text", [QSResourceManager imageNamed:@"QSPlugIn"] , @"image", nil]];
	[setDicts addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:1] , @"viewMode", NSLocalizedString(@"Installed", "Installed: Plugin category name in the sidebar of the 'Plugins' preference pane"), @"text", [QSResourceManager imageNamed:@"QSPlugIn"] , @"image", nil]];
	[setDicts addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:5] , @"viewMode", NSLocalizedString(@"Disabled", "Disabled: Plugin category name in the sidebar of the 'Plugins' preference pane"), @"text", [QSResourceManager imageNamed:@"QSPlugIn"] , @"image", nil]];
	[setDicts addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:4] , @"viewMode", NSLocalizedString(@"Not Installed", "Not Installed: Plugin category name in the sidebar of the 'Plugins' preference pane"), @"text", [QSResourceManager imageNamed:@"QSPlugIn"] , @"image", nil]];
	NSArray *categories = [NSArray arrayWithObjects:
			NSLocalizedString(@"Applications", "Applications: Plugin category name in the sidebar of the 'Plugins' preference pane"),
			NSLocalizedString(@"Calendar", "Calendar: Plugin category name in the sidebar of the 'Plugins' preference pane"),
			NSLocalizedString(@"Contacts", "Contacts: Plugin category name in the sidebar of the 'Plugins' preference pane"),
			NSLocalizedString(@"Development", "Development: Plugin category name in the sidebar of the 'Plugins' preference pane"),
			NSLocalizedString(@"Files", "Files: Plugin category name in the sidebar of the 'Plugins' preference pane"),
			NSLocalizedString(@"Images", "Images: Plugin category name in the sidebar of the 'Plugins' preference pane"),
			NSLocalizedString(@"Interfaces", "Interfaces: Plugin category name in the sidebar of the 'Plugins' preference pane"),
			NSLocalizedString(@"Mail & Chat", "Mail & Chat: Plugin category name in the sidebar of the 'Plugins' preference pane"),
			NSLocalizedString(@"Miscellaneous", "Misc: Plugin category name in the sidebar of the 'Plugins' preference pane"),
			NSLocalizedString(@"Music", "Music: Plugin category name in the sidebar of the 'Plugins' preference pane"),
			NSLocalizedString(@"Quicksilver", "Quicksilver: Plugin category name in the sidebar of the 'Plugins' preference pane"),
			NSLocalizedString(@"Search", "Search: Plugin category name in the sidebar of the 'Plugins' preference pane"),
			NSLocalizedString(@"System", "System: Plugin category name in the sidebar of the 'Plugins' preference pane"),
			NSLocalizedString(@"Text", "Text: Plugin category name in the sidebar of the 'Plugins' preference pane"),
			NSLocalizedString(@"Web", "Web: Plugin category name in the sidebar of the 'Plugins' preference pane"), nil];
	NSMutableArray *categoryDicts = [NSMutableArray array];
	[setDicts addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:3] , @"viewMode", categoryDicts, @"children", NSLocalizedString(@"All Plugins", "Plugin category name in the sidebar of the 'Plugins' preference pane"), @"text", [QSResourceManager imageNamed:@"QSPlugIn"] , @"image", nil]];

	for(NSString * categoryName in categories)
		[categoryDicts addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:3] , @"viewMode", categoryName, @"category", categoryName, @"text", @"category", @"type", nil]];

	return setDicts;
}

- (BOOL)isItemExpanded:(id)item {return YES;}

- (void)reloadFiltersIgnoringViewMode:(BOOL)ignoreView {
	NSMutableArray *predicates = [NSMutableArray array];
	if (!ignoreView) {
		switch (viewMode) {
			case 1: //installed
				[predicates addObject:[NSPredicate predicateWithFormat:@"isInstalled == 1"]];
				break;
			case 2: //Recommended
				[predicates addObject:[NSPredicate predicateWithFormat:@"isRecommended == YES"]];
				break;
			case 3: //All
				[predicates addObject:[NSPredicate predicateWithFormat:@"isObsolete == NO"]];
				break;
			case 4: //UnInstalled
				[predicates addObject:[NSPredicate predicateWithFormat:@"isInstalled <= 0 && isObsolete == NO"]];
				break;
			case 5: //Installed, but disabled (either by the user or some error loading)
				[predicates addObject:[NSPredicate predicateWithFormat:@"isInstalled == 1 && isLoaded == 0"]];
				break;
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
}

@end
