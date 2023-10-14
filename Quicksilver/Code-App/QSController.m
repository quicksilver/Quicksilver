#import <ExceptionHandling/NSExceptionHandler.h>
#import "Quicksilver.h"

#import "QSController.h"

#import "QSCatalogPrefPane.h"
#import "QSPlugInsPrefPane.h"
#import "QSAboutWindowController.h"
#import "QSPreferencesController.h"
#import "QSSetupAssistant.h"
#import "QSTaskViewer.h"
#import "QSCrashReporterWindowController.h"
#import "QSDownloads.h"
#import "QSScreenshots.h"
#import "QSDonationController.h"


#import "QSIntValueTransformer.h"

#define DEVEXPIRE 180.0f
#define DEPEXPIRE 365.24219878f

@interface QSObject (QSURLHandling)
- (void)handleURL:(NSURL *)url;
@end

static QSController *defaultController = nil;

@implementation QSController

@synthesize crashReportPath;

- (void)awakeFromNib { if (!defaultController) defaultController = self;  }
+ (id)sharedInstance {
	if (!defaultController)
		defaultController = [[[self class] alloc] init];
	return defaultController;
}

+ (void)initialize {
	
#ifdef DEBUG
	if (DEBUG_STARTUP) NSLog(@"Controller Initialize");
#endif
    //    A value transformer for checking if a given value is '2'. Used in the QSSearchPrefPane (Caps lock menu item)
    QSIntValueTransformer *intValueIsTwo = [[QSIntValueTransformer alloc] initWithInteger:2];
    [NSValueTransformer setValueTransformer:intValueIsTwo forName:@"IntegerValueIsTwo"];
	
	if (![NSApplication isMavericks]) {
		NSBundle *appBundle = [NSBundle mainBundle];

		NSString *minimumVersionString = @"macOS 10.9+";
		NSString *oldVersionsString = @"10.3–10.8";

		NSAlert *alert = [[NSAlert alloc] init];
		alert.messageText = [NSString stringWithFormat:
			NSLocalizedString(@"%@ %@ requires %@", @"macOS version required alert title (bundle name, bundle version, minimum macOS version)"),
			[appBundle objectForInfoDictionaryKey:@"CFBundleName"],
			[appBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
			minimumVersionString
		];
		alert.informativeText = [NSString stringWithFormat:
			NSLocalizedString(@"Recent versions of Quicksilver require %@. Older %@ compatible versions are available from the http://qsapp.com/download.php", @"macOS version required alert message"),
			minimumVersionString,
			oldVersionsString];
		[alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];

		[alert runModal];

		// Quit - we don't want to be running :)
		[NSApp terminate:nil];
	}

	static BOOL initialized = NO;
	if (initialized) return;
	initialized = YES;

#ifdef DEBUG
	if (QSGetLocalizationStatus() && DEBUG_STARTUP) NSLog(@"Enabling Localization");
#endif

	[NSApp registerServicesMenuSendTypes:[NSArray arrayWithObjects:NSStringPboardType, NSRTFPboardType, nil] returnTypes:[NSArray arrayWithObjects:NSStringPboardType, NSRTFPboardType, nil]];

	[NDHotKeyEvent setSignature:'DAED'];

	[QSVoyeur sharedInstance];

#ifdef DEBUG
	if (defaultBool(@"verbose") )
		setenv("verbose", "1", YES);
#endif
		
	// Pre instantiate to avoid bug
//	[NSColor controlShadowColor];
	[NSColor setIgnoresAlpha:NO];
	return;
}

- (void)setupAssistantCompleted:(id)sender {
	runningSetupAssistant = NO;
}
- (IBAction)runSetupAssistant:(id)sender {
	[NSApp activateIgnoringOtherApps:YES];
	runningSetupAssistant = YES;
	[[QSSetupAssistant sharedInstance] run:nil];
}

- (BOOL)connection:(NSConnection *)conn handleRequest:(NSDistantObjectRequest *)doReq { NSLog(@"handlereq"); return NO;  }
- (BOOL)connection:(NSConnection *)parentConnection shouldMakeNewConnection:(NSConnection *)newConnnection { NSLog(@"makenewconection"); return YES;  }

#if 0
- (void)showExpireDialog {
	[NSApp activateIgnoringOtherApps:YES];
	NSInteger result = NSRunInformationalAlertPanel(@"", @"This version of Quicksilver has expired. Please download the latest version.", @"Download", @"OK", nil);
	if (result)
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kWebSiteURL]];
}
#endif

- (void)startMenuExtraConnection {
	if (controllerConnection) return;
	controllerConnection = [NSConnection serviceConnectionWithName:@"QuicksilverControllerConnection" rootObject:self];
}

- (void)handleAppleEvent:(NSAppleEventDescriptor *)event withReplyEvent: (NSAppleEventDescriptor *)replyEvent {
	//NSLog(@"handl");
}

- (NSInteger) showMenuIcon {
	return -1;
}
- (void)setShowMenuIcon:(NSNumber *)mode {    
	if (statusItem) {
		[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
		statusItem = nil;
	}
    if (![mode boolValue]) {
        return;
    }
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:29.0f];
    NSImage *statusImage = [NSImage imageNamed:@"QuicksilverMenu"];
    [statusImage setTemplate:YES];
	[statusItem setImage:statusImage];
	[statusItem setMenu:[self statusMenuWithQuit]];
	[statusItem setHighlightMode:YES];
}

- (void)showDockIcon {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
}

#ifdef DEBUG

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

