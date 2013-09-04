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

void logKeyMap(char *keyMap) {
	NSMutableString *string = [NSMutableString string];
	NSInteger i;
	for (i = 0; i<16; i++) {
		[string appendFormat:@" %02hhX", keyMap[i]];
    }

	NSLog(@"KeyMap %@", string);

}

void KeyMapAddKeyCode(char *keymap, NSInteger keyCode) {
	NSInteger i = keyCode / 8;
	NSInteger j = keyCode % 8;
	keymap[i] = keymap[i] | 1 << j;
}

void KeyMapInvert(char *keymap) {
	NSInteger i;
	for (i = 0; i<16; i++)
		keymap[i] = ~keymap[i];
}
void KeyMapInit(char *keymap) {
    NSInteger i;
	for (i = 0; i<16; i++) keymap[i] = 0;
}

BOOL KeyMapAND(char *keymap, char *keymap2) {
	NSInteger i;
	for (i = 0; i<16; i++)
		if (keymap[i] & keymap2[i]) return YES;
	return NO;
}


OSStatus keyPressed(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
    
    NSEvent *event = [NSEvent eventWithEventRef:theEvent];
    
    [NSApp sendEvent:event];
	return CallNextEventHandler(nextHandler, theEvent);
}

NSMutableDictionary *modifierKeyEvents = nil;
NSUInteger lastModifiers;
BOOL modifierEventsEnabled = YES;

// !!!:paulkohut:20100316
// additional infomation needed for double tap events
NSTimeInterval lastEventTime = 0;
double doubleTapTimerWindow = 0.3;
NSUInteger previousModifier = 0;

@implementation QSModifierKeyEvent

@synthesize timesKeysPressed;

+ (void)enableModifierEvents {modifierEventsEnabled = YES;}
+ (void)disableModifierEvents {modifierEventsEnabled = NO;}

// !!!:paulkohut:20100318
// Revised handler for modifier keys and caps lock key, single and double
// tap supported.
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
    //BOOL capsKeyPressed = NO;
    if(!modsKeyPressed && (mods == 0 || mods & (NSAlphaShiftKeyMask | NSMouseEnteredMask)) ) {
        mods = NSAlphaShiftKeyMask;
        //capsKeyPressed = YES;
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
        //        NSLog(@"MOD = %d      PRE = %d      ModsAdded = %d    CapsKey = %d    ModsKey = %d", mods, previousModifier, modsAdded, capsKeyPressed, modsKeyPressed);

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

    //    NSLog(@"MOD = %d      PRE = %d      ModsAdded = %d    CapsKey = %d    ModsKey = %d", mods, previousModifier, modsAdded, capsKeyPressed, modsKeyPressed);

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
	EventTypeSpec eventType;
	eventType.eventClass = kEventClassKeyboard;
	eventType.eventKind = kEventRawKeyModifiersChanged;
	EventHandlerUPP handlerFunction = NewEventHandlerUPP(keyPressed);
	OSStatus err = InstallEventHandler(GetEventMonitorTarget(), handlerFunction, 1, &eventType, NULL, NULL);
	if (err) NSLog(@"gmod registration err %ld", (long)err);
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


- (void)setModifierActivationMask:(NSUInteger)value {
	modifierActivationMask = 1 << value;

	switch (modifierActivationMask) {
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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.target performSelector:self.action withObject:nil];
#pragma clang diagnostic pop
}

- (void)checkForModifierTap:(BOOL)modsAdded {

    if (!modsAdded) {
        if (self.timesKeysPressed == modifierActivationCount) {
            [self sendAction];
        }
    } else {
        double window = 0.25;

        self.timesKeysPressed += 1;
        [self performSelector:@selector(resetTimesKeysPressed:) withObject:nil afterDelay:window extend:YES];
    }
}

-(void)resetTimesKeysPressed:(id)sender {
    self.timesKeysPressed = 0;
}

- (NSUInteger)modifierActivationMask { return modifierActivationMask; }

- (NSInteger)modifierActivationCount { return modifierActivationCount; }
- (void)setModifierActivationCount:(NSInteger)newModifierActivationCount {
	modifierActivationCount = newModifierActivationCount;
}

- (id)target { return target; }
- (void)setTarget:(id)newTarget {
	if (target != newTarget) {
		target = newTarget;
	}
}

- (SEL) action { return action; }
- (void)setAction:(SEL)newAction {
	action = newAction;
}

- (NSString *)identifier { return identifier; }
- (void)setIdentifier:(NSString *)newIdentifier {
	if (identifier != newIdentifier) {
		identifier = newIdentifier;
	}
}

@end
