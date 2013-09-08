//
//  QSModifierKeyEvents.m
//  Quicksilver
//
//  Created by Alcor on 8/16/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import "QSModifierKeyEvents.h"
#import "QSController.h"
#import "QSHotKeyEvent.h"
#import <unistd.h>


#define NSNumlockKeyCode 10
#define NSCommandKeyCode 55
#define NSShiftKeyCode 56
#define NSAlphaShiftCode 57
#define NSAlternateKeyCode 58
#define NSControlKeyCode 59
#define NSFunctionKeyCode 63

NSInteger NSAllModifierKeysMask = NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask | NSFunctionKeyMask;


NSMutableDictionary *modifierKeyEvents = nil;
NSUInteger lastModifiers;
BOOL modifierEventsEnabled = YES;


// additional infomation needed for double tap events
NSTimeInterval lastEventTime = 0;
double doubleTapTimerWindow = 0.3;
NSUInteger previousModifier = 0;

@implementation QSModifierKeyEvent

@synthesize timesKeysPressed, target, action, identifier, modifierActivationCount;

+ (void)enableModifierEvents {modifierEventsEnabled = YES;}
+ (void)disableModifierEvents {modifierEventsEnabled = NO;}


+ (void)checkForModifierEvent:(NSEvent *)theEvent {
	if (!modifierEventsEnabled) return;
	if (!modifierKeyEvents) return;

	NSUInteger mods = [theEvent modifierFlags];

    BOOL modsKeyPressed = NO;
    if((mods & NSAllModifierKeysMask))
        modsKeyPressed = YES;

    // To determine if the caps lock key is the only key press check if mods is
    // in one of the 3 states below.  NSMouseEnteredMask is set if QS has current
    // focus.
    if(!modsKeyPressed && (mods == 0 || mods & (NSAlphaShiftKeyMask | NSMouseEnteredMask)) ) {
        mods = NSAlphaShiftKeyMask;
    }

    BOOL modsAdded = mods >= lastModifiers;

	lastModifiers = mods;

    NSTimeInterval eventTime = [NSDate timeIntervalSinceReferenceDate];

    // Get the mod key.
    NSUInteger puremod = mods & NSAllModifierKeysMask;
    if (!puremod)
        puremod = NSAlphaShiftKeyMask;

    QSModifierKeyEvent *match = [modifierKeyEvents objectForKey:[NSNumber numberWithUnsignedShort:[theEvent keyCode]]];

    // handle double taps
    if ([match modifierActivationCount] == 2) {

        if (mods == NSAlphaShiftKeyMask && (previousModifier == NSAlphaShiftKeyMask ||
                                            previousModifier == 0) ) {
            // Handle caps lock key presses
            if([self alphaShiftReleased:eventTime]) {
                [match sendAction];
                lastEventTime = 0;
                previousModifier = 0;
            } else {
                lastEventTime = eventTime;
                previousModifier = 0;
            }
            return;
        } else {
            lastEventTime = eventTime;
            previousModifier = lastModifiers;
            if (modsAdded && (mods != previousModifier || ![self modifierToggled:eventTime])) {
                // Handle other modifier key presses
                return;
            }
        }
    }

    previousModifier = lastModifiers;
    lastEventTime = eventTime;
    // Ignore caps lock key if QS modifier action is set to single tap
    if(modsAdded && [match modifierActivationCount] == 1 && mods == NSAlphaShiftKeyMask)
        return;

    [match checkForModifierTap:modsAdded];
}

// returns true if double tap of caps key occurred within time window
+ (BOOL)alphaShiftReleased:(NSTimeInterval)eventTime {
    if(lastEventTime + 0.5 > eventTime)
        return YES;
    return NO;
}

// returns true if double tap occurred within time window
+ (BOOL)modifierToggled:(NSTimeInterval)eventTime {
    if(lastEventTime + doubleTapTimerWindow > eventTime)
        return YES;
    return NO;
}

+ (void)regisiterForGlobalModifiers {
    // global monitor for when QS isn't active
    [NSEvent addGlobalMonitorForEventsMatchingMask:NSFlagsChangedMask handler:^(NSEvent *theEvent) {
        [self checkForModifierEvent:theEvent];
    }];
    // local monitor for flags changed events when QS is active
    [NSEvent addLocalMonitorForEventsMatchingMask:NSFlagsChangedMask handler:^NSEvent *(NSEvent *theEvent) {
        [self checkForModifierEvent:theEvent];
        // return the event as is, incase anywhere else wants to use it (e.g. QSSearchObjectView.m:flagsChanged - to show alternate actions)
        return theEvent;
    }];
}

