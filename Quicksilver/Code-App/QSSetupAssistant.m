#import "QSPreferenceKeys.h"
#import "QSSetupAssistant.h"
#import "QSController.h"
#import "QSLibrarian.h"

#import "QSRegistry.h"
#import "QSLibrarian.h"

#import "QSNotifications.h"
#import "QSWindow.h"
#import "QSPlugInManager.h"
#import <WebKit/WebKit.h>

#import "NSSortDescriptor+BLTRExtensions.h"

// FIXME:: SCREWS UP ON CLOSING THEN RESTARTING SETUP ASSISTANT

@interface WebView (Private)
- (void)setDrawsBackground:(BOOL)flag;
@end

@implementation QSSetupAssistant
+ (id)sharedInstance {
	static id _sharedInstance;
	if (!_sharedInstance)
		_sharedInstance = [[[self class] alloc] init];
	return _sharedInstance;
}

- (id)init {
	self = [self initWithWindowNibName:@"QSSetupAssistant"];
#if 0
	if (self) {
	}
#endif
	return self;
}
- (void)awakeFromNib { [plugInsController setSortDescriptors:[NSSortDescriptor descriptorArrayWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)]];  }

- (void)initiatePlugInDownload {
	[continueButton setEnabled:NO];
	[backButton setEnabled:NO];
	plugInInfoStatus = 0;
	[[self plugInManager] downloadWebPlugInInfo:^(BOOL success) {
		if (success) {
			[self plugInInfoLoaded];
		} else {
			[self plugInInfoFailed];
		}
	}];
}

