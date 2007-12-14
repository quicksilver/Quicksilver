
#import <WebKit/WebKit.h>
#import <QSBase/QSPlugInManager.h>

#import <QSBase/QSHelp.h>
#import <QSBase/QSPlugIn.h>
#import <QSBase/QSHandledSplitView.h>

#import "QSUpdateController.h"

#import "QSPreferencesController.h"

#import "QSApp.h"

#import "QSPlugInsPrefPane.h"

////#import <QSBase/QSResourceManager.h>

//static int bundleNameSort(id item1, id item2, void *self) {
//	return [[item1 objectForInfoDictionaryKey:@"CFBundleName"] caseInsensitiveCompare:[item2 objectForInfoDictionaryKey:@"CFBundleName"]];
//}

@implementation QSPlugInsPrefPane

- (NSView*)preferencesSplitView {
	return [sidebar superview];
}

+ (void)getMorePlugIns {
	[NSApp activateIgnoringOtherApps:YES];
	[(QSPlugInsPrefPane *)[QSPreferencesController showPaneWithIdentifier:@"QSPlugInsPrefPane"] setViewMode:2];
	//	[[self sharedInstance] setViewMode:2];
}
//static id _sharedInstance;
//+ (id)sharedInstance {
//    if (!_sharedInstance) _sharedInstance = [[[self class] allocWithZone:[self zone]] init];
//    return _sharedInstance;
//}
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
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(installStatusChanged:) name:@"QSUpdateControllerStatusChanged" object:nil];
		
		[self reloadPlugInsList:nil];
	}
    return self;
}

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


- (id)updateController {
	return [QSUpdateController sharedInstance]; 	
}
- (id)manager {
	return [QSPlugInManager sharedInstance]; 	
}
- (void)awakeFromNib {
	
	NSColor *highlightColor = [NSColor colorWithCalibratedHue:0.75f
												 saturation:0.500000f
												 brightness:0.8500000f
													  alpha:1.000000f];
	
	[pluginSetsTable setBackgroundColor:[NSColor colorWithCalibratedHue:0.75f
															  saturation:0.10000f
															  brightness:0.970000f
																   alpha:1.000000f]];
	[pluginSetsTable setHighlightColor:highlightColor];
	[plugInTable setHighlightColor:highlightColor];
	   
	   
	   
	   
	NSSortDescriptor* aSortDesc = [[[NSSortDescriptor alloc] 
                                                 initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)] autorelease];
	[arrayController setSortDescriptors:[NSArray arrayWithObject: aSortDesc]];
	[arrayController rearrangeObjects];
	
	[plugInTable setTarget:self]; 	
	
	//	[plugInTable setDoubleAction:@selector(tableDoubleAction:)]; 	
	[plugInTable setAction:@selector(tableAction:)]; 	
	//[plugInText setTextContainerInset:NSMakeSize(8, 8)];
	//[plugInText changeDocumentBackgroundColor:[NSColor clearColor]];  
	[[plugInText preferences] setDefaultTextEncodingName:@"utf-8"];
	//[plugInText setDrawsBackground:NO];
	[plugInText setPolicyDelegate:self];
	[plugInText setResourceLoadDelegate:self];
	//[plugInTable removeColumn:[plugInTable columnWithIdentifier:@"status"]];
	//[self tableViewSelectionDidChange:nil];
	[[plugInText window] useOptimizedDrawing:NO];
	[arrayController addObserver:self
					  forKeyPath:@"selectedObjects"
						 options:0
						 context:nil];
	
	[setsArrayController addObserver:self
					  forKeyPath:@"selectedObjects"
						 options:0
						 context:nil];
	[pluginSetsTable selectRow:0 byExtendingSelection:NO];
}


- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id)listener {
	//QSLog(@"url %@", [request URL]);
	if ([[[request URL] scheme] isEqualToString:@"applewebdata"] || [[[request URL] scheme] isEqualToString:@"about"]) {
		[listener use]; 	
	} else {
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
		[listener ignore];
	}
}

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource {	
	//QSLog(@"url %@", [request URL]);
	
	if ([[[request URL] scheme] isEqualToString:@"resource"]) {
		NSString *path = [[request URL] resourceSpecifier];
		//	QSLog(@"get %@", path);
		request = [[request mutableCopy] autorelease];
		[(NSMutableURLRequest *)request  setURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:[path stringByDeletingPathExtension] ofType:[path pathExtension]]]];
	}
	
	//	QSLog(@"url %@", [request URL]);
	return request;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (object == setsArrayController) {
		NSArray *selection = [setsArrayController selectedObjects];
	//	QSLog(@"select %@", [selection lastObject]);
		NSDictionary *dict = [selection lastObject];
		if ([dict objectForKey:@"viewMode"]) {
			[self setViewMode:[[dict objectForKey:@"viewMode"] intValue]]; 				
		}
		
		//if ([dict objectForKey:@"category"]) {
			[self setCategory:[dict objectForKey:@"category"]]; 				
		//}
		
		
		
	} else {
		NSArray *selection = [arrayController selectedObjects];
		//QSLog(@"change %@", selection);
		if ([selection count] == 1) {
			NSString *info = [[selection objectAtIndex:0] infoHTML];
			//QSLog(info);
			[[plugInText mainFrame] loadHTMLString:info baseURL:nil];
			
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
- (void)tableAction:(id)sender {
	if ([sender clickedRow] <0) return;
	//if ([sender clickedColumn] == 3) {
	//	NSBundle *bundle = [plugInArray objectAtIndex:[sender clickedRow]];
	//	[self showInfoForPlugIn:bundle]; 		
	//}
	//	QSLog(@"double %d", [sender clickedColumn]); 	
}

- (NSString *)helpPage {return @"PlugIns Preferences";}

- (int) viewMode { return viewMode;  }
- (void)setViewMode:(int)newViewMode {
    viewMode = newViewMode;
	[self reloadFilters];
	[plugInTable scrollRowToVisible:0]; 	
}
- (void)reloadPlugInsList:(NSNotification *)notif {
	QSPlugInManager *manager = [QSPlugInManager sharedInstance];
	NSArray *newPlugIns = [manager knownPlugInsWithWebInfo];
	[self setPlugins:(NSMutableArray *)newPlugIns];
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
	NSMutableArray *array = [[[[self selectedPlugIns] valueForKeyPath:@"infoDictionary.QSPlugIn.infoFile"] mutableCopy] autorelease];
	[array removeObject:[NSNull null]];
	return [array count];
}


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	
	return YES;
}



//- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex {
//	NSBundle *bundle = [plugInArray objectAtIndex:rowIndex];
//	return ![[bundle bundlePath] hasPrefix:[[NSBundle mainBundle] bundlePath]];
//}


- (IBAction)deleteSelection:(id)sender {
	[[QSPlugInManager sharedInstance] deletePlugIns:[self selectedPlugIns] fromWindow:[plugInTable window]];
}


- (IBAction)revealSelection:(id)sender {
	[[self selectedPlugIns] valueForKey:@"reveal"];
}

- (IBAction)copyInstallURL:(id)sender {
	NSString *bundleIDs = [[[self selectedPlugIns] valueForKey:@"identifier"] componentsJoinedByString:@", "];
	//QSLog(@"%@", bundleIDs);
	
	NSString *string = [NSString stringWithFormat:@"qsinstall:id = %@", bundleIDs];
	[[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObjects:NSURLPboardType, NSStringPboardType, nil] owner:self];
	[[NSURL URLWithString:string] writeToPasteboard:[NSPasteboard generalPasteboard]];
	[[NSPasteboard generalPasteboard] setString:string forType:NSStringPboardType];
}
- (IBAction)installSelectedPlugIns:(id)sender {
	[[self selectedPlugIns] setValue:[NSNumber numberWithBool:YES] forKey:@"enabled"];
}

- (IBAction)downloadInBrowser:(id)sender {
	NSArray *URLs = [[self selectedPlugIns] valueForKey:@"downloadURL"];
	[[NSWorkspace sharedWorkspace] openURLs:URLs
				   withAppBundleIdentifier:nil
								   options:NSWorkspaceLaunchDefault
			additionalEventParamDescriptor:nil
						 launchIdentifiers:nil];
}

- (BOOL)showInfoForPlugIn:(NSBundle *)bundle {
	NSString *helpFile = [[bundle objectForInfoDictionaryKey:@"QSPlugIn"] objectForKey:@"infoFile"];
	
	if (!helpFile) return NO; ;
	helpFile = [[[bundle bundlePath] stringByAppendingPathComponent:@"Contents/Resources/"] stringByAppendingPathComponent:helpFile];
	[[NSWorkspace sharedWorkspace] openFile:helpFile];
	return YES;
}


- (IBAction)getInfo:(id)sender {
	
	NSEnumerator *e = [[self selectedPlugIns] objectEnumerator];
	NSBundle *bundle;
	
	BOOL filesOpened = NO;
	while ((bundle = [e nextObject])) {
		filesOpened |= [self showInfoForPlugIn:bundle];
	}
	if (!filesOpened) NSBeep();
}

- (IBAction)updatePlugIns:(id)sender {
	[[QSPlugInManager sharedInstance] checkForPlugInUpdates];
}

- (IBAction)showPlugInsRSS:(id)sender {
	//	[[NSWork
	
	//feed://quicksilver.blacktree.com/pluginsrss.php?feature = Daedalus
}
- (IBAction)reloadPlugIns:(id)sender {
	[[QSPlugInManager sharedInstance] downloadWebPlugInInfoIgnoringDate];
}

//
//- (id)tableView:(NSTableView *)aTableView
//objectValueForTableColumn:(NSTableColumn *)aTableColumn
//            row:(int) rowIndex {
////	NSBundle *bundle = [plugInArray objectAtIndex:rowIndex];
//}

- (NSMutableArray *)plugins { return [[plugins retain] autorelease];  }
- (void)setPlugins:(NSMutableArray *)newPlugins
{
    [plugins autorelease];
    plugins = [newPlugins retain];
}



- (NSString *)search { return [[search retain] autorelease];  }
- (void)setSearch:(NSString *)newSearch
{
    [search autorelease];
    search = [newSearch retain];
	[self reloadFilters];
}


- (NSString *)category { return [[category retain] autorelease];  }
- (void)setCategory:(NSString *)newCategory
{
	if ([newCategory isEqual:@"All Categories"]) newCategory = nil;
    [category autorelease];
    category = [newCategory retain];
	[self reloadFilters];
}

- (void)reloadFilters {
	[self reloadFiltersIgnoringViewMode:NO];
}

- (NSMutableArray *)plugInSets { 

	NSMutableArray *setDicts = [NSMutableArray array];
	[setDicts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:2] , @"viewMode",
		@"Recommended", @"text",
		[NSImage imageNamed:@"QSPlugIn"] , @"image", nil]]; 	

	[setDicts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:1] , @"viewMode",
		@"Installed Plug-ins", @"text",
		[NSImage imageNamed:@"QSPlugIn"] , @"image", nil]];

	NSArray *categories = [NSArray arrayWithObjects:
		@"Applications",
		@"Calendar",
		@"Contacts",
		@"Development",
		@"Files",
		@"Images",
		@"Interfaces",
		@"Mail & Chat",
		@"Miscellaneous",
		@"Music",
		@"Quicksilver",
		@"Search",
		@"System",
		@"Text",
		@"Web",
		nil];
	NSMutableArray *categoryDicts = [NSMutableArray array];

	[setDicts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:3] , @"viewMode",
		categoryDicts, @"children",
		@"All Plug-ins", @"text",
		[NSImage imageNamed:@"QSPlugIn"] , @"image", nil]];
	
	foreach(categoryName, categories) {
		[categoryDicts addObject:[NSDictionary dictionaryWithObjectsAndKeys: 
			[NSNumber numberWithInt:3] , @"viewMode",
			categoryName, @"category",
			categoryName, @"text",
			@"category", @"type",
			nil]];
	}
    
    return setDicts;
	
}