+ (void)initialize {
	[self regisiterForGlobalModifiers];
}

+ (NSMutableDictionary *)modifierKeyEvents {
	if (!modifierKeyEvents) modifierKeyEvents = [[NSMutableDictionary alloc] init];
	return modifierKeyEvents;
}

+ (QSModifierKeyEvent *)eventWithIdentifier:(NSString *)identifier {
	for(QSModifierKeyEvent * event in [modifierKeyEvents allValues]) {
		if ([[event identifier] isEqualToString:identifier]) return event;
	}
	return nil;
}

- (void)enable {
	[[QSModifierKeyEvent modifierKeyEvents] setObject:self forKey:[NSNumber numberWithUnsignedInteger:keyCode]];
}

- (void)disable {
	[[[[QSModifierKeyEvent modifierKeyEvents] objectForKey:[NSNumber numberWithUnsignedInteger:keyCode]] retain] autorelease];
	[[QSModifierKeyEvent modifierKeyEvents] removeObjectForKey:[NSNumber numberWithUnsignedInteger:keyCode]];
}


//- (id)init {
//
//	if (self = [super init]) {
//		NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
//
//		[self bind:@"modifierActivationMask" toObject:defaultsController
//	   withKeyPath:@"values.QSModifierActivationKey"
//		   options:nil];
//
//		[self bind:@"modifierActivationCount" toObject:defaultsController
//	   withKeyPath:@"values.QSModifierActivationCount"
//		   options:nil];
//	}
//	return self;
//}

- (NSUInteger)modifierActivationMask {
    return _modifierActivationMask;
}

- (void)setModifierActivationMask:(NSUInteger)value {
	_modifierActivationMask = 1 << value;

	switch (self.modifierActivationMask) {
		case NSCommandKeyMask:
			keyCode = NSCommandKeyCode;
			break;
		case NSAlternateKeyMask:
			keyCode = NSAlternateKeyCode;
			break;
		case NSControlKeyMask:
			keyCode = NSControlKeyCode;
			break;
		case NSShiftKeyMask:
			keyCode = NSShiftKeyCode;
			break;
		case NSFunctionKeyMask:
			keyCode = NSFunctionKeyCode;
			break;
		case NSAlphaShiftKeyMask:
			keyCode = NSAlphaShiftCode;
			break;
		default:
			keyCode = 0;
	}
    self.timesKeysPressed = 0;
	//	KeyMapInit((char *)&modRequireMap);
	//	KeyMapAddKeyCode((char *)&modRequireMap, keyCode);
	//
	//	KeyMapInit((char *)&modExcludeMap);
	//	KeyMapAddKeyCode((char *)&modExcludeMap, keyCode);
	//	KeyMapAddKeyCode((char *)&modExcludeMap, NSAlphaShiftCode);
	//	KeyMapInvert((char *)&modExcludeMap);
}


- (void)sendAction {
    SuppressPerformSelectorLeakWarning(
        [self.target performSelector:self.action withObject:nil];
    );
}

- (void)checkForModifierTap:(BOOL)modsAdded {

    if (!modsAdded) {
        NSTimeInterval timeDiff = [firstModifierPressedTime timeIntervalSinceNow];
        NSTimeInterval newTimeSinceLastKeyDown = CGEventSourceSecondsSinceLastEventType (
                                                                 kCGEventSourceStateHIDSystemState,
                                                                 kCGEventKeyDown
                                                                 );
        
        NSTimeInterval keyPressDif = timeSinceLastKeyDown - newTimeSinceLastKeyDown;
        if (fabs(timeDiff - keyPressDif) < 0.001 && self.timesKeysPressed == self.modifierActivationCount) {
            [self sendAction];
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetTimesKeysPressed:) object:nil];
            [self resetTimesKeysPressed:nil];
        }
    } else {
        firstModifierPressedTime = [NSDate date];
        timeSinceLastKeyDown = CGEventSourceSecondsSinceLastEventType (
                                                               kCGEventSourceStateHIDSystemState,
                                                               kCGEventKeyDown
                                                               );
        double window = 0.25;
        self.timesKeysPressed += 1;
        [self performSelector:@selector(resetTimesKeysPressed:) withObject:nil afterDelay:window extend:YES];
        
    }
}

-(void)resetTimesKeysPressed:(id)sender {
    self.timesKeysPressed = 0;
}

@end
