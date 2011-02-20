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
#import <Carbon/Carbon.h>
#import <unistd.h>

#define NSNumlockKeyCode 10
#define NSCommandKeyCode 55
#define NSShiftKeyCode 56
#define NSAlphaShiftCode 57
#define NSAlternateKeyCode 58
#define NSControlKeyCode 59
#define NSFunctionKeyCode 63

int NSAllModifierKeysMask = NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask | NSFunctionKeyMask;

void logKeyMap(char *keyMap) {
	NSMutableString *string = [NSMutableString string];
	int i;
	for (i = 0; i<16; i++)
		[string appendFormat:@" %02hhX", keyMap[i]];

	NSLog(@"KeyMap %@", string);

}

void KeyMapAddKeyCode(char *keymap, int keyCode) {
	int i = keyCode / 8;
	int j = keyCode % 8;
	keymap[i] = keymap[i] | 1 << j;
}

void KeyMapInvert(char *keymap) {
	int i;
	for (i = 0; i<16; i++)
		keymap[i] = ~keymap[i];
}
void KeyMapInit(char *keymap) {
    int i;
	for (i = 0; i<16; i++) keymap[i] = 0;
}

BOOL KeyMapAND(char *keymap, char *keymap2) {
	int i;
	for (i = 0; i<16; i++)
		if (keymap[i] & keymap2[i]) return YES;
	return NO;
}


OSStatus keyPressed(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
    OSStatus err;
	UInt32 modifiers;
    err = GetEventParameter( theEvent, kEventParamKeyModifiers, typeUInt32, 0, sizeof(modifiers), 0, &modifiers );
    if( err != 0 ) {
        NSLog( @"Failed getting event modifiers param! %ld\n", err );
    }
    
    /* TODO: Use the new 10.5-only call ? */
    //    NSEvent *event = [NSEvent eventWithEventRef:theEvent];
    NSEvent *event = [NSEvent keyEventWithType:NSFlagsChanged location:NSZeroPoint
                                 modifierFlags:carbonModifierFlagsToCocoaModifierFlags(modifiers)
                                     timestamp:GetEventTime( theEvent )
                                  windowNumber:0 context:nil
                                    characters:nil charactersIgnoringModifiers:nil
                                     isARepeat:NO keyCode:0];
    
    [NSApp sendEvent:event];
	return CallNextEventHandler(nextHandler, theEvent);
}

NSMutableDictionary *modifierKeyEvents = nil;
unsigned int lastModifiers;
BOOL modifierEventsEnabled = YES;

// !!!:paulkohut:20100316
// additional infomation needed for double tap events
NSTimeInterval lastEventTime = 0;
double doubleTapTimerWindow = 0.3;
unsigned int previousModifier = 0;

@implementation QSModifierKeyEvent
+ (void)enableModifierEvents {modifierEventsEnabled = YES;}
+ (void)disableModifierEvents {modifierEventsEnabled = NO;}

// !!!:paulkohut:20100318
// Revised handler for modifier keys and caps lock key, single and double
// tap supported.
+ (BOOL)checkForModifierEvent:(NSEvent *)theEvent {
	if (!modifierEventsEnabled) return NO;
	if (!modifierKeyEvents) return NO;

	unsigned int mods = [theEvent modifierFlags];

    BOOL modsKeyPressed = NO;
    if((mods & NSAllModifierKeysMask))
        modsKeyPressed = YES;

    // To determine if the caps lock key is the only key press check if mods is
    // in one of the 3 states below.  NSMouseEnteredMask is set if QS has current
    // focus.
    BOOL capsKeyPressed = NO;
    if(!modsKeyPressed && (mods == 0 || mods & (NSAlphaShiftKeyMask | NSMouseEnteredMask)) ) {
        mods = NSAlphaShiftKeyMask;
        capsKeyPressed = YES;
    }

	BOOL modsAdded = mods >= lastModifiers;
	lastModifiers = mods;

    if(!modsAdded) // && capsKeyPressed)
        return NO;

    NSTimeInterval eventTime = [NSDate timeIntervalSinceReferenceDate];

    // Get the mod key.
    unsigned int puremod = mods & NSAllModifierKeysMask;
    if (!puremod)
        puremod = NSAlphaShiftKeyMask;

    QSModifierKeyEvent *match = [modifierKeyEvents objectForKey:[NSNumber numberWithUnsignedInt:puremod]];

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
                return YES;
            } else {
                lastEventTime = eventTime;
                previousModifier = 0;
                return NO;
            }
        } else if (mods != previousModifier || ![self modifierToggled:eventTime]) {
            // Handle other modifier key presses
            lastEventTime = eventTime;
            previousModifier = lastModifiers;
            return NO;
        }
    }

    //    NSLog(@"MOD = %d      PRE = %d      ModsAdded = %d    CapsKey = %d    ModsKey = %d", mods, previousModifier, modsAdded, capsKeyPressed, modsKeyPressed);

    previousModifier = lastModifiers;
    lastEventTime = eventTime;

    // Ignore caps lock key if QS modifier action is set to single tap
    if([match modifierActivationCount] == 1 && mods == NSAlphaShiftKeyMask)
        return NO;

    return [match checkForModifierTap];
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
	if (err) NSLog(@"gmod registration err %ld", err);
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
	[[QSModifierKeyEvent modifierKeyEvents] setObject:self forKey:[NSNumber numberWithUnsignedInt:modifierActivationMask]];
}