- (void)activateDebugMenu {
	NSMenu *debugMenu = [[NSMenu alloc] initWithTitle:@"Debug"];

	NSMenuItem *theItem;

	/*theItem = */[debugMenu addItemWithTitle:@"Log Object to Console" action:@selector(logObjectDictionary:) keyEquivalent:@""];

	theItem = [debugMenu addItemWithTitle:@"Perform Score Test" action:@selector(scoreTest:) keyEquivalent:@""];
	[theItem setTarget:QSLib];

	theItem = [debugMenu addItemWithTitle:@"Log Registry" action:@selector(printRegistry:) keyEquivalent:@""];
	[theItem setTarget:QSReg];

	theItem = [debugMenu addItemWithTitle:@"Run Setup Assistant..." action:@selector(runSetupAssistant:) keyEquivalent:@""];
	[theItem setTarget:self];

	theItem = [debugMenu addItemWithTitle:@"Release Histories..." action:@selector(sendReleaseAll:) keyEquivalent:@""];
	[theItem setTarget:self];

	theItem = [debugMenu addItemWithTitle:@"Purge Image and Child Caches..." action:@selector(purgeAllImagesAndChildren) keyEquivalent:@""];
	[theItem setTarget:[QSObject class]];

	theItem = [debugMenu addItemWithTitle:@"Raise Exception..." action:@selector(raiseException) keyEquivalent:@""];
	[theItem setTarget:self];

	theItem = [debugMenu addItemWithTitle:@"Crash..." action:@selector(crashQS) keyEquivalent:@""];
	[theItem setTarget:self];
	
	theItem = [debugMenu addItemWithTitle:@"Output missing localizations" action:@selector(outputMissingLocalizations:) keyEquivalent:@""];
	[theItem setTarget:self];

	theItem = [debugMenu addItemWithTitle:@"New Prefs..." action:@selector(showPrefs) keyEquivalent:@""];
	[theItem setTarget:[QSPreferencesController class]];

	NSMenuItem *debugMenuItem = [[NSApp mainMenu] addItemWithTitle:@"Debug" action:nil keyEquivalent:@""];
	[debugMenuItem setSubmenu:debugMenu];
}

#pragma clang diagnostic pop

- (void)raiseException {
	[NSException raise:@"Test Exception" format:@"This is a test. It is only a test. In the event of a real exception, it would have been followed by some witty commentary."];
}


// disable warning because this is intentional
#pragma clang diagnostic ignored "-Wformat-security"

// Method to crash QS - can call from the debug menu
- (void)crashQS {
	//NSLog((id)1);
}

#endif

#pragma clang diagnostic warning "-Wformat-security"

// Menu Actions

- (IBAction)showForums:(id)sender { [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kForumsURL]];  }
- (IBAction)openIRCChannel:(id)sender { [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"irc://irc.freenode.net/quicksilver"]];  }
- (IBAction)reportABug:(id)sender { [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kBugsURL]];  }
- (IBAction)showAbout:(id)sender {
	[NSApp activateIgnoringOtherApps:YES];
	if (!aboutWindowController)
	aboutWindowController = [[QSAboutWindowController alloc] init];
	[aboutWindowController showWindow:self];
}

- (IBAction)openDonatePage:(id)sender {
	[[QSDonationController sharedInstance] openDonationPage];
}
	 
- (IBAction)showPreferences:(id)sender {
	[NSApp activateIgnoringOtherApps:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"WindowsShouldHide" object:self];
	[QSPreferencesController showPrefs];
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent {
	//NSLog(@"event %@", theEvent);
	if ([[theEvent charactersIgnoringModifiers] isEqualToString:@"'"]) {
		[self showTriggers:nil];
		return YES;
	}
	if ([[theEvent charactersIgnoringModifiers] isEqualToString:@"; "]) {
		[self showCatalog:nil];
		return YES;
	}
	return NO;

}

#ifdef DEBUG
- (IBAction)sendReleaseAll:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:QSReleaseAllNotification object:nil];  }
#endif

- (IBAction)showGuide:(id)sender { [QSPreferencesController showPaneWithIdentifier:@"QSMainMenuPrefPane"];  }
- (IBAction)showSettings:(id)sender { [QSPreferencesController showPaneWithIdentifier:@"QSSettingsPanePlaceholder"];  }
- (IBAction)showCatalog:(id)sender { [QSPreferencesController showPaneWithIdentifier:@"QSCatalogPrefPane"];  }
- (IBAction)showPlugins:(id)sender { [QSPreferencesController showPaneWithIdentifier:@"QSPlugInsPrefPane"];  }
- (IBAction)showTriggers:(id)sender { [QSPreferencesController showPaneWithIdentifier:@"QSTriggersPrefPane"];  }
- (IBAction)showHelp:(id)sender { [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kHelpURL]];  }
- (IBAction)getMorePlugIns:(id)sender { [QSPlugInsPrefPane getMorePlugIns];  }
- (IBAction)outputMissingLocalizations:(id)sender {
#if DEBUG
	/* missingLocalizedValuesForAllTables *only* exists in debug ! */
	NSMutableDictionary *missingBundles = [NSBundle performSelector:@selector(missingLocalizedValuesForAllBundles)];
	NSLog(@"Missing localisations for bundles: %@", missingBundles);
	
	NSString *localizationPath = QSApplicationSupportSubPath(@"Localization", YES);
	for (NSString *bundleIdentifier in missingBundles) {
		NSMutableDictionary *missingLocales = [missingBundles objectForKey:bundleIdentifier];
		for (NSString *missingLocaleKey in missingLocales) {
			NSMutableDictionary *missingTables = [missingLocales objectForKey:missingLocaleKey];
			for (NSString *missingTableKey in missingTables) {
				NSMutableDictionary *missingTable = [missingTables objectForKey:missingTableKey];
				NSString *tablePath = [[localizationPath stringByAppendingPathComponent:bundleIdentifier] stringByAppendingPathComponent:missingLocaleKey];
				NSString *tableName = [[tablePath stringByAppendingPathComponent:missingTableKey] stringByAppendingPathExtension:@"strings"];
				[[NSFileManager defaultManager] createDirectoriesForPath:tablePath];
				[missingTable writeToFile:tableName atomically:NO];
			}
		}
	}
#endif
}

