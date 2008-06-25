#import "QSShading.h"
#import "NSScreen_BLTRExtensions.h"
#import "NSApplication+ServicesModification.h"
#import "NDHotKeyEvent_QSMods.h"
#import "NDAlias+AliasFile.h"
#import "NDHotKeyEvent_QSMods.h"
#import "NDHotKeyEvent_QSMods.h"
#import <Quartz/Quartz.h>
#import "NDHotKeyEvent.h"
#import "NDProcess.h"
#import "QSProxyObject.h"
#import "NSApplication_BLTRExtensions.h"
#import "NSException_TraceExtensions.h"
#import "NSException_TraceExtensions.h"
#import "NSFileManager_BLTRExtensions.h"
#import "NSStatusItem_BLTRExtensions.h"
#import "QSAboutWindowController.h"
#import "QSApp.h"
#import "QSBackgroundView.h"
#import "QSCatalogEntrySource.h"
#import "QSCatalogPrefPane.h"
#import "QSWindowAnimation.h"
#import "QSWindowAnimation.h"
#import "QSCommandBuilder.h"
#import "QSController.h"
#import "QSDefaultsObjectSource.h"
#import "QSExecutor.h"
#import "QSFileConflictPanel.h"
#import "QSFileSystemObjectSource.h"
#import "QSFSBrowserMediator.h"
#import "QSFSBrowserMediator.h"
#import "QSImageAndTextCell.h"
#import "QSInterfaceController.h"
#import "QSInterfaceMediator.h"
#import "QSLibrarian.h"
#import "QSMacros.h"
#import "QSModifierKeyEvents.h"
#import "QSMnemonics.h"
#import "QSNotifications.h"
#import "QSObject_AEConversion.h"
#import "QSObject_FileHandling.h"
#import "QSObject_StringHandling.h"
#import "QSObject_URLHandling.h"
#import "QSObjectView.h"
#import "QSPlugIn.h"
#import "QSPlugInManager.h"
#import "QSPlugInsPrefPane.h"
#import "QSPreferenceKeys.h"
#import "QSPreferencesController.h"
#import "QSProcessSource.h"
#import "QSRegistry.h"
#import "QSResourceManager.h"
#import "QSSearchObjectView.h"
#import "QSSetupAssistant.h"
#import "QSTaskController.h"
#import "QSTaskViewer.h"
#import "QSTask.h"
#import "QSTriggerCenter.h"
#import "QSTriggersPrefPane.h"
#import "QSUpdateController.h"
#import "QSVoyeur.h"
#import "QSWindow.h"
#import <ApplicationServices/ApplicationServices.h>
#import <Carbon/Carbon.h>
#import <ExceptionHandling/NSExceptionHandler.h>
#import <IOKit/IOCFBundle.h>
#import <QSCore/QSObject.h>
#import <QSCore/QSObject.h>
#import <QSFoundation/QSFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <stdio.h>
#include <unistd.h>

#import "QSSyncManager.h"

#define DEVEXPIRE 180.0f
#define DEPEXPIRE 365.24219878f

#include "QSLocalization.h"

#import "QSObject_Pasteboard.h"
#import "QSCommand.h"

QSController *QSCon;

@interface QSObject (QSURLHandling)
- (void)handleURL:(NSURL *)url;
@end

@interface QSController (ErrorHandling)
- (void)registerForErrors;
@end

@implementation QSController
- (void)awakeFromNib { if (!QSCon) QSCon = [self retain];  }
+ (id)sharedInstance {
	if (!QSCon)
		QSCon = [[[self class] allocWithZone:[self zone]] init];
	return QSCon;
}

+ (void)initialize {
	if (DEBUG_STARTUP) NSLog(@"Controller Initialize");
	static BOOL initialized = NO;
	if (initialized) return;
	initialized = YES;

	if (QSGetLocalizationStatus() && DEBUG_STARTUP) NSLog(@"Enabling Localization");

	[NSApp registerServicesMenuSendTypes:[NSArray arrayWithObjects:NSStringPboardType, NSRTFPboardType, nil] returnTypes:[NSArray arrayWithObjects:NSStringPboardType, NSRTFPboardType, nil]];

	[NDHotKeyEvent setSignature:'DAED'];

	[QSVoyeur sharedInstance];

#if 0
	NSImage *defaultActionImage = [NSImage imageNamed:@"defaultAction"];
	[[defaultActionImage retain] setScalesWhenResized:NO];
	[defaultActionImage setCacheMode:NSImageCacheNever];
#endif

	if (defaultBool(@"verbose") )
		setenv("verbose", "1", YES);

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
	int result = NSRunInformationalAlertPanel(@"", @"This version of Quicksilver has expired. Please download the latest version.", @"Download", @"OK", nil);
	if (result)
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kDownloadUpdateURL]];
}
#endif

