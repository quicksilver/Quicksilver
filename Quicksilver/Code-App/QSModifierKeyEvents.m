//
//  QSModifierKeyEvents.m
//  Quicksilver
//
//  Created by Alcor on 8/16/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import "QSModifierKeyEvents.h"
#import "QSController.h"
#import "NDHotKeyEvent_QSMods.h"
#import <Carbon/Carbon.h>
#import <unistd.h>

/*#define NSCommandKeyCode 55
#define NSShiftKeyCode 56
#define NSAlphaShiftCode 57
#define NSAlternateKeyCode 58
#define NSControlKeyCode 59
#define NSFunctionKeyCode 63*/

int NSAllModifierKeysMask = NSAlphaShiftKeyMask | NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask | NSFunctionKeyMask;

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
	UInt32 modifiers;
	GetEventParameter(theEvent, kEventParamKeyModifiers, typeUInt32, NULL, sizeof(modifiers), NULL, &modifiers);
    NSEvent * event;
    
    if([NSEvent respondsToSelector:@selector(eventWithEventRef:)]) {
        event = [NSEvent eventWithEventRef:theEvent];
    } else {
        event = [NSEvent keyEventWithType:NSFlagsChanged
                                 location:NSZeroPoint
                            modifierFlags:carbonModifierFlagsToCocoaModifierFlags(modifiers)
                                timestamp:[NSDate timeIntervalSinceReferenceDate]
                             windowNumber:0
                                  context:nil
                               characters:nil
              charactersIgnoringModifiers:nil
                                isARepeat:NO
                                  keyCode:0];
    }
//	if (VERBOSE) NSLog(@"Sending event %@", event);
    [NSApp sendEvent:event];
	return CallNextEventHandler(nextHandler, theEvent);
}

NSMutableDictionary *modifierKeyEvents = nil;
unsigned int lastModifiers;
BOOL modifierEventsEnabled = YES;

@implementation QSModifierKeyEvent

+ (void)registerForGlobalModifiers {
	EventTypeSpec eventType;
	eventType.eventClass = kEventClassKeyboard;
	eventType.eventKind = kEventRawKeyModifiersChanged;
	EventHandlerUPP handlerFunction = NewEventHandlerUPP(keyPressed);
	OSStatus err = InstallEventHandler(GetEventMonitorTarget(), handlerFunction, 1, &eventType, NULL, NULL);
	if (err) NSLog(@"gmod registration err %d", err);
}

+ (void)initialize {
	[self registerForGlobalModifiers];
}

+ (void)enableModifierEvents {modifierEventsEnabled = YES;}

+ (void)disableModifierEvents {modifierEventsEnabled = NO;}

+ (BOOL)checkForModifierEvent:(NSEvent *)theEvent {
	if (!modifierEventsEnabled) return NO;
	if (!modifierKeyEvents) return NO;
//    if(VERBOSE) NSLog(@"%s checking for modifier flags in runloop mode %@ event %x flags %x", _cmd, (NSString*)CFRunLoopCopyCurrentMode([[NSRunLoop currentRunLoop] getCFRunLoop]), theEvent, [theEvent modifierFlags]);

	unsigned int modMask = [theEvent modifierFlags] & NSAllModifierKeysMask;

    if(VERBOSE) NSLog(@"%s %x mods are %d, event mods are %d, key is %d", _cmd, theEvent, modMask, [theEvent modifierFlags], [theEvent keyCode]);
    
    if( modMask == 0 ) {
        if(VERBOSE) NSLog(@"%s an all-mods up", _cmd, (modMask == 0 ? "is" : "isn't"));
        [[modifierKeyEvents allValues] makeObjectsPerformSelector:@selector(allKeysReleased)];
    } else {
        QSModifierKeyEvent *match = [modifierKeyEvents objectForKey:[NSNumber numberWithUnsignedInt:modMask]];
        if(match == nil) {
            // if(VERBOSE) NSLog(@"%s %x no matching key event", _cmd, theEvent);
            return NO;
        }
        
        if (![match modifierToggled:modMask countTimes:[match modifierActivationCount]]) {
            // if(VERBOSE) NSLog(@"%s %x modifier not retoggled %d times for mods %d", _cmd, theEvent, [match modifierActivationCount], modMask);
            return NO;
        }
        // if(VERBOSE) NSLog(@"%s %x sending action for match %@", _cmd, theEvent, match);
        [match sendAction];
        return YES;
    }
    return NO;
}

+ (NSMutableDictionary *)modifierKeyEvents {
    if (!modifierKeyEvents) modifierKeyEvents = [[NSMutableDictionary alloc] init];
    return modifierKeyEvents;
}