- (IBAction)unsureQuit:(id)sender {
	// NSLog(@"sender (%@) %@", sender, [NSApp currentEvent]);

	if ([[NSApp currentEvent] type] == NSKeyDown && [[NSUserDefaults standardUserDefaults] boolForKey:kDelayQuit]) {
		if ([[NSApp currentEvent] isARepeat]) return;

		QSWindow *quitWindow = nil;
		if (!quitWindowController) {
			quitWindowController = [[NSWindowController alloc] initWithWindowNibName:@"QuitConfirm"];

			quitWindow = (QSBorderlessWindow *)[quitWindowController window];
			[quitWindow setLevel:kCGPopUpMenuWindowLevel+1];
			[quitWindow setIgnoresMouseEvents:YES];
			[quitWindow setShowEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSVExpandEffect", @"transformFn", @"show", @"type", [NSNumber numberWithDouble:0.15] , @"duration", nil]];
			[quitWindow setHideEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSShrinkEffect", @"transformFn", @"hide", @"type", [NSNumber numberWithDouble:0.25] , @"duration", nil]];
		} else {
			quitWindow = (QSBorderlessWindow *)[quitWindowController window];
		}

		NSString *currentCharacters = [[NSApp currentEvent] charactersIgnoringModifiers];

		[quitWindow orderFront:self];

		NSEvent *theEvent = [NSApp nextEventMatchingMask:NSKeyUpMask untilDate:[NSDate dateWithTimeIntervalSinceNow:0.625] inMode:NSDefaultRunLoopMode dequeue:YES];

		BOOL shouldQuit = !theEvent;

		if (theEvent) {
			theEvent = [NSApp nextEventMatchingMask:NSKeyDownMask untilDate:[NSDate dateWithTimeIntervalSinceNow:0.625] inMode:NSDefaultRunLoopMode dequeue:YES];
			if ([[theEvent charactersIgnoringModifiers] isEqualToString:currentCharacters])
				shouldQuit = YES;
		}

		if (shouldQuit) {
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.333]];
			[quitWindow orderOut:self];
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.50]];
			[NSApp terminate:self];
		}
		[quitWindow orderOut:self];
	} else {
		[NSApp terminate:self];
	}
}

- (IBAction)showTaskViewer:(id)sender {
	[NSApp activateIgnoringOtherApps:YES];
    [[QSTaskViewer sharedInstance] toggleWindow:self];
}

- (BOOL)validateMenuItem:(NSMenuItem*)anItem {
	SEL action = [anItem action];
	if (action == @selector(showForums:) || action == @selector(reportABug:) || action == @selector(showHelp:) || action == @selector(openIRCChannel:) ) {
		if (![anItem image])
			[anItem setImage:[[NSImage imageNamed:@"DefaultBookmarkIcon"] duplicateOfSize:QSSize16]];
		return YES;
	}
	if (action == @selector(showReleaseNotes:) ) {
		if (![anItem image])
			[anItem setImage:[[NSImage imageNamed:@"Catalog"] duplicateOfSize:QSSize16]];
	} else if (action == @selector(rescanItems:) ) {
		if (![anItem image])
			[anItem setImage:[[NSImage imageNamed:@"Button-Rescan"] duplicateOfSize:QSSize16]];
	} else if (action == @selector(showPreferences:) || action == @selector(showSettings:) ) {
		if (![anItem image])
			[anItem setImage:[[QSResourceManager imageNamed:@"prefsGeneral"] duplicateOfSize:QSSize16]];
	} else if (action == @selector(showGuide:) ) {
		if (![anItem image])
			[anItem setImage:[[QSResourceManager imageNamed:@"Quicksilver"] duplicateOfSize:QSSize16]];
	} else if (action == @selector(getMorePlugIns:) ) {
		if (![anItem image])
			[anItem setImage:[[NSImage imageNamed:@"QSPlugIn"] duplicateOfSize:QSSize16]];
	} else if (action == @selector(showCatalog:) ) {
		if (![anItem image])
			[anItem setImage:[[NSImage imageNamed:@"Catalog"] duplicateOfSize:QSSize16]];
	} else if ([anItem action] == @selector(showShelf:) ) {
		return YES;
	} else if ([anItem action] == @selector(showTriggers:) ) {
		if (![anItem image])
			[anItem setImage:[[NSImage imageNamed:@"Triggers"] duplicateOfSize:QSSize16]];
		return [[QSReg tableNamed:@"QSTriggerManagers"] count];
	} else if ([anItem action] == @selector(unsureQuit:) ) {
		[anItem setTitle:@"Quit Quicksilver"];
		return YES;
	}
	return YES;
}

- (void)displayStatusMenuAtPoint:(NSPoint)point { [NSMenu popUpContextMenu:[NSApp mainMenu] withEvent:[NSEvent mouseEventWithType:NSLeftMouseDown location:NSMakePoint(500, 500) modifierFlags:0 timestamp:0 windowNumber:0 context:nil eventNumber:0 clickCount:1 pressure:0] forView:[NSView focusView] withFont:nil]; }

- (NSMenu *)statusMenuWithQuit {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	if ([defaults boolForKey:@"QSUseFullMenuStatusItem"])
		return [NSApp mainMenu];

	NSMenu *newMenu = [statusMenu copy];

	NSMenuItem *modulesItem = [[NSApp mainMenu] itemWithTag:128];
	[newMenu addItem:[modulesItem copy]];

	[newMenu addItem:[NSMenuItem separatorItem]];
	NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit Quicksilver" action:@selector(terminate:) keyEquivalent:@""];
	[quitItem setTarget:NSApp];
	[newMenu addItem:quitItem];

	return newMenu;
}

- (void)activateInterfaceTransmogrified:(id)sender {
	NSWindow *modal = [NSApp modalWindow];
	if (modal) {
		NSBeep();
		[NSApp activateIgnoringOtherApps:YES];
		[modal makeKeyAndOrderFront:self];
	} else {
		id iController = [self interfaceController];
		if (!iController)
			NSBeep();
		[iController activateInTextMode:self];
	}
}

- (void)activateInterface:(id)sender {
	NSWindow *modal = [NSApp modalWindow];
	if (modal) {
		NSBeep();
		[NSApp activateIgnoringOtherApps:YES];
		[modal makeKeyAndOrderFront:self];
	} else {
		QSInterfaceController *iController = [self interfaceController];
		if (!iController)
			NSBeep();
		[iController activate:self];
	}
}

