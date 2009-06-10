#import <WebKit/WebKit.h>
#import <QSCrucible/QSPlugInManager.h>

#import "QSController.h"

#import "QSUpdateController.h"

#import "QSSetupAssistant.h"

@implementation QSSetupAssistant
+ (id)sharedInstance {
    static id _sharedInstance;
    if (!_sharedInstance) _sharedInstance = [[[self class] allocWithZone:[self zone]] init];
    return _sharedInstance;
}

- (id)init {
    self = [self initWithWindowNibName:@"QSSetupAssistant"];
    if (self) {
//		plugInsToInstall = [[NSMutableDictionary alloc] init];  
//        
//		
//		identifiers = [[NSDictionary dictionaryWithObjectsAndKeys:
//			@"com.blacktree.Quicksilver.QSiChatPlugIn", @"iChat",
//			@"com.blacktree.Quicksilver.QSiTunesPlugIn", @"iTunes",
//			@"com.blacktree.Quicksilver.QSAddressBookPlugIn", @"AddressBook",
//			@"com.blacktree.Quicksilver.QSAppleMailPlugIn", 	@"Mail",
//			@"com.blacktree.Quicksilver.QSSafariPlugIn", @"Safari",
//			@"com.blacktree.Quicksilver.QSClipboardPlugIn", @"Clipboard",
//			@"com.blacktree.Quicksilver.QSTerminalPlugIn", @"Terminal",
//			@"com.blacktree.Quicksilver.QSExtraScriptsPlugIn", @"ExtraScripts",
//			nil] retain];
//		
//		NSMutableSet *installedSet = [NSMutableSet setWithArray:[identifiers allValues]];
//		[installedSet intersectSet:[NSSet setWithArray:[[[QSPlugInManager sharedInstance] localPlugIns] allKeys]]];
//		
//		QSLog(@"plugs %@", installedSet);  
//		NSEnumerator *e = [installedSet objectEnumerator];
//		NSString *theID;
//		
//		installedPlugIns = [[NSMutableDictionary alloc] init];
//		
//		while((theID = [e nextObject])) {
//			[installedPlugIns setObject:[NSNumber numberWithBool:YES] forKey:[[identifiers allKeysForObject:theID] lastObject]];
//			[plugInsToInstall setObject:[NSNumber numberWithBool:YES] forKey:[[identifiers allKeysForObject:theID] lastObject]];
//			
//		}
		//	QSLog(@"plugs %@", installedPlugIns);  
	}
	
    return self;
}
- (void)awakeFromNib {
	[plugInsController setSortDescriptors:[NSSortDescriptor descriptorArrayWithKey:@"name" ascending:YES
																		  selector:@selector(caseInsensitiveCompare:)]]; 	
}
- (void)initiatePlugInDownload {
	plugInInfoStatus = 0;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(plugInInfoLoaded) name:QSPlugInInfoLoadedNotification
											  object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(plugInInfoFailed) name:QSPlugInInfoFailedNotification
											  object:nil];
	QSPlugInManager *manager = [QSPlugInManager sharedInstance];
	[manager downloadWebPlugInInfoIgnoringDate];
	
	
}
- (void)plugInInfoLoaded {
	plugInInfoStatus = 1;
	
	QSPlugInManager *manager = [QSPlugInManager sharedInstance];
	NSArray *plugins = [manager knownPlugInsWithWebInfo];
	//QSLog(@"loadedplugins %d", [plugins count]);
	plugins = [plugins filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isInstalled == NO && isRecommended == YES"]];
	
	//QSLog(@"loadedplugins %d", [plugins count]);
	
	
	[self setRecommendedPlugIns:plugins];
		
	
	[plugInLoadTabView selectTabViewItemWithIdentifier:@"loaded"];
	[plugInLoadProgress stopAnimation:nil]; 	
}

- (void)plugInInfoFailed {
	plugInInfoStatus = -1;
	QSLog(@"failed to get plugins");
	[plugInLoadTabView selectTabViewItemWithIdentifier:@"failed"];

}

- (NSArray *)recommendedPlugIns { return [[recommendedPlugIns retain] autorelease];  }
- (void)setRecommendedPlugIns:(NSArray *)newRecommendedPlugIns
{
    if (recommendedPlugIns != newRecommendedPlugIns) {
        [recommendedPlugIns release];
        recommendedPlugIns = [newRecommendedPlugIns retain];
    }
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[identifiers release];
	[plugInsToInstall release];
	[installedPlugIns release];
	[recommendedPlugIns release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}
- (IBAction)setHotKey:(id)sender {
	QSLog(@"sender %@", sender);
}

- (void)windowDidLoad {
    
    [setupTabView selectFirstTabViewItem:self];
    
	// [setupTabView removeTabViewItem:[setupTabView tabViewItemAtIndex:[setupTabView indexOfTabViewItemWithIdentifier:@"network"]]];
    //[setupTabView removeTabViewItem:[setupTabView tabViewItemAtIndex:[setupTabView indexOfTabViewItemWithIdentifier:@"features"]]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(installStatusChanged:) name:QSPlugInUpdatesFinishedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(catalogIndexed:) name:QSCatalogEntryIsIndexing object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(catalogIndexed:) name:QSCatalogIndexed object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(catalogIndexingFinished:) name:QSCatalogIndexingCompleted object:nil];
	
    [[self window] setLevel:NSNormalWindowLevel];
	
	[setupTabView setTabViewType:NSNoTabsBezelBorder];
	[(QSWindow *)[self window] setShowEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSGrowEffect", @"transformFn", @"show", @"type", [NSNumber numberWithFloat:0.5] , @"duration", nil]];
	[(QSWindow *)[self window] setHideEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSShrinkEffect", @"transformFn", @"hide", @"type", [NSNumber numberWithFloat:0.5] , @"duration", nil]];
	
	NSString *path = [[NSBundle bundleForClass:[self class]]pathForResource:@"License"
																   ofType:@"rtf"];
	[[(NSScrollView *)agreementView documentView] replaceCharactersInRange:NSMakeRange(0, 0) withRTF:[NSData dataWithContentsOfFile:path]];
	
	[self selectedItem:[setupTabView selectedTabViewItem]];
	[[gettingStartedView preferences] setDefaultTextEncodingName:@"utf-8"];
	[gettingStartedView setDrawsBackground:NO];
	[gettingStartedView setPolicyDelegate:self];

	[[gettingSupportView preferences] setDefaultTextEncodingName:@"utf-8"];
	[gettingSupportView setDrawsBackground:NO];
	[gettingSupportView setPolicyDelegate:self];
	
}
- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id)listener {
	if ([[[request URL] scheme] isEqualToString:@"applewebdata"] || [[[request URL] scheme] isEqualToString:@"file"] || [[[request URL] scheme] isEqualToString:@"about"]) {
		[listener use]; 	
	} else {
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
		[listener ignore];
	}
}



//-(void)accept:(id)sender {
//	
//	[(QSWindow *)[self window] setHideOffset:NSMakePoint(0, 400)];
//	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"QSAgreementAccepted"];
//	[[NSUserDefaults standardUserDefaults] synchronize];
//	[NSApp stopModal];
//}
//	
//	


- (NSMutableDictionary *)plugInsToInstall {
	return plugInsToInstall; 	
}

- (NSMutableDictionary *)installedPlugIns {
	return installedPlugIns;
}

- (BOOL)run:(id)sender {
    [[self window] center];
    [[self window] makeKeyAndOrderFront:self];
	
	//QSPlugInManager *manager = [QSPlugInManager sharedInstance];
	
	 [NSApp runModalForWindow:[self window]];
    
	// [[self window] setLevel:NSNormalWindowLevel];
    return NO;
}

- (BOOL)windowShouldClose:(id)sender {
	if (!defaultBool(@"QSAgreementAccepted") ) {
	NSAlert *alert = [NSAlert alertWithMessageText:@"Cancel Setup" defaultButton:@"Quit" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"Would you like to stop setup and quit Quicksilver?"];
	[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
	return NO;
	}
		return YES;
}
- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	[[alert window] close];
	QSLog(@"alert %d", returnCode);
	if (returnCode)
		[NSApp terminate:self]; 	
	
}

- (void)catalogIndexingFinished:(id)notif {
	[scanProgress stopAnimation:self];
		[scanStatusField setHidden:YES];
		[[self window] display];
		//[scanStatusField setStringValue:@""]; //[NSString stringWithFormat:@"%d items in catalog", [[[QSLib catalog] contents] count]]];
	scanComplete = YES;

	if ([[[setupTabView selectedTabViewItem] identifier] isEqualToString:@"scan"]) {
		[scanStatusField setStringValue:@"Scan Complete"];
		[[self window] display];
	}
}
- (void)catalogIndexed:(id)notif {
    if ([[notif name] isEqualToString:QSCatalogEntryIsIndexing]) {
		
		[scanStatusField setStringValue:[NSString stringWithFormat:@"Scanning %@", [[notif object] name]]];
	}
}

- (IBAction)cancelPlugInInstall:(id)sender {
	[NSApp endSheet:pluginStatusPanel returnCode:0];
}
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo {
	[sheet close];
	[[QSPlugInManager sharedInstance] cancelPlugInInstall];
	[[self recommendedPlugIns] setValue:[NSNumber numberWithBool:NO] forKey:@"shouldInstall"];
	[self nextSection:nil];
}
- (IBAction)nextSection:(id)sender {
	//    if [setupTabView selectNextTabViewItem:self];
	if ([[[setupTabView selectedTabViewItem] identifier] isEqualToString:@"plugins"]) {
		
		NSArray *plugins = [[self recommendedPlugIns] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"shouldInstall == YES"]];
		if ([plugins count]) {
			[[QSPlugInManager sharedInstance] installPlugInsForIdentifiers:[plugins valueForKey:@"identifier"]];
			[NSApp beginSheet:pluginStatusPanel modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
			return;
		}
	}
	
	
	
    if ([setupTabView selectedTabViewItem] == [[setupTabView tabViewItems] lastObject]) {
		[self finish:sender];
		return;
    }
    int index = [setupTabView indexOfTabViewItem:[setupTabView selectedTabViewItem]];
	
	int transitions[5] = {CGSUp, CGSLeft, CGSLeft, CGSLeft, CGSUp} ;
	
	//int transitions[5] = {CGSUp, CGSLeft, CGSDown, CGSLeft, CGSUp} ;
	
	QSCGSTransition *transition = [QSCGSTransition transitionWithWindow:[self window]
																 type:CGSCube option:transitions[index]];
	
	[self deselectedItem:[setupTabView selectedTabViewItem]];
    [setupTabView selectNextTabViewItem:self];  
	[self selectedItem:[setupTabView selectedTabViewItem]];
	[[self window] display];
	[transition runTransition:0.5];
    
}


- (void)selectedItem:(NSTabViewItem *)item {
	[[self window] setTitle:[[setupTabView selectedTabViewItem] label]];
	[continueButton setTitle:([setupTabView selectedTabViewItem] == [[setupTabView tabViewItems] lastObject]) ?@"Finish":@"Continue"];
    [backButton setHidden:([setupTabView selectedTabViewItem] == [[setupTabView tabViewItems] objectAtIndex:0])];
	
    if ([[item identifier] isEqualToString:@"options"]) {
        if (!scanComplete) {
			// [continueButton setEnabled:NO];
			
            [scanStatusField setStringValue:@""];
            [scanTextField setStringValue:@"Performing Initial Scan"];
            [[self window] displayIfNeeded];
            
            [scanProgress setUsesThreadedAnimation:YES];
            [scanProgress startAnimation:self];
            
            [[QSLibrarian sharedInstance] startThreadedAndForcedScan];
            
        } 	
		NSString *path = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Resources/GettingStarted.html"];
		[[gettingStartedView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
		
    } else if ([[item identifier] isEqualToString:@"plugins"]) {
		if (plugInInfoStatus != 1) {
	
		[plugInLoadTabView selectTabViewItemWithIdentifier:@"loading"];
		[plugInLoadProgress startAnimation:nil];
		[self initiatePlugInDownload]; 	
		}
	} else if ([[item identifier] isEqualToString:@"license"]) {
		[continueButton bind:@"enabled" toObject:[NSUserDefaultsController sharedUserDefaultsController]
				 withKeyPath:@"values.QSAgreementAccepted" options:nil];
	} else if ([[item identifier] isEqualToString:@"gettingstarted"]) {
		
		NSString *path = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Resources/GettingSupport.html"];
		[[gettingSupportView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
		
			
	} else {
		[continueButton setEnabled:YES];
	}
}
- (void)deselectedItem:(NSTabViewItem *)item {
	if ([[item identifier] isEqualToString:@"plugins"]) {
		
	}
	if ([[item identifier] isEqualToString:@"license"]) {
		[continueButton unbind:@"enabled"];
		if ([[NSApp modalWindow] isEqual:[self window]])
			[NSApp stopModal];
	}
}

- (IBAction)prevSection:(id)sender {
	   int index = [setupTabView indexOfTabViewItem:[setupTabView selectedTabViewItem]];
	
	int transitions[6] = {CGSUp, CGSDown, CGSRight, CGSRight, CGSRight, CGSDown} ;
	
	QSCGSTransition *transition = [QSCGSTransition transitionWithWindow:[self window]
																 type:CGSCube option:transitions[index]];
	
    [self deselectedItem:[setupTabView selectedTabViewItem]];
	[setupTabView selectPreviousTabViewItem:self];  
	[self selectedItem:[setupTabView selectedTabViewItem]];
	[[self window] display];
	[transition runTransition:0.5];
}

- (void)installStatusChanged:(NSNotification *)notif {
	float progress = [[QSPlugInManager sharedInstance] downloadProgress];
	[installProgress setDoubleValue:progress];
	[installProgress displayIfNeeded];
	
	if (progress == 1) {
		//[installProgress setDoubleValue:progress];
		[self setDownloadComplete:YES];
		[installProgress setHidden:YES];
		[installTextField setStringValue:@"Download Complete"];
	}
	
	[self plugInInfoLoaded];
	[NSApp endSheet:pluginStatusPanel returnCode:1];
}

- (id)updateController {
	return [QSUpdateController sharedInstance]; 	
}
- (id)plugInManager {
	return [QSPlugInManager sharedInstance]; 	
}


- (BOOL)downloadComplete { return downloadComplete;  }
- (void)setDownloadComplete:(BOOL)flag
{
	downloadComplete = flag;
}


- (IBAction)downloadPlugIns:(id)sender {
	[sender setHidden:YES];
	[installProgress setHidden:NO];
	//[installProgress setDisplayedWhenStopped:YES];
	//[scanProgress animate:YES];
	//[scanProgress displayIfNeeded];
	[installTextField setHidden:NO];
	
	[installTextField setStringValue:@"Downloading plug-ins"];
	NSMutableArray *array = [[[plugInsToInstall allKeysForObject:[NSNumber numberWithBool:YES]]mutableCopy] autorelease];
	
	[array removeObjectsInArray:[installedPlugIns allKeys]];
	NSArray *plugInsToAdd = [identifiers objectsForKeys:array  notFoundMarker:@""];
	
	[[QSPlugInManager sharedInstance] installPlugInsForIdentifiers:plugInsToAdd];
	//	QSLog(@"plugs:%@", plugInsToAdd);
	
	
}


- (IBAction)finish:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSetupAssistantCompleted];
    
	
	[[self window] close];
	[NSApp stopModal];
	

	
    [(QSController *)[NSApp delegate] setupAssistantCompleted:self];
    [(QSController *)[NSApp delegate] activateInterface:self];
}


- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	
}


- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	
	
}

- (BOOL)tabView:(NSTabView *)tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem {  
	
    //if (tabViewItem == [[setupTabView tabViewItems] lastObject])
    //    return (scanComplete);
    return YES;
}
- (id)manager {
	return [QSPlugInManager sharedInstance]; 	
}

@end
