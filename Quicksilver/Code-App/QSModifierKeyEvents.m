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

NSInteger NSAllModifierKeysMask = NSEventModifierFlagShift | NSEventModifierFlagControl | NSEventModifierFlagOption | NSEventModifierFlagCommand | NSEventModifierFlagFunction;


NSMutableDictionary *modifierKeyEvents = nil;
NSUInteger lastModifiers;
BOOL modifierEventsEnabled = YES;
BOOL capsLockIsOn = NO;

@implementation QSModifierKeyEvent

@synthesize timesKeysPressed, target, action, identifier, modifierActivationCount;

+ (void)enableModifierEvents {
    modifierEventsEnabled = YES;
	capsLockIsOn = ([NSEvent modifierFlags] & NSEventModifierFlagCapsLock) == NSEventModifierFlagCapsLock;
}

+ (void)disableModifierEvents {modifierEventsEnabled = NO;}


+ (void)checkForModifierEvent:(NSEvent *)theEvent {
	if (!modifierEventsEnabled) return;
	if (!modifierKeyEvents) return;

	NSUInteger mods = [theEvent modifierFlags] & NSEventModifierFlagDeviceIndependentFlagsMask;

	BOOL capsLockIsNowOn = (mods & NSEventModifierFlagCapsLock) == NSEventModifierFlagCapsLock;
	if (capsLockIsNowOn != capsLockIsOn) {
		mods |= NSEventModifierFlagCapsLock;
	} else {
		mods &= ~NSEventModifierFlagCapsLock;
	}
	capsLockIsOn = capsLockIsNowOn;

	QSModifierKeyEvent *match = [modifierKeyEvents objectForKey:(mods ? @(mods) : @(lastModifiers))];

	[modifierKeyEvents enumerateKeysAndObjectsUsingBlock:^(id key, QSModifierKeyEvent *ev, BOOL *stop) {
		if (match != ev) {
			// reset the modifier state for any non-matching modifier key events (Issue #1950)
			[ev resetTimesKeysPressed:self];
		}
	}];

	BOOL modsAdded = mods > lastModifiers;

	lastModifiers = mods & ~NSEventModifierFlagCapsLock;
	[match checkForModifierTap:modsAdded];
}

+ (void)regisiterForGlobalModifiers {
    // global monitor for when QS isn't active
	[NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskFlagsChanged handler:^(NSEvent *theEvent) {
        [self checkForModifierEvent:theEvent];
    }];
    // local monitor for flags changed events when QS is active
	[NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskFlagsChanged handler:^NSEvent *(NSEvent *theEvent) {
        [self checkForModifierEvent:theEvent];
        // return the event as is, incase anywhere else wants to use it (e.g. QSSearchObjectView.m:flagsChanged - to show alternate actions)
        return theEvent;
    }];
}

+ (void)initialize {
	capsLockIsOn = ([NSEvent modifierFlags] & NSEventModifierFlagCapsLock) == NSEventModifierFlagCapsLock;

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
	[[QSModifierKeyEvent modifierKeyEvents] setObject:self forKey:@(self.modifierActivationMask)];
}

- (void)disable {
	[[QSModifierKeyEvent modifierKeyEvents] objectForKey:@(self.modifierActivationMask)];
	[[QSModifierKeyEvent modifierKeyEvents] removeObjectForKey:@(self.modifierActivationMask)];
}

- (NSUInteger)modifierActivationMask {
    return _modifierActivationMask;
}

- (void)setModifierActivationMask:(NSUInteger)value {
	_modifierActivationMask = 1 << value;

    self.timesKeysPressed = 0;
}


- (void)sendAction {
    SuppressPerformSelectorLeakWarning(
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetTimesKeysPressed:) object:nil];
        [self resetTimesKeysPressed:nil];
        [self.target performSelector:self.action withObject:nil];
    );
}

- (void)checkForModifierTap:(BOOL)modsAdded {
    if (modsAdded) {
        pressedKeyDownCount = CGEventSourceCounterForEventType(
                                                               kCGEventSourceStateHIDSystemState,
                                                               kCGEventKeyDown
                                                               );

        self.timesKeysPressed += 1;

        double window = 0.3;
        [self performSelector:@selector(resetTimesKeysPressed:) withObject:nil afterDelay:window extend:YES];

        // Workaround: CapsLock does not generate keyUp events -> simulate keyUp right after keyDown.
		if (self.modifierActivationMask & NSEventModifierFlagCapsLock) {
        	modsAdded = NO;
        }
    }

    if (!modsAdded) {
        uint32_t newPressedKeyDownCount = CGEventSourceCounterForEventType (
                                                                            kCGEventSourceStateHIDSystemState,
                                                                            kCGEventKeyDown
                                                                            );

        if (newPressedKeyDownCount == pressedKeyDownCount && self.timesKeysPressed == self.modifierActivationCount) {
            [self sendAction];
        }
    }
}

-(void)resetTimesKeysPressed:(id)sender {
    self.timesKeysPressed = 0;
}

+ (void)resetModifierState
{
    lastModifiers = 0;
}
@end