- (void)openURL:(NSURL *)url {
	AESetInteractionAllowed(kAEInteractWithSelf);
	if ([[url scheme] isEqualToString:@"qsinstall"]) {
		NSLog(@"Install: %@", url);
		[[QSPlugInManager sharedInstance] handleInstallURL:url];
	} else if ([[url scheme] isEqualToString:@"qs"]) {
		id handler = [QSReg instanceForKey:[url host] inTable:@"QSInternalURLHandlers"];
		//if (VERBOSE) NSLog(@"Handling %@ [%@] ", url, handler);
		if ([handler respondsToSelector:@selector(handleURL:)])
			[handler handleURL:url];
	} else {
		QSObject *entry;
		entry = [QSObject URLObjectWithURL:[url absoluteString] title:[NSString stringWithFormat:@"Search %@", [url host]]];
		[entry loadIcon];
		[[self interfaceController] selectObject:entry];
		[self activateInterface:self];
		[[self interfaceController] shortCircuit:self];
	}
}

- (void)showSplash:sender {

	[splashWindow setReleasedWhenClosed:NO];
	[splashWindow setBackgroundColor:[NSColor clearColor]];
	[splashWindow setLevel:NSFloatingWindowLevel];
    [splashWindow reallyCenter];
    [splashWindow setAlphaValue:0];
    [splashWindow setSticky:YES];
	__weak QSController *weakSelf = self;
    if ([NSApp wasLaunchedAtLogin]) {
        [splashWindow setLevel:NSNormalWindowLevel-1];
		[splashWindow orderFront:self];
		QSWindowAnimation *animation = [QSWindowAnimation effectWithWindow:splashWindow attributes:@{kQSGSDuration: @0.33, kQSGSAlphaA: @0, kQSGSAlphaB: @0.25}];
		[animation setDelegate:weakSelf];
		[animation setAnimationBlockingMode:NSAnimationBlocking];
		[animation startAnimation];
		
    } else {
		[splashWindow orderFront:self];
        QSWindowAnimation *animation = [QSWindowAnimation showHelperForWindow:splashWindow];
		[animation setDelegate:weakSelf];
        [animation setTransformFt:QSExtraExtraEffect];
        [animation setDuration:1.0];
        [animation setAnimationBlockingMode:NSAnimationBlocking];
        [animation startAnimation];
		
    }
}
- (void)animationDidEnd:(NSAnimation *)animation {
	QSGCDMainDelayed(0.05, ^{
		[self hideSplash:animation];
	});
}

- (void)hideSplash:sender {
    if (splashWindow) {
        [splashWindow flare:self];
        [splashWindow close];
        splashWindow = nil;
    }
}
- (void)startDropletConnection {
	if (dropletConnection) return;
	dropletConnection = [NSConnection serviceConnectionWithName:@"Quicksilver Droplet" rootObject:self];
}

- (void)handlePasteboardDrop:(NSPasteboard *)pb commandPath:(NSString *)path {
	QSObject *drop = [QSObject objectWithPasteboard:pb];
	[self setDropletProxy:drop];
	[self executeCommandAtPath:path];
	[self setDropletProxy:nil];
}

- (void)executeCommandAtPath:(NSString *)path { [[QSCommand commandWithFile:path] execute];  }
- (void)performService:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error {
#ifdef DEBUG
	if (VERBOSE) NSLog(@"Perform Service: %@ %C", userData, [userData characterAtIndex:0]);
#endif
	[self receiveObject:[[QSObject alloc] initWithPasteboard:pboard]];
}
- (void)getSelection:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error {
#ifdef DEBUG
	if (VERBOSE) NSLog(@"GetSel Service: %@ %C", userData, [userData characterAtIndex:0]);
#endif
	[self receiveObject:[[QSObject alloc] initWithPasteboard:pboard]];
}

- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard {
	[self receiveObject:[[QSObject alloc] initWithPasteboard:pboard]];
	return YES;
}

- (void)receiveObject:(QSObject *)object {
	[[self interfaceController] clearObjectView:[[self interfaceController] dSelector]];
	[[self interfaceController] selectObject:object];
    [[self interfaceController] actionActivate:nil];
}

- (NSObject *)dropletProxy { return dropletProxy;  }
- (void)setDropletProxy:(NSObject *)newDropletProxy {
	if (dropletProxy != newDropletProxy) {
		dropletProxy = newDropletProxy;
	}
}


- (id)resolveProxyObject:(id)proxy {
	if ([[proxy identifier] isEqualToString:@"QSDropletItemProxy"]) {
		return dropletProxy;
	} else {
		QSObject *object = [[[self interfaceController] dSelector] objectValue];
		if ([object isEqual:proxy]) return [[[self interfaceController] dSelector] previousObjectValue];
		return object;
	}
	return nil;
}

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key {
	if ([key isEqual:@"QSSelection"])
		return YES;
	return NO;
}

- (void)setQSSelection:(id)sel {
	QSObject *object = nil;
	if ([sel isKindOfClass:[NSString class]]) {
		object = [QSObject objectWithString:(NSString *)sel];
	} else if ([sel isKindOfClass:[NSArray class]]) {
        NSArray *objs = [(NSArray *)sel arrayByEnumeratingArrayUsingBlock:^id(id obj) {
            if ([obj isKindOfClass:[NSString class]]) {
                return [QSObject objectWithString:obj];
            }
            return nil;
        }];
		object = [QSObject objectByMergingObjects:objs];
    } else {
		object = [QSObject objectWithAEDescriptor:sel];
	}
	[self receiveObject:object];
}

- (id)QSSelection {
	QSObject *selection = (QSObject*)[[self interfaceController] selection];
	NSLog(@"object %@", selection);
    if ([[selection primaryType] isEqualToString:QSFilePathType]) {
        NSArray *paths = [selection validPaths];
        if (paths) {
            return ([paths count] == 1 ? [paths lastObject] : paths);
        }
    }
    if ([[selection primaryType] isEqualToString:QSURLType]) {
        return [NSURL performSelector:@selector(URLWithString:) onObjectsInArray:[[selection splitObjects] valueForKey:@"primaryObject"] returnValues:YES];
    }
    return [selection stringValue];
}

//Notifications

