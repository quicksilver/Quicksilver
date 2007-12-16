
#import <QSCrucible/NSEvent+BLTRExtensions.h>
#import <QSCrucible/QSProcessMonitor.h>

#import "QSController.h"

#import "QSModifierKeyEvents.h"

#import "QSApp.h"

BOOL QSApplicationCompletedLaunch = NO;
@interface NSObject (QSAppDelegateProtocols)
- (BOOL)shouldSendEvent:(NSEvent *)event;
- (void)handleMouseTriggerEvent:(NSEvent *)event type:(id)type forView:(NSView *)view;
@end 
@interface NSApplication (NSPrivate)
- (BOOL)_handleKeyEquivalent:(NSEvent *)event;
- (void)_sendFinishLaunchingNotification;
@end

//#import "QSToolbarView.h"
@implementation QSApp 
- (void)handleCreateCommand:(id)command {
	QSLog(@"create %@", command); 	
}
+(void)load {
	
    if (DEBUG)
        setenv("verbose", "1", YES);
    else if (mOptionKeyIsDown) {
        QSLog(@"Setting Verbose");
        setenv("QSDebugPlugIns", "1", YES);
        setenv("QSDebugStartup", "1", YES);
        setenv("QSDebugCatalog", "1", YES);
    } else {
		unsetenv("verbose");
	}
	
}


+ (void)initialize {
    if (DEBUG_STARTUP) QSLog(@"App Initialize");
  [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"QSDefaults" ofType:@"plist"]]];
}



