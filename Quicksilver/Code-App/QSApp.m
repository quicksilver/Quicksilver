#import "QSPreferenceKeys.h"
#import "QSApp.h"
#import "QSController.h"
#import "QSModifierKeyEvents.h"
#import "QSInterfaceController.h"
#import "NSApplication_BLTRExtensions.h"
#import <unistd.h>

#import "QSProcessMonitor.h"
#import "NSEvent+BLTRExtensions.h"

BOOL QSApplicationCompletedLaunch = NO;

@interface NSObject (QSAppDelegateProtocols)
- (BOOL)shouldSendEvent:(NSEvent *)event;
- (void)handleMouseTriggerEvent:(NSEvent *)event type:(id)type forView:(NSView *)view;
@end
@interface NSApplication (NSPrivate)
- (BOOL)_handleKeyEquivalent:(NSEvent *)event;
- (void)_sendFinishLaunchingNotification;
@end

@implementation QSApp
+(void)load {
#ifdef DEBUG
	 if(mOptionKeyIsDown) {
		NSLog(@"Setting Verbose");
		setenv("verbose", "1", YES);
		setenv("QSDebugPlugIns", "1", YES);
		setenv("QSDebugStartup", "1", YES);
		setenv("QSDebugCatalog", "1", YES);
	}
#endif
}

+ (void)initialize {
    static BOOL done = NO;
    if(!done) {
		
#ifdef DEBUG
        if (DEBUG_STARTUP) NSLog(@"App Initialize");
#endif
		
        [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/QSDefaults.plist"]]];
        done = YES;
    }
}

- (id)init {
	char *relaunchingFromPid = getenv("relaunchFromPid");
	if (relaunchingFromPid) {
		unsetenv("relaunchFromPid");
		int pid = atoi(relaunchingFromPid);
		int i;
		for (i = 0; !kill(pid, 0) && i<50; i++) usleep(100000);
	}
	if ((self = [super init])) {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
	// Honor dock hidden preference if new version
	isUIElement = [self shouldBeUIElement];
	if (!isUIElement && [defaults boolForKey:kHideDockIcon]) {
		if (![defaults objectForKey:@"QSShowMenuIcon"])
			[defaults setInteger:1 forKey:@"QSShowMenuIcon"];

	  NSLog(@"Relaunching to honor Dock Icon Preference");
		if ([self setShouldBeUIElement:YES]) {
#ifndef DEBUG
			[self relaunch:nil];
#endif
		} else {
			[defaults setBool:NO forKey:kHideDockIcon];
		}
	}
	}
	return self;
}

#if 0
- (void)finishLaunching { [super finishLaunching];  }
#endif

- (void)_sendFinishLaunchingNotification {
	[super _sendFinishLaunchingNotification];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"QSApplicationDidFinishLaunchingNotification" object:self];
	QSApplicationCompletedLaunch = YES;
}

- (BOOL)completedLaunch { return QSApplicationCompletedLaunch;  }

- (void)setApplicationIconImage:(NSImage *)image {
  if (!isUIElement)
	[super setApplicationIconImage:image];
}

- (BOOL)_handleKeyEquivalent:(NSEvent *)event {
	if ([[self globalKeyEquivalentTarget] performKeyEquivalent:event])
		return YES;
	else if ([hiddenMenu performKeyEquivalent:event])
		return YES;
	else
		return [super _handleKeyEquivalent:event];
}

- (void)sendEvent:(NSEvent *)theEvent {
	if (eventDelegates) {
		for(id eDelegate in eventDelegates) {
			if ([eDelegate respondsToSelector:@selector(shouldSendEvent:)] && ![eDelegate shouldSendEvent:theEvent])
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
			if ([theEvent standardModifierFlags] > 0)
				[[NSClassFromString(@"QSMouseTriggerManager") sharedInstance] handleMouseTriggerEvent:theEvent type:nil forView:nil];
		  break;
	  case NSOtherMouseDown:
			[theEvent retain];
#ifdef DEBUG
			if (VERBOSE)
				NSLog(@"OtherMouse %@ %@", theEvent, [theEvent window]);
#endif
			[[NSClassFromString(@"QSMouseTriggerManager") sharedInstance] handleMouseTriggerEvent:theEvent type:nil forView:nil];
			break;
	  case NSScrollWheel: {
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
	NSWindow *clickWindow = nil;
	for (NSWindow *thisWindow in [self windows])
		if ([thisWindow isVisible] && [thisWindow level] > [clickWindow level] && [thisWindow styleMask] & NSNonactivatingPanelMask && ![thisWindow ignoresMouseEvents] && NSPointInRect([theEvent locationInWindow] , NSInsetRect([thisWindow frame] , 0, -1) )) //These points are offset by one for some silly reason
			clickWindow = thisWindow;
	if (clickWindow) {
		theEvent = [NSEvent mouseEventWithType:[theEvent type] location:[clickWindow convertScreenToBase:[theEvent locationInWindow]] modifierFlags:[theEvent modifierFlags] timestamp:[theEvent timestamp] windowNumber:[clickWindow windowNumber] context:[theEvent context] eventNumber:[theEvent eventNumber] clickCount:[theEvent clickCount] pressure:[theEvent pressure]];
		[self sendEvent:theEvent];
	}
#if 0
	else {
		//NSLog(@"Unable to forward");
	}
#endif
}

- (BOOL)isUIElement { return isUIElement;  }
- (BOOL)setShouldBeUIElement:(BOOL)hidden {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:hidden forKey:kHideDockIcon];
	[defaults synchronize];
	if (!hidden) {
		ProcessSerialNumber psn = { 0, kCurrentProcess } ;
		TransformProcessType(&psn, kProcessTransformToForegroundApplication);
	}
	return [super setShouldBeUIElement:hidden];
}

- (NSResponder *)globalKeyEquivalentTarget { return globalKeyEquivalentTarget;  }
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