/* NSWorkspaceWillLaunchApplicationNotification */
- (void)appWillLaunch:(NSNotification *)notif {
	if ([[[notif userInfo] objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:[[NSBundle mainBundle] bundleIdentifier]])
		[NSApp terminate:self];
	//	else
	//		NSLog(@"App: %@ %@", [[notif userInfo] objectForKey:@"NSApplicationBundleIdentifier"] , [[NSBundle mainBundle] bundleIdentifier]);
}

/* NSWorkspaceDidLaunchApplicationNotification */
- (void)appLaunched:(NSNotification*)notif {
	NSString *launchedApp = [[notif userInfo] objectForKey:@"NSApplicationName"];
	if ([launchedApp isEqualToString:@"Dock0"])
		NSLog(@"%@ Launching ", launchedApp);
}

- (void)appChanged:(NSNotification *)aNotification {
    [QSModifierKeyEvent resetModifierState];
}

- (IBAction)rescanItems:sender { [QSLib startThreadedScan];  }
- (IBAction)forceRescanItems:sender { [QSLib startThreadedAndForcedScan];  }

- (void)delayedStartup {
        
#ifdef DEBUG
    if (DEBUG_STARTUP) NSLog(@"Delayed Startup");
#endif
    
    QSTask *task = [QSTask taskWithIdentifier:@"QSDelayedStartup"];
    task.name = NSLocalizedString(@"Starting Up...", @"Delayed startup task name");
    task.status = NSLocalizedString(@"Updating Catalog", @"Delayed startup task status");
    [task start];
    [[QSLibrarian sharedInstance] loadMissingIndexes];
    [task stop];
}

- (void)checkForFirstRun {

#ifdef DEBUG
	launchStatus = QSApplicationNormalLaunch;
#else
	launchStatus = [NSApp checkLaunchStatus];
#endif

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
	NSString *lastVersionString = [defaults objectForKey:kLastUsedVersion];
	NSUInteger lastVersion = [lastVersionString respondsToSelector:@selector(hexIntValue)] ? [lastVersionString hexIntValue] : 0;
	switch (launchStatus) {
		case QSApplicationUpgradedLaunch: {
/** Turn off "running from a new location" and "you are using a new version of QS" popups for DEBUG builds **/
#ifndef DEBUG     
            NSString *lastLocation = [defaults objectForKey:kLastUsedLocation];
			if (lastLocation && ![bundlePath isEqualToString:[lastLocation stringByStandardizingPath]]) {
				//New version in new location.
				[NSApp activateIgnoringOtherApps:YES];
				NSInteger selection = NSRunAlertPanel(NSLocalizedString(@"Running from a new location",nil), NSLocalizedString(@"The previous version of Quicksilver was located in \"%@\". Would you like to move this new version to that location?",nil), NSLocalizedString(@"Move and Relaunch",nil), NSLocalizedString(@"Don't Move",nil), nil, [[lastLocation stringByDeletingLastPathComponent] lastPathComponent]);
				if (selection)
					[NSApp relaunchAtPath:lastLocation movedFromPath:bundlePath];
			}
			if ([defaults boolForKey:kShowReleaseNotesOnUpgrade]) {
				[NSApp activateIgnoringOtherApps:YES];
				NSInteger selection = NSRunInformationalAlertPanel([NSString stringWithFormat:NSLocalizedString(@"Quicksilver has been updated",nil), nil] , NSLocalizedString(@"You are using a new version of Quicksilver. Would you like to see the Release Notes?",nil), NSLocalizedString(@"Show Release Notes",nil), NSLocalizedString(@"Later",nil), nil);
				if (selection == 1)
					[self showReleaseNotes:self];
			}
			if (lastVersion < [@"3929" hexIntValue] && [[NSRunningApplication currentApplication] executableArchitecture] == NSBundleExecutableArchitectureX86_64) {
				// first time-running a 64-bit version
				NSRunInformationalAlertPanel(NSLocalizedString(@"Quicksilver is now 64-bit", nil), NSLocalizedString(@"64-bit details", nil), NSLocalizedString(@"OK", nil), nil, nil);
			}
#endif
			
            // Not localizing this, as it's pretty much obsolete
			[[NSWorkspace sharedWorkspace] setComment:@"Quicksilver" forFile:[[NSBundle mainBundle] bundlePath]];
            versionChanged = YES;
			break;
        }
		case QSApplicationDowngradedLaunch: {
/** Turn off "you have previously used a newer version" popup for DEBUG builds **/
#ifndef DEBUG
			[NSApp activateIgnoringOtherApps:YES];
#endif
			QSAlertResponse response =  [NSAlert runAlertWithTitle:NSLocalizedString(@"This is an old version of Quicksilver",nil)
														   message:NSLocalizedString(@"You have previously used a newer version. Perhaps you have duplicate copies?",nil)
														   buttons:@[NSLocalizedString(@"Reveal this copy",nil), NSLocalizedString(@"Ignore",nil)]
															 style:NSAlertStyleInformational];
			if (response == QSAlertResponseOK) {
				[[NSWorkspace sharedWorkspace] selectFile:[[NSBundle mainBundle] bundlePath] inFileViewerRootedAtPath:@""];
			}
            versionChanged = YES;
            break;
        }
		case QSApplicationFirstLaunch: {
			NSString *containerPath = [[bundlePath stringByDeletingLastPathComponent] stringByStandardizingPath];
			BOOL shouldInstall = [containerPath isEqualToString:@"/Volumes/Quicksilver"] || [containerPath isEqualToString:[[QSDownloads downloadsLocation] path]];
			if (shouldInstall) {
				//New version in new location.
				[NSApp activateIgnoringOtherApps:YES];

                NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Would you like to install Quicksilver?",nil)
                                                 defaultButton:NSLocalizedString(@"Install in \"Applications\"",nil)
                                               alternateButton:NSLocalizedString(@"Quit",nil)
                                                   otherButton:NSLocalizedString(@"Choose Location...",nil)
                                     informativeTextWithFormat:@"%@", NSLocalizedString(@"Quicksilver was launched from a download location.\rWould you like to copy Quicksilver to your applications folder?",nil)];

                QSAlertResponse response = [alert runAlert];

				NSString *installPath = nil;
				if (response == QSAlertResponseFirst) {
					installPath = @"/Applications";
				} else if (response == QSAlertResponseThird) {
					NSOpenPanel *openPanel = [NSOpenPanel openPanel];
					[openPanel setCanChooseDirectories:YES];
					[openPanel setCanChooseFiles:NO];
					[openPanel setPrompt:NSLocalizedString(@"Install Here",nil)];
					[openPanel setTitle:NSLocalizedString(@"Install Quicksilver",nil)];
					if (NSFileHandlingPanelOKButton == [openPanel runModal]) {
						installPath = [[openPanel URL] path];
					}
				}
				if (installPath) {
					NSLog(@"Installing Quicksilver at: %@", installPath);
					installPath = [installPath stringByAppendingPathComponent:[bundlePath lastPathComponent]];
					[NSApp relaunchAtPath:installPath movedFromPath:bundlePath];
				}
				[NSApp terminate:self];
			}
		}
			break;
		default: // QSApplicationNormalLaunch:
			break;
	}

	// Don't block the interface with the setup assistant if running a test build
#ifndef TESTING
	if (![defaults boolForKey:kSetupAssistantCompleted] || lastVersion <= [@"3694" hexIntValue] || ![defaults boolForKey:@"QSAgreementAccepted"])
		runningSetupAssistant = YES;
#endif

#ifndef DEBUG
	[NSApp updateLaunchStatusInfo];
#endif
}