- (id)init {
	char *relaunchingFromPid = getenv("relaunchFromPid"); 	
	if (relaunchingFromPid) {
		unsetenv("relaunchFromPid");
		int pid = atoi(relaunchingFromPid);
		int i;
		for (i = 0; !kill(pid, 0) && i < 50; i++) usleep(100000);
	}
	
	
    if ((self = [super init])) {
		
		
		// Prevent Pre-Tiger Systems
		
		//QSLog([self versionString]);
		SInt32 version;
		Gestalt (gestaltSystemVersion, & version);
		if (version < 0x1040) {
			//int selection=
			NSRunAlertPanel([[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"] stringByAppendingString:@" requires Mac OS 10.4"] , @"Recent versions of Quicksilver require Mac OS 10.4 Tiger. An older, 10.3 compatible version is available from the website.", @"OK", nil, nil, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]);
			[self terminate:self];
		}
        
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        // Honor dock hidden preference if new version
        isUIElement = [self shouldBeUIElement];
        if (!isUIElement && [defaults boolForKey:kHideDockIcon]) {
			
			if (![defaults objectForKey:@"QSShowMenuIcon"])
				[defaults setInteger:1 forKey:@"QSShowMenuIcon"];
			
            QSLog(@"Relaunching to honor Dock Icon Preference");
            //  if (NSRunAlertPanel(@"Hide Dock Icon?", @"A previous version of Quicksilver had its dock icon hidden. Relaunch and hide it again?", @"Hide Icon", @"Show Icon", nil) ) {
            if ([self setShouldBeUIElement:YES])
                [self relaunch:nil];
            else
                [defaults setBool:NO forKey:kHideDockIcon];
            }
        if (isUIElement) {
            ProcessSerialNumber psn = { 0, kCurrentProcess } ;
            TransformProcessType( & psn, kProcessTransformToForegroundApplication);
        }
        //Set Feature level
        featureLevel = [defaults integerForKey:kFeatureLevel];
		if (featureLevel < 0) featureLevel = 0;
		if (featureLevel > 0) featureLevel = 2;
		// if (!featureLevel && DEVELOPMENTVERSION)
		//     featureLevel = 1;
        if (featureLevel > 2 && !([defaults boolForKey:kCuttingEdgeFeatures]) )
            featureLevel = 2;
		//if (featureLevel == 1)
		//	featureLevel == 2;
		
		
		}
    return self;
	}

- (void)finishLaunching {
	[super finishLaunching];
}

- (void)_sendFinishLaunchingNotification {
	[super _sendFinishLaunchingNotification];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"QSApplicationDidFinishLaunchingNotification" object:self];
	QSApplicationCompletedLaunch = YES;
}


- (BOOL)completedLaunch {
	return QSApplicationCompletedLaunch;
}

- (void)setApplicationIconImage:(NSImage *)image {
    if (!isUIElement)
        [super setApplicationIconImage:image];
}

- (int) featureLevel {return featureLevel;}

- (BOOL)betaLevel {return featureLevel > 0;}
- (BOOL)alphaLevel {return featureLevel > 1;}
- (BOOL)devLevel {return featureLevel > 2;}

- (BOOL)isTiger {
	SInt32 version;
	Gestalt (gestaltSystemVersion, & version);
	return (version >= 0x1040);
}

//- (void)setApplicationIconImage:(NSImage *)image {
// QSLog(@"AppImage: %@", image);
//    [super setApplicationIconImage: image];
//}


- (BOOL)_handleKeyEquivalent:(NSEvent *)event {
	if ([[self globalKeyEquivalentTarget] performKeyEquivalent:event])
		return YES;
	
	//QSLog(@"global %@", [self globalKeyEquivalentTarget] );
	if ([hiddenMenu performKeyEquivalent:event]) return YES;
	return [super _handleKeyEquivalent:event];
}

- (void)sendEvent:(NSEvent *)theEvent {
	//	QSLog(@"event %@", theEvent);
	if (eventDelegates) {
		foreach(eDelegate, eventDelegates) {
			if ([eDelegate respondsToSelector:@selector(shouldSendEvent:)] 
				 && ![eDelegate shouldSendEvent:theEvent])
				return;
		}
	} 	
	switch ((int) [theEvent type]) {
		case NSProcessNotificationEvent:
			[[QSProcessMonitor sharedInstance] handleProcessEvent:theEvent];
			break;
		case NSRightMouseDown:
			
			if (![theEvent windowNumber]) { // Workaround for ignored right clicks on non activating panels
				[self forwardWindowlessRightClick:theEvent];
				return;
			} else if ([theEvent standardModifierFlags] > 0) {
					[[NSClassFromString(@"QSMouseTriggerManager") sharedInstance] handleMouseTriggerEvent:theEvent type:nil forView:nil];
			}
			break;
		case NSLeftMouseDown:
		
			if ([theEvent standardModifierFlags] > 0) {
				[[NSClassFromString(@"QSMouseTriggerManager") sharedInstance] handleMouseTriggerEvent:theEvent type:nil forView:nil];
			}
				break;
		case NSOtherMouseDown:
			//if (![theEvent window]) {
			[theEvent retain];
			if (VERBOSE) 	
				QSLog(@"OtherMouse %@ %@", theEvent, [theEvent window]);
			[[NSClassFromString(@"QSMouseTriggerManager") sharedInstance] handleMouseTriggerEvent:theEvent type:nil forView:nil];
			//}
			break;
		case NSScrollWheel:
		 {
			NSWindow *interfaceWindow = [[(QSController *)[self delegate] interfaceController] window];
			if ([self keyWindow] == interfaceWindow)
				[[interfaceWindow firstResponder] scrollWheel:theEvent];
		}
			break;
		case NSFlagsChanged:
			[QSModifierKeyEvent checkForModifierEvent:theEvent];
			break;
	}
	[super sendEvent:theEvent];
}
- (void)forwardWindowlessRightClick:(NSEvent *)theEvent {	
	NSEnumerator *windowEnumerator = [[self windows] objectEnumerator];
	NSWindow *thisWindow;
	NSWindow *clickWindow = nil;
	while ((thisWindow = [windowEnumerator nextObject]))
		if ([thisWindow isVisible]
			 && [thisWindow level] > [clickWindow level] 
			 && [thisWindow styleMask] & NSNonactivatingPanelMask
			 && ![thisWindow ignoresMouseEvents] 
			 && NSPointInRect([theEvent locationInWindow] , NSInsetRect([thisWindow frame] , 0, -1) )) //These points are offset by one for some silly reason
			clickWindow = thisWindow;
	if (clickWindow) {
		theEvent = [NSEvent mouseEventWithType:[theEvent type] location:[clickWindow convertScreenToBase:[theEvent locationInWindow]] modifierFlags:[theEvent modifierFlags] timestamp:[theEvent timestamp] windowNumber:[clickWindow windowNumber] context:[theEvent context] eventNumber:[theEvent eventNumber] clickCount:[theEvent clickCount] pressure:[theEvent pressure]];
		[self sendEvent:theEvent];
	} else {
		//QSLog(@"Unable to forward");  
	} 	
}

- (BOOL)isUIElement {
    return isUIElement;
}
- (BOOL)setShouldBeUIElement:(BOOL)hidden {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:hidden forKey:kHideDockIcon];
	[defaults synchronize];
	return [super setShouldBeUIElement:hidden];
}



- (NSResponder *)globalKeyEquivalentTarget {
    return [[globalKeyEquivalentTarget retain] autorelease];
}

- (void)setGlobalKeyEquivalentTarget:(NSResponder *)value {
    if (globalKeyEquivalentTarget != value) {
        [globalKeyEquivalentTarget release];
        globalKeyEquivalentTarget = [value retain];
    }
}

- (void)addEventDelegate:(id)eDelegate {
	if (!eventDelegates)
		eventDelegates = [[NSMutableArray alloc] init];
	[eventDelegates addObject:eDelegate];
}

- (void)removeEventDelegate:(id)eDelegate {
	[eventDelegates removeObject:eDelegate];
	if (![eventDelegates count]) {
		[eventDelegates release];
		eventDelegates = nil;
	}
}

- (BOOL)isPrerelease {
	int releaseLevel = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"QSReleaseStatus"] intValue];
	return releaseLevel > 0;
}

@end
