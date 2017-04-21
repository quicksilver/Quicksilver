#import "QSPreferenceKeys.h"
#import "QSApp.h"
#import "QSController.h"
#import "QSModifierKeyEvents.h"
#import "QSInterfaceController.h"
#import "NSApplication_BLTRExtensions.h"
#import <unistd.h>

#import "QSProcessMonitor.h"
#import "NSEvent+BLTRExtensions.h"

typedef void (^QSModalSessionBlock)(NSInteger result);

BOOL QSApplicationCompletedLaunch = NO;

@interface NSObject (QSAppDelegateProtocols)
- (BOOL)shouldSendEvent:(NSEvent *)event;
- (void)handleMouseTriggerEvent:(NSEvent *)event type:(id)type forView:(NSView *)view;
@end
@interface NSApplication (NSPrivate)
- (BOOL)_handleKeyEquivalent:(NSEvent *)event;
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
		
        //    A value transformer for checking if a given value is '1'. Used in the QSSearchPrefPane (Caps lock menu item)
        QSIntValueTransformer *intValueIsTwo = [[QSIntValueTransformer alloc] initWithInteger:2];
        [NSValueTransformer setValueTransformer:intValueIsTwo forName:@"IntegerValueIsTwo"];
		
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
    }
	return self;
}

- (BOOL)completedLaunch { return QSApplicationCompletedLaunch;  }

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
	switch ([theEvent type]) {
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

		case NSKeyDown:
			if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible]) {
				// Close the Quicksilver window when ⌘⌥Y is pressed in full screen, or the spacebar or ESC key is pressed (send event to QSSearchObjectView:keyDown)
				QLPreviewPanel *quicklookPanel = [QLPreviewPanel sharedPreviewPanel];
				NSString *key = [theEvent charactersIgnoringModifiers];
				if (([quicklookPanel isInFullScreenMode] && [key isEqualToString:@"y"]
					 && ([theEvent modifierFlags] & (NSCommandKeyMask | NSAlternateKeyMask))) || [key isEqualToString:@" "] || [theEvent keyCode] == kVK_Escape) {
					[(QSSearchObjectView *)[quicklookPanel delegate] closePreviewPanel];
					return;
				}
			}
			break;

		default:
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
}

- (NSResponder *)globalKeyEquivalentTarget { return globalKeyEquivalentTarget;  }
- (void)setGlobalKeyEquivalentTarget:(NSResponder *)value {
	if (globalKeyEquivalentTarget != value) {
		globalKeyEquivalentTarget = value;
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
		eventDelegates = nil;
	}
}

- (BOOL)isPrerelease {
	NSInteger releaseLevel = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"QSReleaseStatus"] integerValue];
	return releaseLevel > 0;
}

- (void)qs_sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    QSModalSessionBlock completionHandler = (__bridge_transfer QSModalSessionBlock)contextInfo;
    completionHandler(returnCode);
}

- (void)qs_beginSheet:(NSWindow *)sheet modalForWindow:(NSWindow *)docWindow completionHandler:(QSModalSessionBlock)completionHandler {
    [self beginSheet:sheet modalForWindow:docWindow modalDelegate:self didEndSelector:@selector(qs_sheetDidEnd:returnCode:contextInfo:) contextInfo:(__bridge_retained void *)([completionHandler copy])];
}

@end