- (void)checkForCrash {
    // TODO - if the crash reporter is hidden, we need an option to send crashes automatically

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // hidden pref to disable the crash reporter from showing
    if ([defaults boolForKey:@"QSRestartAutomaticallyWithoutCrashReporter"]) {
        return;
    }
    
    // obtain the last known crash date from the prefs
    NSDate *lastKnownCrashDate = [defaults objectForKey:kLastKnownCrashDate];
    
	NSFileManager *fm = [[NSFileManager alloc] init];
    
    // get a list of files beginning with 'Quicksilver' from the crash reporter folder
    NSArray *files = [fm contentsOfDirectoryAtPath:pCrashReporterFolder error:nil];
    NSArray *filteredFiles = [files filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[c] 'Quicksilver'"]];

    NSDate *mostRecentCrashDate = [NSDate distantPast];
    // Enumerate crash files to find most recent crash report
    for (NSString *individualFile in filteredFiles) {
        NSDate *individualDate = [[fm attributesOfItemAtPath:[pCrashReporterFolder stringByAppendingPathComponent:individualFile] error:nil] objectForKey:NSFileCreationDate];
        if ([individualDate compare:mostRecentCrashDate] == NSOrderedDescending) {
            mostRecentCrashDate = individualDate;
            [self setCrashReportPath:individualFile];
        }
    }

    // path to the most recent crash report (used by the crash reporter for sending the file to the server)
    [self setCrashReportPath:[pCrashReporterFolder stringByAppendingPathComponent:crashReportPath]];
    
    // Check the QuicksilverState.plist file to see if a plugin caused a crash
    NSDictionary *state = [NSDictionary dictionaryWithContentsOfFile:pStateLocation];
    NSString *pluginName = [state objectForKey:kQSPluginCausedCrashAtLaunch];
    NSWindowController *QSCrashController = nil;
	// check to see if Quicksilver crashed since last used (there's a newer crash report or a plugin crashed)
	if ((lastKnownCrashDate && [mostRecentCrashDate compare:lastKnownCrashDate] == NSOrderedDescending) ||  pluginName) {
        
        // Crash due to faulty plugin
        if (pluginName) {
            // There are no crash reports for these, so set the crashReportPath to nil
            [self setCrashReportPath:nil];
        }

        // Crash occurred, load the crash reporter window
        QSCrashController = [[QSCrashReporterWindowController alloc] initWithWindowNibName:@"QSCrashReporter"];
        // Open the crash reporter window
        [NSApp runModalForWindow:[QSCrashController window]];
    }

    // synchronise prefs and QuicksilverState file
    [fm removeItemAtPath:pStateLocation error:nil];
    [defaults setObject:mostRecentCrashDate forKey:kLastKnownCrashDate];
    [defaults synchronize];

}

- (IBAction)showReleaseNotes:(id)sender {
    
    NSURL *appURL = nil;
    CFURLRef *appURLRefPointer = (void *)&appURL;
    LSGetApplicationForURL((__bridge CFURLRef)[NSURL URLWithString:@"http://"], kLSRolesAll, NULL, appURLRefPointer);
    [[NSWorkspace sharedWorkspace] openFile:[[[NSBundle mainBundle] sharedSupportPath] stringByAppendingPathComponent:@"Changes.html"] withApplication:[appURL path]];
}

- (QSInterfaceController *)interfaceController { return [QSReg preferredCommandInterface];  }

- (void)setInterfaceController:(QSInterfaceController *)newInterfaceController {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	if (interfaceController)
		[nc postNotificationName:QSReleaseAllCachesNotification object:self];
	interfaceController = newInterfaceController;
	[nc postNotificationName:QSInterfaceChangedNotification object:self];
}

- (void)clearHistory
{
	[[[self interfaceController] dSelector] clearHistory];
}

- (void)relaunchQuicksilver
{
	[NSApp relaunch:nil];
}

# pragma mark - Accessibility Permissions

-(BOOL)checkForAccessibilityPermission {
		#ifdef TESTING
			return YES;
		#endif

       // Prompt for accessibility permissions on macOS Mojave and later.
       if (!accessibilityChecker) {
               accessibilityChecker = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
                       [self checkForAccessibilityPermission];
               }];
               [accessibilityChecker fire];
       }
       NSDictionary *options = @{(id)CFBridgingRelease(kAXTrustedCheckOptionPrompt): @NO};
       BOOL accessibilityEnabled = AXIsProcessTrustedWithOptions((CFDictionaryRef)options);
       if(!accessibilityEnabled) {
               if (![accessibilityPermissionWindow isVisible]) {
                       [self showAccessibilityPrompt:nil];
               }
               return NO;
       }else{
		   [self closeAccessibilityPrompt:nil];
       }
       return YES;
}