+ (QSModifierKeyEvent *)eventWithIdentifier:(NSString *)identifier {
    foreach(event, [modifierKeyEvents allValues]) {
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

- (void)dealloc {
    [activationAttempts release], activationAttempts = nil;
    [super dealloc];
}

- (void)sendAction {
    [target performSelector:action];
}

- (void) printActivationArray {
    foreachkey( date, value, activationAttempts ) {
        NSLog(@"activation attempt at %f, state %s", [(NSDate*)date timeIntervalSinceNow], ( [(NSNumber*)value boolValue] == YES ? "down" : "up" ) );
    }    
}

- (void)cleanupActivationArray {
    NSMutableArray * oldAttempts = [[NSMutableArray alloc] init];
    foreachkey( date, value, activationAttempts ) {
        if([(NSDate*)date timeIntervalSinceNow] < -0.3f)
            [oldAttempts addObject:date];
    }
    [activationAttempts removeObjectsForKeys:oldAttempts];
    [oldAttempts release];
}

- (void)allKeysReleased {
    if(activationAttempts == nil)
        activationAttempts = [[NSMutableDictionary alloc] init];
    
    [activationAttempts setValue:[NSNumber numberWithBool:NO]
                          forKey:[NSDate date]];
}

- (BOOL)modifierToggled:(unsigned int)modifierKeysMask countTimes:(unsigned int)count {
    // NSLog(@"%s toggled modifier %d, self is %d", _cmd, modifierKeysMask, modifierActivationMask);
    if(activationAttempts == nil)
        activationAttempts = [[NSMutableDictionary alloc] init];
    
    [activationAttempts setValue:[NSNumber numberWithBool:YES]
                          forKey:[NSDate date]];
    
    [self cleanupActivationArray];
    [self printActivationArray];
    
    BOOL lastValue = NO;
    BOOL currentValue;
    int currentCount = 0;
    foreachkey( date, value, activationAttempts ) {
        currentValue = [(NSNumber*)value boolValue];
        NSLog(@"current mod %s at %f, old was %s", (currentValue == YES ? "down" : "up"), [(NSDate*)date timeIntervalSinceNow], (lastValue == YES ? "down" : "up"));
        if(currentValue == YES && lastValue != currentValue) {
            currentCount++;
            if(currentCount == count)
                return YES;
        }
    }
    
    return NO;
    
    /* This is commented because it doesn't work when QS doesn't have the focus, since our run loop isn't running (and thus we can't peek ahead and expect to get events) */
    /*NSEvent *nextMask = [NSApp nextEventMatchingMask:NSFlagsChangedMask untilDate:[NSDate dateWithTimeIntervalSinceNow:0.2] inMode:NSDefaultRunLoopMode dequeue:YES];
     if(nextMask == nil) {
     if(VERBOSE) NSLog(@"%s no other modifier event in 0.2s", _cmd);
     return NO;
     }
     
     if (!([nextMask modifierFlags] & NSAllModifierKeysMask) ) { // All keys released
     nextMask = [NSApp nextEventMatchingMask:NSFlagsChangedMask untilDate:[NSDate dateWithTimeIntervalSinceNow:0.2] inMode:NSDefaultRunLoopMode dequeue:YES];
     if(VERBOSE) NSLog(@"%s all keys up", _cmd);
     if (nextMask && ([nextMask modifierFlags]) == modifierKeysMask) { // Modifier re-pressed
     if(VERBOSE) NSLog(@"%s modifier %d repressed", _cmd, modifierKeysMask);
     return YES;
     }
     }
     if (!([nextMask modifierFlags] & NSAlphaShiftKeyMask) ) { //All keys released
     if(VERBOSE) NSLog(@"%s all keys up (alpha)", _cmd);
     return YES;
     }
     */
    return NO;
}

- (unsigned int)modifierActivationMask { return modifierActivationMask;  }
- (void)setModifierActivationMask:(unsigned int)value {
    modifierActivationMask = 1 << value;
}

- (int)modifierActivationCount { return modifierActivationCount;  }
- (void)setModifierActivationCount:(int)newModifierActivationCount {
    modifierActivationCount = newModifierActivationCount;
}


- (id)target { return target;  }
- (void)setTarget:(id)newTarget {
    if (target != newTarget) {
        [target release];
        target = [newTarget retain];
    }
}


- (SEL) action { return action;  }
- (void)setAction:(SEL)newAction {
    action = newAction;
}

- (NSString *)identifier { return identifier;  }
- (void)setIdentifier:(NSString *)newIdentifier {
    if (identifier != newIdentifier) {
        [identifier release];
        identifier = [newIdentifier retain];
    }
}

@end