- (void)disable {
	[[[[QSModifierKeyEvent modifierKeyEvents] objectForKey:[NSNumber numberWithUnsignedInt:modifierActivationMask]] retain] autorelease];
	[[QSModifierKeyEvent modifierKeyEvents] removeObjectForKey:[NSNumber numberWithUnsignedInt:modifierActivationMask]];
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


- (void)setModifierActivationMask:(unsigned int)value {
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
	//	KeyMapInit((char *)&modRequireMap);
	//	KeyMapAddKeyCode((char *)&modRequireMap, keyCode);
	//
	//	KeyMapInit((char *)&modExcludeMap);
	//	KeyMapAddKeyCode((char *)&modExcludeMap, keyCode);
	//	KeyMapAddKeyCode((char *)&modExcludeMap, NSAlphaShiftCode);
	//	KeyMapInvert((char *)&modExcludeMap);
}


- (void)sendAction {
	[target performSelector:action];
}

- (BOOL)checkForModifierTap {

	usleep(10000);
	char keyMap[16];
	//NSLog(@"check");
	//logKeyMap((char *)&modRequireMap);
	//logKeyMap((char *)&modExcludeMap);

	char modRequireMap[16];
	char modExcludeMap[16];

	KeyMapInit((char *)&modRequireMap);
	KeyMapAddKeyCode((char *)&modRequireMap, keyCode);

	KeyMapInit((char *)&modExcludeMap);
	KeyMapAddKeyCode((char *)&modExcludeMap, keyCode);
	if (keyCode != NSAlphaShiftCode) KeyMapAddKeyCode((char *)&modExcludeMap, NSAlphaShiftCode);
	KeyMapInvert((char *)&modExcludeMap);


	GetKeys((void *)keyMap);
	//logKeyMap((char *)&keyMap);

	if (!KeyMapAND((char *)&keyMap, (char *)&modRequireMap) || KeyMapAND((char *)&keyMap, (char *)&modExcludeMap))
        return NO;

	NSTimeInterval startDate = [NSDate timeIntervalSinceReferenceDate];
	NSTimeInterval window = [self modifierActivationCount] == 2 ? doubleTapTimerWindow : 0.15;

	while(([NSDate timeIntervalSinceReferenceDate] -startDate) <window) {
		GetKeys((void *)keyMap);
        //	logKeyMap((char *)&keyMap);

		if (KeyMapAND((char *)&keyMap, (char *)&modExcludeMap))
            break; //Other keys pressed

		if (!KeyMapAND((char *)&keyMap, (char *)&modRequireMap)) { // Modifier released
			[self sendAction];
			return YES;
		}
		usleep(10000);
	}

	return NO;
}

- (unsigned int)modifierActivationMask { return modifierActivationMask; }

- (int)modifierActivationCount { return modifierActivationCount; }
- (void)setModifierActivationCount:(int)newModifierActivationCount {
	modifierActivationCount = newModifierActivationCount;
}

- (id)target { return target; }
- (void)setTarget:(id)newTarget {
	if (target != newTarget) {
		[target release];
		target = [newTarget retain];
	}
}

- (SEL) action { return action; }
- (void)setAction:(SEL)newAction {
	action = newAction;
}

- (NSString *)identifier { return identifier; }
- (void)setIdentifier:(NSString *)newIdentifier {
	if (identifier != newIdentifier) {
		[identifier release];
		identifier = [newIdentifier retain];
	}
}

@end