-(IBAction)showAccessibilityPrompt:(id)sender {
       [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeAccessibilityPrompt:) name:NSWindowWillCloseNotification object:accessibilityPermissionWindow];
    [NSApp activateIgnoringOtherApps:YES];
    [accessibilityPermissionWindow center];
    [accessibilityPermissionWindow setIsVisible:YES];
    [accessibilityPermissionWindow makeKeyAndOrderFront:sender];
       
}

- (IBAction)closeAccessibilityPrompt:(NSNotification *)notif {
	[accessibilityChecker invalidate];
	accessibilityChecker = nil;
	if(!notif  && [accessibilityPermissionWindow isVisible]) {
		[accessibilityPermissionWindow close];
	}
	accessibilityPermissionWindow = nil;
}

-(IBAction)launchPrivacyPreferences:(id)sender {
    NSString *urlString = @"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility";
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}

@end

@implementation QSController (Application)

//- (void)applicationDidResignActive:(NSNotification *)aNotification {}

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"QSEventNotification" object:@"QSQuicksilverWillQuitEvent" userInfo:nil];
	return YES;
}

- (void)writeLeaksToFileAtPath:(NSString*)path {
    NSFileHandle * output = [NSFileHandle fileHandleForWritingAtPath:path];
    if(output == nil)
        output = [NSFileHandle fileHandleWithStandardError];
    NSTask * leaksTask = [NSTask taskWithLaunchPath:@"/usr/bin/leaks"
                                          arguments:[NSArray arrayWithObjects:
                                                     [NSString stringWithFormat:@"%u", getpid()],
                                                     nil]];
    [leaksTask setStandardOutput:output];
    [leaksTask setStandardError:output];
    NSLog( @"Writing leaks to %@", ( path != nil ? path : @"stderr" ) );
    [leaksTask launch];
    [leaksTask waitUntilExit];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"WindowsShouldHide" object:self];
//    if (DEBUG_MEMORY) [self writeLeaksToFileAtPath:QSApplicationSupportSubPath(@"QSLeaks.plist", NO)];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
	
	[self startMenuExtraConnection];

    QSGetLocalizationStatus();

    // Honor dock preference (if statement true if icon is NOT set to hide)
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:kHideDockIcon]) {
        if (![defaults objectForKey:@"QSShowMenuIcon"])
            [defaults setInteger:0 forKey:@"QSShowMenuIcon"];
        [self showDockIcon];
    }
}

- (void)setupSplash {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kUseEffects]) {
		[self showSplash:nil];
	}
}
- (void)startQuicksilver:(id)sender {
	[self checkForFirstRun];
	[self checkForCrash];

#ifdef DEBUG
	if (DEBUG_STARTUP)
		NSLog(@"Instantiate Classes");
#endif
	
	[QSRegistry sharedInstance];
	
#ifdef DEBUG
	if (DEBUG_STARTUP)
		NSLog(@"Registry loaded");
#endif

	[QSMnemonics sharedInstance];
	[QSLibrarian sharedInstance];
	[QSExecutor sharedInstance];
	[QSTaskController sharedInstance];
	[QSUpdateController sharedInstance];

	if ([NSApplication isSierra]) {
		[NSApp setAutomaticCustomizeTouchBarMenuItemEnabled:YES];
	}

#ifdef DEBUG
	if (DEBUG_STARTUP)
		NSLog(@"Library loaded");
#endif

	[[QSPlugInManager sharedInstance] loadPlugInsAtLaunch];
	
#ifdef DEBUG
	if (DEBUG_STARTUP)
		NSLog(@"PlugIns loaded");
#endif

	[[QSLibrarian sharedInstance] initCatalog];

	[[QSLibrarian sharedInstance] pruneInvalidChildren:nil];
	[[QSLibrarian sharedInstance] loadCatalogInfo];

	[QSExec loadFileActions];

	[[QSLibrarian sharedInstance] reloadIDDictionary:nil];
	[[QSLibrarian sharedInstance] enableEntries];
	
#ifdef DEBUG
	if (DEBUG_STARTUP)
		NSLog(@"Catalog loaded");
#endif

#ifndef DEBUG
	if (versionChanged) {
		if (!runningSetupAssistant) {
			NSLog(@"New Version: Purging all Identifiers and Forcing Rescan");
			[QSLibrarian removeIndexes];
			[QSLib startThreadedAndForcedScan];
		}
	} else {
		[[QSLibrarian sharedInstance] loadCatalogArrays];
	}
#endif
	
#ifdef DEBUG
	[[QSLibrarian sharedInstance] loadCatalogArrays];
#endif
	
	[[QSLibrarian sharedInstance] reloadEntrySources:nil];

	[NSApp setServicesProvider:self];

	// Setup Activation Hotkey
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	quitWindowController = nil;

	NSInteger rescanInterval = [defaults integerForKey:@"QSCatalogRescanFrequency"];

	if (rescanInterval>0) {
		
#ifdef DEBUG
		if (DEBUG_STARTUP) NSLog(@"Rescanning every %ld minutes", (long)rescanInterval);
#endif
		
		[NSTimer scheduledTimerWithTimeInterval:rescanInterval*60 target:self selector:@selector(rescanItems:) userInfo:nil repeats:YES];
	}

#ifdef DEBUG
	if (DEBUG_STARTUP) NSLog(@"Register for Notifications");
#endif
	
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	[[ws notificationCenter] addObserver:self selector:@selector(appLaunched:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
	[[ws notificationCenter] addObserver:self selector:@selector(appWillLaunch:) name:NSWorkspaceWillLaunchApplicationNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appChanged:) name:QSActiveApplicationChanged object:nil];

	[[[NSApp mainMenu] itemAtIndex:0] setTitle:@"Quicksilver"];
	
#ifdef DEBUG
	if (DEBUG_STARTUP) NSLog(@"Will Finish Launching");

    [self activateDebugMenu];
#endif

	if (runningSetupAssistant) {
		[self hideSplash:nil];
		[self runSetupAssistant:nil];
	}
	char *visiblePref = getenv("QSVisiblePrefPane");
	if (visiblePref) {
		[QSPreferencesController showPaneWithIdentifier:[NSString stringWithUTF8String:visiblePref]];
        unsetenv("QSVisiblePrefPane");
    }

	[QSResourceManager sharedInstance];
	[[QSTriggerCenter sharedInstance] activateTriggers];
	
#ifdef DEBUG
	if (DEBUG_STARTUP) NSLog(@"Did Finish Launching\n ");
#endif

	[self bind:@"showMenuIcon" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.QSShowMenuIcon" options:nil];

	if ([defaults boolForKey:kAutomaticTaskViewer])
		[QSTaskViewer sharedInstance];

	if ( ! (runningSetupAssistant || versionChanged) )
		[self rescanItems:self];

#if 0
	[self recompositeIconImages];
#endif

	[[self interfaceController] window];

	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

	if ([NSApp wasLaunchedAtLogin])
		[nc postNotificationName:@"QSEventNotification" object:@"QSQuicksilverLaunchedAtLoginEvent" userInfo:nil];

	[nc postNotificationName:@"QSEventNotification" object:@"QSQuicksilverLaunchedEvent" userInfo:nil];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [self delayedStartup];
    });
	[self startDropletConnection];
	if (!runningSetupAssistant) {
		[self setupSplash];
	}
}