- (void)plugInInfoLoaded {
	plugInInfoStatus = 1;
	NSArray *plugins = [[self plugInManager] knownPlugInsWithWebInfo];
	plugins = [plugins filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isInstalled == NO && isRecommended == YES"]];

	[self setRecommendedPlugIns:plugins];

	QSGCDMainSync(^{
		[self->plugInLoadTabView selectTabViewItemWithIdentifier:@"loaded"];
		[self->plugInLoadProgress stopAnimation:nil];
		[self->continueButton setEnabled:YES];
		[self->backButton setEnabled:YES];
	});
}

- (void)plugInInfoFailed {
	plugInInfoStatus = -1;
	NSLog(@"failed to get plugins");
	QSGCDMainSync(^{
		[self->plugInLoadTabView selectTabViewItemWithIdentifier:@"failed"];
	});
	[continueButton setEnabled:YES];
	[backButton setEnabled:YES];
}

- (NSArray *)recommendedPlugIns { return recommendedPlugIns;  }
- (void)setRecommendedPlugIns:(NSArray *)newRecommendedPlugIns {
	if (recommendedPlugIns != newRecommendedPlugIns) {
		recommendedPlugIns = newRecommendedPlugIns;
	}
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)windowDidLoad {
	[setupTabView selectFirstTabViewItem:self];
	// [setupTabView removeTabViewItem:[setupTabView tabViewItemAtIndex:[setupTabView indexOfTabViewItemWithIdentifier:@"network"]]];
	//[setupTabView removeTabViewItem:[setupTabView tabViewItemAtIndex:[setupTabView indexOfTabViewItemWithIdentifier:@"features"]]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(installStatusChanged:) name:@"QSPlugInUpdatesFinished" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(catalogIndexed:) name:QSCatalogEntryIsIndexingNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(catalogIndexingFinished:) name:QSCatalogIndexingCompleted object:nil];

	[[self window] setLevel:NSNormalWindowLevel];

	[setupTabView setTabViewType:NSNoTabsBezelBorder];

	[(QSWindow *)[self window] setShowEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSGrowEffect", @"transformFn", @"show", @"type", [NSNumber numberWithDouble:0.5] , @"duration", nil]];
	[(QSWindow *)[self window] setHideEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSShrinkEffect", @"transformFn", @"hide", @"type", [NSNumber numberWithDouble:0.5] , @"duration", nil]];
	NSString *licenseString = [[[NSAttributedString alloc] initWithRTF:[NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"License" ofType:@"rtf"]] documentAttributes:nil] string];
	[[agreementView performSelector:@selector(documentView)] replaceCharactersInRange:NSMakeRange(0, 0) withString:licenseString];

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
	NSString *scheme = [[request URL] scheme];
	if ([scheme isEqualToString:@"applewebdata"] || [scheme isEqualToString:@"file"] || [scheme isEqualToString:@"about"])
		[listener use];
	else {
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
		[listener ignore];
	}
}

- (NSMutableDictionary *)plugInsToInstall { return plugInsToInstall;  }

- (NSMutableDictionary *)installedPlugIns { return installedPlugIns;  }

- (void)run:(id)sender {
	[[self window] center];
	[[self window] makeKeyAndOrderFront:nil];
	[NSApp runModalForWindow:[self window]];
}

- (BOOL)windowShouldClose:(id)sender {
	if (!defaultBool(@"QSAgreementAccepted") ) {
        QSAlertResponse response = [NSAlert runAlertWithTitle:NSLocalizedString(@"Cancel Setup", @"Setup assistant - Cancel alert title")
                                                     message:NSLocalizedString(@"Would you like to stop setup and quit Quicksilver?", @"Setup assistant - Cancel alert message")
                                                     buttons:@[NSLocalizedString(@"Quit", nil), NSLocalizedString(@"Cancel", nil)]
														style:NSAlertStyleInformational];
		if (response == QSAlertResponseOK)
			[NSApp terminate:self];
		return NO;
	}
	return YES;
}

- (void)catalogIndexingFinished:(id)notif {
	QSGCDMainSync(^{
		[self->scanProgress stopAnimation:self];
		[self->scanStatusField setHidden:YES];
		[[self window] display];
		//[scanStatusField setStringValue:@""]; //[NSString stringWithFormat:@"%d items in catalog", [[[[QSLibrarian sharedInstance] catalog] contents] count]]];
		self->scanComplete = YES;
		[self->continueButton setEnabled:YES];
		[self->backButton setEnabled:YES];
		if ([[[self->setupTabView selectedTabViewItem] identifier] isEqualToString:@"scan"]) {
			[self->scanStatusField setStringValue:@"Scan Complete"];
			[[self window] display];
		}
	});
}

- (void)catalogIndexed:(NSNotification *)notif {
	if ([[notif name] isEqualToString:QSCatalogEntryIsIndexingNotification])
		[scanStatusField setStringValue:[NSString stringWithFormat:@"Scanning %@", [(QSCatalogEntry *)[notif object] name]]];
}

- (IBAction)cancelPlugInInstall:(id)sender { [[self window] endSheet:pluginStatusPanel returnCode:0]; }

- (IBAction)nextSection:(id)sender {
	if ([[[setupTabView selectedTabViewItem] identifier] isEqualToString:@"plugins"]) {
		NSArray *plugins = [[self recommendedPlugIns] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"shouldInstall == YES"]];
		if ([plugins count]) {
			[[self plugInManager] installPlugInsForIdentifiers:[plugins valueForKey:@"identifier"]];
			[[self window] beginSheet:pluginStatusPanel completionHandler:^(NSModalResponse returnCode) {
				[self->pluginStatusPanel close];
				[[self plugInManager] cancelPlugInInstall];
				[[self recommendedPlugIns] setValue:[NSNumber numberWithBool:NO] forKey:@"shouldInstall"];
				[self nextSection:nil];
			}];
			return;
		}
	}
	if ([setupTabView selectedTabViewItem] == [[setupTabView tabViewItems] lastObject]) {
		[self finish:sender];
		return;
	}
	[self deselectedItem:[setupTabView selectedTabViewItem]];
	[setupTabView selectNextTabViewItem:self];
	[self selectedItem:[setupTabView selectedTabViewItem]];
	[[self window] display];
}

- (void)selectedItem:(NSTabViewItem *)item {
	[[self window] setTitle:[[setupTabView selectedTabViewItem] label]];
	[continueButton setTitle:([setupTabView selectedTabViewItem] == [[setupTabView tabViewItems] lastObject]) ?@"Finish":@"Continue"];
	[backButton setHidden:(![setupTabView indexOfTabViewItem:[setupTabView selectedTabViewItem]]) ];

	if ([[item identifier] isEqualToString:@"options"]) {
		if (!scanComplete) {
			[continueButton setEnabled:NO];
			[backButton setEnabled:NO];
			[scanStatusField setStringValue:@""];
			[[self window] displayIfNeeded];
			[scanProgress setUsesThreadedAnimation:YES];
			[scanProgress startAnimation:self];
			[QSLib startThreadedAndForcedScan];
		}
		[[gettingStartedView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Resources/GettingStarted.html"]]]];
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
		[[gettingSupportView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Resources/GettingSupport.html"]]]];
	} else {
		[continueButton setEnabled:YES];
	}
}
- (void)deselectedItem:(NSTabViewItem *)item {
#if 0
	if ([[item identifier] isEqualToString:@"plugins"]) {}
#endif
	if ([[item identifier] isEqualToString:@"license"]) {
		[continueButton unbind:@"enabled"];
		if ([[NSApp modalWindow] isEqual:[self window]])
			[NSApp stopModal];
	}
}

- (IBAction)prevSection:(id)sender {
	[self deselectedItem:[setupTabView selectedTabViewItem]];
	[setupTabView selectPreviousTabViewItem:self];
	[self selectedItem:[setupTabView selectedTabViewItem]];
	[[self window] display];
}

- (void)installStatusChanged:(NSNotification *)notif {
	CGFloat progress = [[self plugInManager] installProgress];
	[installProgress setDoubleValue:progress];
	[installProgress displayIfNeeded];
	if (progress == 1) {
		[self setDownloadComplete:YES];
		[installProgress setHidden:YES];
		[installTextField setStringValue:@"Download Complete"];
	}
	[self plugInInfoLoaded];
	[NSApp endSheet:pluginStatusPanel returnCode:1];
}

- (BOOL)downloadComplete { return downloadComplete;  }
- (void)setDownloadComplete:(BOOL)flag {
	downloadComplete = flag;
}

- (IBAction)downloadPlugIns:(id)sender {
	[sender setHidden:YES];
	[installProgress setHidden:NO];
	//[installProgress setDisplayedWhenStopped:YES];
	//[scanProgress animate:YES];
	//[scanProgress displayIfNeeded];
	[installTextField setHidden:NO];

	[installTextField setStringValue:@"Downloading plugins"];
	NSMutableArray *array = [[plugInsToInstall allKeysForObject:[NSNumber numberWithBool:YES]] mutableCopy];

	[array removeObjectsInArray:[installedPlugIns allKeys]];
	NSArray *plugInsToAdd = [identifiers objectsForKeys:array notFoundMarker:@""];

	[[self plugInManager] installPlugInsForIdentifiers:plugInsToAdd];
}

- (IBAction)finish:(id)sender {
	
	// Create 'Actions' folder if it doesn't already exist
	NSString *actionsFolder = [QSGetApplicationSupportFolder() stringByAppendingPathComponent:@"/Actions/"];
	[[NSFileManager defaultManager] createDirectoryAtPath:actionsFolder withIntermediateDirectories:YES attributes:nil error:nil];
	
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSetupAssistantCompleted];
	[[self window] close];
	[NSApp stopModal];

// return the setup assistant to the first screen
    [setupTabView selectFirstTabViewItem:self];
    [self selectedItem:[setupTabView selectedTabViewItem]];
    
	[(QSController *)[NSApp delegate] setupAssistantCompleted:nil];
	[(QSController *)[NSApp delegate] activateInterface:nil];
}

- (id)plugInManager
{
	return [QSPlugInManager sharedInstance];
}

@end