- (void)reloadFiltersIgnoringViewMode:(BOOL)ignoreView {
	NSMutableArray *predicates = [NSMutableArray arrayWithCapacity:3];
	
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
	//if (VERBOSE) QSLog(@"Plugins Predicate: %@", filterPredicate);
	[arrayController setFilterPredicate:filterPredicate];
	
	if (!ignoreView && ![[arrayController arrangedObjects] count]) {
		[self reloadFiltersIgnoringViewMode:YES];
	}
}

#pragma mark -
#pragma mark NSTableView Delegate
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	if ([[aTableColumn identifier] isEqualToString:@"enabled"]) {
		NSArray *array = [arrayController arrangedObjects];
		id object = [array objectAtIndex:rowIndex];
		[aCell setEnabled:[object canBeDisabled]];
	}
    
	if ([[aTableColumn identifier] isEqualToString:@"CFBundleName"] || [[aTableColumn identifier] isEqualToString:@"CFBundleName"]) {
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

- (float) tableView:(NSTableView *)tableView heightOfRow:(int)row {
	return 16;
}

- (BOOL)isItemExpanded:(id)item {return YES;}

#pragma mark -
#pragma mark NSOutlineView Delegate
- (float) outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {

	if ([[[item representedObject] objectForKey:@"type"] isEqualToString:@"category"])
		return 16; 	
	return 32;
}

@end