- (NSString *)applicationSupportFolder {
	FSRef foundRef;
	FSFindFolder(kUserDomain, kApplicationSupportFolderType, kDontCreateFolder, &foundRef);
	unsigned char path[1024];
	FSRefMakePath(&foundRef, path, sizeof(path) );
	return [[NSString stringWithUTF8String:(char *)path] stringByAppendingPathComponent:@"Quicksilver"];
}

- (id)init {
	if (self = [super init]) {
		if (DEBUG_STARTUP) NSLog(@"Controller Init");

		// Enforce Expiration Date
		//Check if a devopment version has expired
#if 0
		if (PRERELEASEVERSION && [[NSDate date] timeIntervalSinceDate:[[[NSDate alloc] initWithTimeInterval:DAYS*(DEVELOPMENTVERSION?DEVEXPIRE:DEPEXPIRE) sinceDate:[[[NSFileManager defaultManager] fileAttributesAtPath:[[NSBundle mainBundle] executablePath] traverseLink:YES] fileModificationDate]] autorelease]]>0) {
			[self showExpireDialog];
			if (!(GetCurrentKeyModifiers() & (optionKey | rightOptionKey) ))
				[NSTimer scheduledTimerWithTimeInterval:13*HOURS target:self selector:@selector(showExpireDialog) userInfo:nil repeats:YES];
		}
#endif
		[self startMenuExtraConnection];

		QSApplicationSupportPath = [[[[NSUserDefaults standardUserDefaults] stringForKey:@"QSApplicationSupportPath"] stringByStandardizingPath] retain];

		if (![QSApplicationSupportPath length])
			QSApplicationSupportPath = [[self applicationSupportFolder] retain];
		//	NSLog(@"App Support: %@", QSApplicationSupportPath);
	}
	return self;
}

- (void)startMenuExtraConnection {
	if (controllerConnection) return;
	controllerConnection = [NSConnection defaultConnection];
	[controllerConnection registerName:@"QuicksilverControllerConnection"];
	[controllerConnection setRootObject:self];
}