- (id)activationHotKey { return nil;  }
- (void)setActivationHotKey:(id)object {
	[[QSHotKeyEvent hotKeyWithIdentifier:kActivationHotKey] setEnabled:NO];
	UInt16 keyCode = [[object objectForKey:@"keyCode"] unsignedShortValue];
	NSUInteger modifiers = [[object objectForKey:@"modifiers"] unsignedLongValue];
	QSHotKeyEvent *activationKey = [QSHotKeyEvent getHotKeyForKeyCode:keyCode modifierFlags:modifiers];
	[activationKey setTarget:self selectorReleased:(SEL) 0 selectorPressed:@selector(activateInterface:)];
	[activationKey setIdentifier:kActivationHotKey];
	[activationKey setEnabled:YES];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
#ifdef DEBUG
    NSDate *start;
    if (VERBOSE) {
        start = [NSDate date];
    }
#endif
	[self startQuicksilver:aNotification];
#ifdef DEBUG
    if (VERBOSE) {
        NSLog(@"-[QSController startQuicksilver:] took %lfs", -1*([start timeIntervalSinceNow]));
    }
#endif
    [NSApp disableRelaunchOnLogin];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"QSApplicationDidFinishLaunchingNotification" object:self];
    [QSObject interfaceChanged];
    
    // Setup Activation Hotkey
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
	if ([defaults integerForKey:@"QSModifierActivationCount"] >0) {
		QSModifierKeyEvent *modActivation = [[QSModifierKeyEvent alloc] init];
		[modActivation setModifierActivationMask: [defaults integerForKey:@"QSModifierActivationKey"]];
		[modActivation setModifierActivationCount:[defaults integerForKey:@"QSModifierActivationCount"]];
		[modActivation setTarget:self];
		[modActivation setIdentifier:@"QSModKeyActivation"];
		[modActivation setAction:@selector(activateInterface:)];
		[modActivation enable];
	}
    
	id oldModifiers = [defaults objectForKey:kHotKeyModifiers];
	id oldKeyCode = [defaults objectForKey:kHotKeyCode];
    
	//Update hotkey prefs
    
	if (oldModifiers && oldKeyCode) {
		NSInteger modifiers = [oldModifiers unsignedIntegerValue];
		if (modifiers < (1 << (rightControlKeyBit+1) )) {
			NSLog(@"updating shortcut %ld", (long)modifiers);
			[defaults setValue:[NSNumber numberWithInteger:carbonModifierFlagsToCocoaModifierFlags(modifiers)] forKey:kHotKeyModifiers];
			[defaults synchronize];
		}
        
		NSLog(@"Updating Activation Key");
		[defaults removeObjectForKey:kHotKeyModifiers];
		[defaults removeObjectForKey:kHotKeyCode];
		[defaults setObject:[NSDictionary dictionaryWithObjectsAndKeys:oldModifiers, @"modifiers", oldKeyCode, @"keyCode", nil] forKey:@"QSActivationHotKey"];
		[defaults synchronize];
	}
    
	[self bind:@"activationHotKey" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.QSActivationHotKey" options:nil];

    // make sure we're visible on the first activation
    [NSApp unhideWithoutActivation];
	
	if (!runningSetupAssistant) {
		[[QSDonationController sharedInstance] checkDonationStatus:launchStatus];
	}
	
	// check for accessibility access
	accessibilityChecker = nil;
	[self checkForAccessibilityPermission];

	[QSApp setCompletedLaunch:YES];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
	[self activateInterface:theApplication];
	return YES;
}

#if 0
- (void)applicationWillBecomeActive:(NSNotification *)aNotification {
	//	NSLog(@"active");
}
#endif

- (void)application:(NSApplication *)app openFiles:(NSArray *)fileList {
	NSArray *plugIns = nil;
	if ([(plugIns = [fileList pathsMatchingExtensions:[NSArray arrayWithObjects:@"qspkg", @"qsplugin", nil]]) count]) {
		[[QSPlugInManager sharedInstance] installPlugInsFromFiles:plugIns];
	} else if ([(plugIns = [fileList pathsMatchingExtensions:[NSArray arrayWithObject:@"qscatalog"]]) count]) {
		for(NSString * path in plugIns)
			[QSCatalogPrefPane addEntryForCatFile:path];
	} else if ([(plugIns = [fileList pathsMatchingExtensions:[NSArray arrayWithObject:@"qscommand"]]) count]) {
		for(NSString * path in plugIns)
			[self executeCommandAtPath:path];
	} else {
		QSObject *entry;
		entry = [QSObject fileObjectWithArray:fileList];
		[entry loadIcon];
		[[self interfaceController] selectObject:entry];
		[self activateInterface:self];
	}
}

- (NSApplicationPrintReply) application:(NSApplication *)application printFiles:(NSArray *)fileNames withSettings:(NSDictionary *)printSettings showPrintPanels:(BOOL)showPrintPanels {
	NSLog(@"Print %@ using %@ show %@", fileNames, printSettings, showPrintPanels ? @"YES" : @"NO");
	return NSPrintingFailure;
}

@end