- (void)handleAppleEvent:(NSAppleEventDescriptor *)event withReplyEvent: (NSAppleEventDescriptor *)replyEvent {
	//NSLog(@"handl");
}
- (void)appWillLaunch:(NSNotification *)notif {
	if ([[[notif userInfo] objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:[[NSBundle mainBundle] bundleIdentifier]])
		[NSApp terminate:self];
//	else
		//		NSLog(@"App: %@ %@", [[notif userInfo] objectForKey:@"NSApplicationBundleIdentifier"] , [[NSBundle mainBundle] bundleIdentifier]);
}

- (int) showMenuIcon {
	return -1;
}
- (void)setShowMenuIcon:(NSNumber *)mode {
	int priority = 0;

	if (statusItem) {
		[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
		[statusItem release];
		statusItem = nil;
	}

	switch ([mode intValue]) {
		case 1: priority = NSNormalStatusItemPriority; break;
		case 2: priority = NSLeftStatusItemPriority; break;
		case 3: priority = NSRightStatusItemPriority; break;
		case 4: priority = NSFarRightStatusItemPriority; break;
		default: return;
	}
	statusItem = [[NSStatusBar systemStatusBar] _statusItemWithLength:29.0f withPriority:priority];
	[statusItem retain];
	[statusItem setImage:[NSImage imageNamed:@"QuicksilverMenu"]];
	[statusItem setAlternateImage:[NSImage imageNamed:@"QuicksilverMenuPressed"]];
	[statusItem setMenu:[self statusMenuWithQuit]];
	[statusItem setHighlightMode:YES];
}

- (void)activateDebugMenu {
	NSLog(@"debug menu");
	NSMenu *debugMenu = [[[NSMenu alloc] initWithTitle:@"Debug"] autorelease];

	NSMenuItem *theItem;

	theItem = [debugMenu addItemWithTitle:@"Log Object to Console" action:@selector(logObjectDictionary:) keyEquivalent:@""];

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

	theItem = [debugMenu addItemWithTitle:@"Purge Identifiers..." action:@selector(purgeIdentifiers) keyEquivalent:@""];
	[theItem setTarget:[QSObject class]];

	theItem = [debugMenu addItemWithTitle:@"Raise Exception..." action:@selector(raiseException) keyEquivalent:@""];
	[theItem setTarget:self];

	theItem = [debugMenu addItemWithTitle:@"Crash..." action:@selector(crashQS) keyEquivalent:@""];
	[theItem setTarget:self];

	theItem = [debugMenu addItemWithTitle:@"New Prefs..." action:@selector(showPrefs) keyEquivalent:@""];
	[theItem setTarget:[QSPreferencesController class]];

	NSMenuItem *debugMenuItem = [[NSApp mainMenu] addItemWithTitle:@"Debug" action:nil keyEquivalent:@""];
	[debugMenuItem setSubmenu:debugMenu];

}
- (void)raiseException {
	[NSException raise:@"Test Exception" format:@"This is a test. It is only a test. In the event of a real exception, it would have been followed by some witty commentary."];
}

- (void)crashQS {
	NSLog((id)1);
}

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

- (IBAction)sendReleaseAll:(id)sender { [[NSNotificationCenter defaultCenter] postNotificationName:QSReleaseAllNotification object:nil];  }
- (IBAction)showGuide:(id)sender { [QSPreferencesController showPaneWithIdentifier:@"QSMainMenuPrefPane"];  }
- (IBAction)showSettings:(id)sender { [QSPreferencesController showPaneWithIdentifier:@"QSSettingsPanePlaceholder"];  }
- (IBAction)showCatalog:(id)sender { [QSPreferencesController showPaneWithIdentifier:@"QSCatalogPrefPane"];  }
- (IBAction)showTriggers:(id)sender { [QSPreferencesController showPaneWithIdentifier:@"QSTriggersPrefPane"];  }
- (IBAction)showHelp:(id)sender { [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kHelpURL]];  }
- (IBAction)getMorePlugIns:(id)sender { [QSPlugInsPrefPane getMorePlugIns];  }

- (IBAction)unsureQuit:(id)sender {
	// NSLog(@"sender (%@) %@", sender, [NSApp currentEvent]);

	if ([[NSApp currentEvent] type] == NSKeyDown && [[NSUserDefaults standardUserDefaults] boolForKey:kDelayQuit]) {
		if ([[NSApp currentEvent] isARepeat]) return;

		QSWindow *quitWindow = nil;
		if (!quitWindowController) {
			quitWindowController = [NSWindowController alloc];
			[quitWindowController initWithWindowNibName:@"QuitConfirm" owner:quitWindowController];

			quitWindow = (QSWindow *)[quitWindowController window];
			[quitWindow setLevel:kCGStatusWindowLevel+1];
			[quitWindow setIgnoresMouseEvents:YES];
			[quitWindow center];
			[quitWindow setShowEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSVExpandEffect", @"transformFn", @"show", @"type", [NSNumber numberWithFloat:0.15] , @"duration", nil]];
			[quitWindow setHideEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSShrinkEffect", @"transformFn", @"hide", @"type", [NSNumber numberWithFloat:0.25] , @"duration", nil]];
		} else {
			quitWindow = (QSWindow *)[quitWindowController window];
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
			[(NSButton *)[quitWindow initialFirstResponder] setState:NSOnState];
			[[(NSButton *)[quitWindow initialFirstResponder] alternateImage] setSize:QSSize128];
			[[(NSButton *)[quitWindow initialFirstResponder] alternateImage] setFlipped:NO];
			[quitWindow display];
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
	[[QSTaskViewer sharedInstance] showWindow:self];
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
		[anItem setTitle:([[NSUserDefaults standardUserDefaults] boolForKey:kDelayQuit] ?@"Quit Quicksilver...":@"Quit Quicksilver")];
		return YES;
	}
	return YES;
}

- (NSProgressIndicator *)progressIndicator { return [interfaceController progressIndicator];  }

- (void)displayStatusMenuAtPoint:(NSPoint)point { [NSMenu popUpContextMenu:[NSApp mainMenu] withEvent:[NSEvent mouseEventWithType:NSLeftMouseDown location:NSMakePoint(500, 500) modifierFlags:0 timestamp:0 windowNumber:0 context:nil eventNumber:0 clickCount:1 pressure:0] forView:nil withFont:nil];  }

- (NSMenu *)statusMenuWithQuit {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	if ([defaults boolForKey:@"QSUseFullMenuStatusItem"])
		return [NSApp mainMenu];

	NSMenu *newMenu = [[statusMenu copy] autorelease];

	NSMenuItem *modulesItem = [[NSApp mainMenu] itemWithTag:128];
	[newMenu addItem:[[modulesItem copy] autorelease]];

	[newMenu addItem:[NSMenuItem separatorItem]];
	NSMenuItem *quitItem = [[[NSMenuItem alloc] initWithTitle:@"Quit Quicksilver" action:@selector(terminate:) keyEquivalent:@""] autorelease];
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
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSImage *splashImage = [NSImage imageNamed:@"QSLigature"];
 {
		splashWindow = [NSWindow windowWithImage:splashImage];
#if 0
//		if ([NSApp isPrerelease]) {
			NSRect rect = NSInsetRect(NSMakeRect(28, 108, 88, 24), 1, 1);
			NSBezierPath *path = [NSBezierPath bezierPath];
			[path appendBezierPathWithRoundedRectangle:rect withRadius:12];
			[[NSColor colorWithCalibratedRed:0.0 green:0.33 blue:0.0 alpha:0.8] set];
			[path fill];
			[[splashWindow contentView] lockFocus];
			NSAttributedString *string = [[[NSAttributedString alloc] initWithString:@"Unofficial" attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:12] , NSFontAttributeName, [NSColor whiteColor] , NSForegroundColorAttributeName, nil]] autorelease];
			[string drawWithRect:NSOffsetRect(centerRectInRect(rectFromSize([string size]), rect), 0, 4) options:NSStringDrawingOneShot];
			[path addClip];
			[QSGlossClipPathForRectAndStyle(rect, 4) addClip];
			[[NSColor colorWithCalibratedWhite:1.0 alpha:0.1] set];
			NSRectFillUsingOperation(rect, NSCompositeSourceOver);

			[[splashWindow contentView] unlockFocus];
//		}
#endif
 }

	[splashWindow reallyCenter];
	[splashWindow setAlphaValue:0];
	[splashWindow setSticky:YES];

	if ([NSApp wasLaunchedAtLogin]) {
		[splashWindow setLevel:NSNormalWindowLevel-1];
		[splashWindow orderFront:self];
		[splashWindow setAlphaValue:0.25 fadeTime:0.333];
	} else {
		[splashWindow orderFront:self];
		QSWindowAnimation *animation = [QSWindowAnimation showHelperForWindow:splashWindow];
		[animation setTransformFt:QSExtraExtraEffect];
		[animation setDuration:1.0];
		[animation setAnimationBlockingMode:NSAnimationBlocking];
		[animation startAnimation];
	}
	[pool release];
}
- (void)hideSplash:sender {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (splashWindow) {
		[splashWindow setLevel:NSFloatingWindowLevel];
		[splashWindow flare:self];
		[splashWindow close];
		splashWindow = nil;
	}
	[pool release];
}
- (void)startDropletConnection {
	if (dropletConnection) return;
	dropletConnection = [NSConnection defaultConnection];
	[dropletConnection registerName:@"Quicksilver Droplet"];
	[dropletConnection setRootObject:self];
}

- (void)handlePasteboardDrop:(NSPasteboard *)pb commandPath:(NSString *)path {
	QSObject *drop = [QSObject objectWithPasteboard:pb];
	NSLog(@"got droplet item");
	[self setDropletProxy:drop];
	[self executeCommandAtPath:path];
	[self setDropletProxy:nil];
}

- (void)executeCommandAtPath:(NSString *)path { [[QSCommand commandWithFile:path] execute];  }
- (void)performService:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error {
	if (VERBOSE) NSLog(@"Perform Service: %@ %d", userData, [userData characterAtIndex:0]);
	[self receiveObject:[[[QSObject alloc] initWithPasteboard:pboard] autorelease]];
}
- (void)getSelection:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error {
	if (VERBOSE) NSLog(@"GetSel Service: %@ %d", userData, [userData characterAtIndex:0]);
	[self receiveObject:[[[QSObject alloc] initWithPasteboard:pboard] autorelease]];
}

- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard {
	[self receiveObject:[[[QSObject alloc] initWithPasteboard:pboard] autorelease]];
	return YES;
}

- (void)receiveObject:(QSObject *)object {
	[[self interfaceController] selectObject:object];
	[self activateInterface:self];
}

- (NSObject *)dropletProxy { return dropletProxy;  }
- (void)setDropletProxy:(NSObject *)newDropletProxy {
	if (dropletProxy != newDropletProxy) {
		[dropletProxy release];
		dropletProxy = [newDropletProxy retain];
	}
}

- (void)dealloc {
	[interfaceController release];
	[aboutWindowController release];
	[quitWindowController release];
	[splashWindow release];
	[statusItem release];
	[controllerConnection release];
	[dropletConnection release];
	[dropletProxy release];
	[super dealloc];
}

- (id)resolveProxyObject:(id)proxy {
	if ([[proxy identifier] isEqualToString:@"QSDropletItemProxy"]) {
		return dropletProxy;
	} else {
		QSObject *object = [[[self interfaceController] dSelector] objectValue];
		if ([object isKindOfClass:[QSProxyObject class]] || [object isEqual:proxy])
			return nil;
		return object;
	}
	return nil;
}

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key {
	if ([key isEqual:@"AESelection"])
		return YES;
	return NO;
}

- (id)selection { return [NSAppleEventDescriptor descriptorWithString:@"string"];  }

- (void)setAESelection:(NSAppleEventDescriptor *)desc types:(NSArray *)types {
	QSObject *object = nil;
	if ([desc isKindOfClass:[NSString class]])
		object = [QSObject objectWithString:(NSString *)desc];
	else if ([desc isKindOfClass:[NSArray class]])
		object = [QSObject fileObjectWithArray:(NSArray *)desc];
	else if (fDEV) {
		NSLog(@"descriptor %@ %@", NSStringFromClass([desc class]), desc);
		object = [QSObject objectWithAEDescriptor:desc types:(NSArray *)types];
	}
	NSLog(@"object %@", object);
	[self receiveObject:object];
}
- (void)setAESelection:(NSAppleEventDescriptor *)desc {
	[self setAESelection:desc types:nil];
}
- (NSAppleEventDescriptor *)AESelection {
	QSObject *selection = (QSObject*)[[self interfaceController] selection];
	NSLog(@"object %@", selection);
	id desc = [selection AEDescriptor];
	if (!desc)
		desc = [NSAppleEventDescriptor descriptorWithString:[selection stringValue]];
	return desc;
}

//Notifications

- (void)appLaunched:(NSNotification*)notif {
	NSString *launchedApp = [[notif userInfo] objectForKey:@"NSApplicationName"];
	if ([launchedApp isEqualToString:@"Dock0"])
		NSLog(@"%@ Launching ", launchedApp);
}

- (void)appChanged:(NSNotification *)aNotification {
	NSString *currentApp = [[[NSWorkspace sharedWorkspace] activeApplication] objectForKey:@"NSApplicationName"];
	if (![currentApp isEqualToString:@"Quicksilver"])
		[[NSNotificationCenter defaultCenter] postNotificationName:@"WindowsShouldHide" object:self];
}

- (IBAction)rescanItems:sender { [[QSLibrarian sharedInstance] startThreadedScan];  }
- (IBAction)forceRescanItems:sender { [[QSLibrarian sharedInstance] startThreadedAndForcedScan];  }

- (void)delayedStartup {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (DEBUG_STARTUP) NSLog(@"Delayed Startup");
	[NSThread setThreadPriority:0.0];
	QSTask *task = [QSTask taskWithIdentifier:@"QSDelayedStartup"];
	[task setStatus:@"Updating Catalog"];
	[task startTask:self];
	[QSLib loadMissingIndexes];
	[task stopTask:self];
	[pool release];
}

- (NSString *)internetDownloadLocation { return [[[NDAlias aliasWithData:[[[[(NSDictionary *)CFPreferencesCopyValue((CFStringRef) @"Version 2.5.4", (CFStringRef) @"com.apple.internetconfig", kCFPreferencesCurrentUser, kCFPreferencesAnyHost) autorelease] objectForKey:@"ic-added"] objectForKey:@"DownloadFolder"] objectForKey:@"ic-data"]] path] stringByStandardizingPath];  }

- (void)checkForFirstRun {
	int status = [NSApp checkLaunchStatus];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *lastLocation = [defaults objectForKey:kLastUsedLocation];
	NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
	NSString *lastVersionString = [defaults objectForKey:kLastUsedVersion];
	int lastVersion = [lastVersionString respondsToSelector:@selector(hexIntValue)] ? [lastVersionString hexIntValue] : 0;
	switch (status) {
		case QSApplicationUpgradedLaunch:
			if (fBETA && lastLocation && ![bundlePath isEqualToString:[lastLocation stringByStandardizingPath]]) {
				//New version in new location.
				[NSApp activateIgnoringOtherApps:YES];
				int selection = NSRunAlertPanel(@"Running from a new location", @"The previous version of Quicksilver was located in \"%@\". Would you like to move this new version to that location?", @"Move and Relaunch", @"Don't Move", nil, [[lastLocation stringByDeletingLastPathComponent] lastPathComponent]);
				if (selection)
					[NSApp relaunchAtPath:lastLocation movedFromPath:bundlePath];
			}
			if ([defaults boolForKey:kShowReleaseNotesOnUpgrade] && (!DEBUG) ) {
				[NSApp activateIgnoringOtherApps:YES];
				int selection = NSRunInformationalAlertPanel([NSString stringWithFormat:@"Quicksilver has been updated", nil] , @"You are using a new version of Quicksilver. Would you like to see the Release Notes?", @"Show Release Notes", @"Ignore", nil);
				if (selection == 1)
					[self showReleaseNotes:self];
			}
			[[NSWorkspace sharedWorkspace] setComment:@"Quicksilver" forFile:[[NSBundle mainBundle] bundlePath]];
			if (lastVersion < [@"2000" hexIntValue]) {
				NSFileManager *fm = [NSFileManager defaultManager];
				[fm movePath:QSApplicationSupportSubPath(@"PlugIns", NO) toPath:QSApplicationSupportSubPath(@"PlugIns (B40 Incompatible) ", NO) handler:nil];
				[fm movePath:@"/Library/Application Support/Quicksilver/PlugIns" toPath:@"/Library/Application Support/Quicksilver/PlugIns (B40 Incompatible) " handler:nil];
			}
				newVersion = YES;
			break;
		case QSApplicationDowngradedLaunch:
			[NSApp activateIgnoringOtherApps:YES];
			int selection = NSRunInformationalAlertPanel([NSString stringWithFormat:@"This is an old version of Quicksilver", nil] , @"You have previously used a newer version. Perhaps you have duplicate copies?", @"Reveal this copy", @"Ignore", nil);
			if (selection == 1)
				[[NSWorkspace sharedWorkspace] selectFile:[[NSBundle mainBundle] bundlePath] inFileViewerRootedAtPath:@""];
				break;
		case QSApplicationFirstLaunch: {
			NSString *containerPath = [[bundlePath stringByDeletingLastPathComponent] stringByStandardizingPath];
			BOOL shouldInstall = [containerPath isEqualToString:@"/Volumes/Quicksilver"] || [containerPath isEqualToString:[self internetDownloadLocation]];
			if (shouldInstall) {
				//New version in new location.
				[NSApp activateIgnoringOtherApps:YES];
				int selection = NSRunAlertPanel(@"Would you like to install Quicksilver?", @"Quicksilver was launched from a download location.\rWould you like to copy Quicksilver to your applications folder?", @"Install in \"Applications\"", @"Quit", @"Choose Location...");
				NSString *installPath = nil;
				if (selection == 1) {
					installPath = @"/Applications";
				} else if (selection == -1) {
					NSOpenPanel *openPanel = [NSOpenPanel openPanel];
					[openPanel setCanChooseDirectories:YES];
					[openPanel setCanChooseFiles:NO];
					[openPanel setPrompt:@"Install Here"];
					[openPanel setTitle:@"Install Quicksilver"];
					if (NSFileHandlingPanelOKButton == [openPanel runModalForDirectory:[NSHomeDirectory() stringByAppendingPathComponent:@"Applications"] file:nil]) {
						installPath = [openPanel filename];
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
	if (![defaults boolForKey:kSetupAssistantCompleted] || lastVersion <= [@"3694" hexIntValue] || ![defaults boolForKey:@"QSAgreementAccepted"])
		runningSetupAssistant = YES;
	[NSApp updateLaunchStatusInfo];
}

- (IBAction)showReleaseNotes:(id)sender { [[NSWorkspace sharedWorkspace] openFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/SharedSupport/Changes.html"]];  }

- (QSInterfaceController *)interfaceController { return [QSReg preferredCommandInterface];  }

- (void)setInterfaceController:(QSInterfaceController *)newInterfaceController {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	if (interfaceController)
		[nc postNotificationName:QSReleaseAllCachesNotification object:self];
	[interfaceController release];
	interfaceController = [newInterfaceController retain];
	[nc postNotificationName:QSInterfaceChangedNotification object:self];
}

- (id <QSFSBrowserMediator>) finderProxy { return [QSReg FSBrowserMediator];  }

@end

@implementation QSController (Application)

//- (void)applicationDidResignActive:(NSNotification *)aNotification {}

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender {
#if 0
	[[NSImage imageNamed:@"NSApplicationIcon"] setSize:NSMakeSize(128, 128)];
	[NSApp setApplicationIconImage:[NSImage imageNamed:@"NSApplicationIcon"]];
#endif
	[[NSNotificationCenter defaultCenter] postNotificationName:@"QSEventNotification" object:@"QSQuicksilverWillQuitEvent" userInfo:nil];
	return YES;
}

- (void)writeLeaksToFileAtPath:(NSString*)path {
    NSFileHandle * output = [NSFileHandle fileHandleForWritingAtPath:path];
    if(output == nil)
        output = [NSFileHandle fileHandleWithStandardError];
    NSTask * leaksTask = [NSTask taskWithLaunchPath:@"/usr/bin/leaks"
                                          arguments:[NSArray arrayWithObjects:
                                                     [NSString stringWithFormat:@"%d", getpid()],
                                                     nil]];
    [leaksTask setStandardOutput:output];
    [leaksTask setStandardError:output];
    NSLog( @"Writing leaks to %@", ( path != nil ? path : @"stderr" ) );
    [leaksTask launch];
    [leaksTask waitUntilExit];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"WindowsShouldHide" object:self];
	[[NSUserDefaults standardUserDefaults] synchronize];
    if (DEBUG_MEMORY) [self writeLeaksToFileAtPath:QSApplicationSupportSubPath(@"QSLeaks.plist", NO)];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
	if (DEBUG) {
		[self registerForErrors];
	}
}

- (void)setupSplash {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kUseEffects]) {
		[self showSplash:nil];
		[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(threadedHideSplash) userInfo:nil repeats:NO];
	}
}
- (void)startQuicksilver:(id)sender {
	[self checkForFirstRun];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSString *equiv = [defaults objectForKey:@"QSServiceMenuKeyEquivalent"];
	//NSLog(@"Setting service %@", equiv);
	if (equiv && ![equiv isEqualToString:[NSApp keyEquivalentForService:@"Quicksilver/Send to Quicksilver"]]) {
		NSLog(@"Setting Service Key Equivalent to %@", equiv);
		[NSApp setKeyEquivalent:equiv forService:@"Quicksilver/Send to Quicksilver"];
	}

	// Show Splash Screen
	BOOL atLogin = [NSApp wasLaunchedAtLogin];
	if (!atLogin)
		[self setupSplash];

	if (DEBUG_STARTUP)
		NSLog(@"Instantiate Classes");

	[QSRegistry sharedInstance];

	if (DEBUG_STARTUP)
		NSLog(@"Registry loaded");

	[QSMnemonics sharedInstance];
	[QSLibrarian sharedInstance];
	[QSExecutor sharedInstance];
	[QSTaskController sharedInstance];

	if (DEBUG_STARTUP)
		NSLog(@"Library loaded");

	[[QSPlugInManager sharedInstance] loadPlugInsAtLaunch];
	if (DEBUG_STARTUP)
		NSLog(@"PlugIns loaded");

	[QSLib initCatalog];

	[QSLib pruneInvalidChildren:nil];
	[QSLib loadCatalogInfo];

	[QSExec loadFileActions];

	[QSLib reloadIDDictionary:nil];
	[QSLib enableEntries];

	if (DEBUG_STARTUP)
		NSLog(@"Catalog loaded");

	[QSObject purgeIdentifiers];

	if (newVersion && (!DEBUG) ) {
		if (!runningSetupAssistant) {
			NSLog(@"New Version: Purging all Identifiers and Forcing Rescan");
			[QSLibrarian removeIndexes];
			[QSLib startThreadedAndForcedScan];
		}
	} else {
		[QSLib loadCatalogArrays];
	}

	[QSLib reloadEntrySources:nil];

	if (atLogin)
		[self setupSplash];

	[NSApp setServicesProvider:self];

	// Setup Activation Hotkey

	if ([defaults integerForKey:@"QSModifierActivationCount"] >0) {
		QSModifierKeyEvent *modActivation = [[[QSModifierKeyEvent alloc] init] autorelease];
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
		int modifiers = [oldModifiers unsignedIntValue];
		if (modifiers < (1 << (rightControlKeyBit+1) )) {
			NSLog(@"updating hotkey %d", modifiers);
			[defaults setValue:[NSNumber numberWithInt:carbonModifierFlagsToCocoaModifierFlags(modifiers)] forKey:kHotKeyModifiers];
			[defaults synchronize];
		}

		NSLog(@"Updating Activation Key");
		[defaults removeObjectForKey:kHotKeyModifiers];
		[defaults removeObjectForKey:kHotKeyCode];
		[defaults setObject:[NSDictionary dictionaryWithObjectsAndKeys:oldModifiers, @"modifiers", oldKeyCode, @"keyCode", nil] forKey:@"QSActivationHotKey"];
		[defaults synchronize];
	}

	[self bind:@"activationHotKey" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.QSActivationHotKey" options:nil];

	quitWindowController = nil;

	int rescanInterval = [defaults integerForKey:@"QSCatalogRescanFrequency"];

	if (rescanInterval>0) {
		if (DEBUG_STARTUP) NSLog(@"Rescanning every %d minutes", rescanInterval);
		[[NSTimer scheduledTimerWithTimeInterval:rescanInterval*60 target:self selector:@selector(rescanItems:) userInfo:nil repeats:YES] retain];
	}

	if (DEBUG_STARTUP) NSLog(@"Register for Notifications");
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	[[ws notificationCenter] addObserver:self selector:@selector(appLaunched:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
	[[ws notificationCenter] addObserver:self selector:@selector(appWillLaunch:) name:NSWorkspaceWillLaunchApplicationNotification object:nil];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(appChanged:) name:@"com.apple.HIToolbox.menuBarShownNotification" object:nil];

	[[[NSApp mainMenu] itemAtIndex:0] setTitle:@"Quicksilver"];

	if (DEBUG_STARTUP) NSLog(@"Will Finish Launching");

	if (DEBUG || PRERELEASEVERSION)
		[self activateDebugMenu];

	if (runningSetupAssistant) {
		[self hideSplash:nil];
		[self runSetupAssistant:nil];
	}
	char *visiblePref = getenv("QSVisiblePrefPane");
	if (visiblePref)
		[QSPreferencesController showPaneWithIdentifier:[NSString stringWithUTF8String:visiblePref]];

	[QSResourceManager sharedInstance];
	[[QSTriggerCenter sharedInstance] activateTriggers];

	if (DEBUG_STARTUP) NSLog(@"Did Finish Launching\n ");

	[self bind:@"showMenuIcon" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.QSShowMenuIcon" options:nil];

	if ([defaults boolForKey:kAutomaticTaskViewer])
		[QSTaskViewer sharedInstance];

	if ( ! (runningSetupAssistant || newVersion) )
		[self rescanItems:self];

	if (newVersion && !DEBUG)
		[[QSUpdateController sharedInstance] forceStartupCheck];

	[[QSUpdateController sharedInstance] setUpdateTimer];

#if 0
	[self recompositeIconImages];
#endif

	[[self interfaceController] window];

	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

	if (atLogin)
		[nc postNotificationName:@"QSEventNotification" object:@"QSQuicksilverLaunchedAtLoginEvent" userInfo:nil];

	[nc postNotificationName:@"QSEventNotification" object:@"QSQuicksilverLaunchedEvent" userInfo:nil];

	if ([defaults boolForKey:@"QSEnableISync"])
		[[QSSyncManager sharedInstance] setup];

	[NSThread detachNewThreadSelector:@selector(delayedStartup) toTarget:self withObject:nil];
	[self startDropletConnection];
}

- (id)activationHotKey { return nil;  }
- (void)setActivationHotKey:(id)object {
	[[QSHotKeyEvent hotKeyWithIdentifier:kActivationHotKey] setEnabled:NO];

	QSHotKeyEvent *activationKey = (QSHotKeyEvent *)[QSHotKeyEvent hotKeyWithDictionary:object];
	[activationKey setTarget:self selectorReleased:(SEL) 0 selectorPressed:@selector(activateInterface:)];
	[activationKey setIdentifier:kActivationHotKey];
	[activationKey setEnabled:YES];
}

- (void)threadedHideSplash {
	[NSThread detachNewThreadSelector:@selector(hideSplash:) toTarget:self withObject:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification { [self startQuicksilver:aNotification];  }

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
	} else if ([(plugIns = [fileList pathsMatchingExtensions:[NSArray arrayWithObject:@"qscatalogentry"]]) count]) {
		foreach(path, plugIns)
			[QSCatalogPrefPane addEntryForCatFile:path];
	} else if ([(plugIns = [fileList pathsMatchingExtensions:[NSArray arrayWithObject:@"qscommand"]]) count]) {
		foreach(path, plugIns)
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
	NSLog(@"Print %@ using %@ show %d", fileNames, printSettings, showPrintPanels) 	;
	return NSPrintingFailure;
}

@end

void QSSignalHandler(int i) {
	printf("signal %d", i);
	NSLog(@"Current Tasks %@", [[QSTaskController sharedInstance] tasks]);
	[NSApp activateIgnoringOtherApps:YES];
	int result = NSRunCriticalAlertPanel(@"An error has occured", @"Quicksilver must be relaunched to regain stability.", @"Relaunch", @"Quit", nil, i);
	NSLog(@"result %d", result);
	if (result == 1)
		[NSApp relaunch:nil];
	exit(-1);
}

@implementation QSController (ErrorHandling)
- (void)registerForErrors {
	signal(SIGBUS, QSSignalHandler);
	signal(SIGSEGV, QSSignalHandler);

	if (fDEV) {
		NSExceptionHandler *handler = [NSExceptionHandler defaultExceptionHandler];
		[handler setExceptionHandlingMask:NSLogAndHandleEveryExceptionMask];
		[handler setDelegate:self];
	}
}

- (BOOL)exceptionHandler:(NSExceptionHandler *)sender shouldLogException:(NSException *)exception mask:(unsigned int)aMask {
	[exception printStackTrace];
	return NO;
} // mask is NSLog<exception type>Mask, exception's userInfo has stack trace for key NSStackTraceKey

- (BOOL)exceptionHandler:(NSExceptionHandler *)sender shouldHandleException:(NSException *)exception mask:(unsigned int)aMask {

	return YES;
}

@end