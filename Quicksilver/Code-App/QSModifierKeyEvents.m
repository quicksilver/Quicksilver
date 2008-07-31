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

#define NSCommandKeyCode 55
#define NSShiftKeyCode 56
#define NSAlphaShiftCode 57
#define NSAlternateKeyCode 58
#define NSControlKeyCode 59
#define NSFunctionKeyCode 63

unsigned int lastModifiers;

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
	EventMouseButton button;
	GetEventParameter(theEvent, kEventParamMouseButton, typeMouseButton, 0,
					  sizeof(button), 0, &button);
	UInt32 modifiers = GetCurrentEventKeyModifiers();
    
    NSEvent * event = [NSEvent keyEventWithType:NSFlagsChanged
                                       location:NSZeroPoint
                                  modifierFlags:carbonModifierFlagsToCocoaModifierFlags(modifiers)
                                      timestamp:[NSDate timeIntervalSinceReferenceDate]
                                   windowNumber:0
                                        context:nil
                                     characters:nil
                    charactersIgnoringModifiers:nil
                                      isARepeat:NO
                                        keyCode:0];
	// if (VERBOSE) NSLog(@"Sending event %@", event);
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

	unsigned int mods = [theEvent modifierFlags];
/*	BOOL modsAdded = mods >= lastModifiers;
	lastModifiers = mods;
//	NSLog(@"mods %d %d ", modsAdded, mods);

	if (!modsAdded) {
        if(VERBOSE) NSLog(@"%s %x no mods added", _cmd, theEvent);
        return NO;
    }*/

	unsigned int puremod = mods & NSAllModifierKeysMask;
    // if(VERBOSE) NSLog(@"%s %x mods is %d, puremod is %d", _cmd, theEvent, mods, puremod);

	QSModifierKeyEvent *match = [modifierKeyEvents objectForKey:[NSNumber numberWithUnsignedInt:puremod]];
    if(match == nil) {
        // if(VERBOSE) NSLog(@"%s %x no matching key event", _cmd, theEvent);
        return NO;
    }
    
    if (![match modifierToggled:puremod countTimes:[match modifierActivationCount]]) {
        // if(VERBOSE) NSLog(@"%s %x modifier not retoggled %d times for mods %d", _cmd, theEvent, [match modifierActivationCount], puremod);
        return NO;
	}
    // if(VERBOSE) NSLog(@"%s %x sending action for match %@", _cmd, theEvent, match);
    [match sendAction];
    return YES;
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


- (void)sendAction {
	[target performSelector:action];
}

- (BOOL)modifierToggled:(unsigned int)modifierKeysMask countTimes:(unsigned int)count {
    // NSLog(@"%s toggled modifier %d, self is %d", _cmd, modifierKeysMask, modifierActivationMask);
    if(activationAttempts == nil)
        activationAttempts = [[NSMutableArray alloc] init];
    
    [activationAttempts addObject:[NSDate date]];
    
    NSMutableArray * oldAttempts = [[NSMutableArray alloc] init];
    foreach( date, activationAttempts ) {
        // NSLog(@"date %@ interval from now %f", date, [date timeIntervalSinceNow]);
        if([date timeIntervalSinceNow] < -0.3f)
            [oldAttempts addObject:date];
    }
    [activationAttempts removeObjectsInArray:oldAttempts];
    // NSLog(@"activationAttempts %@", activationAttempts);
    
    if([activationAttempts count] == count) {
        return YES;
    }
    
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

/*- (BOOL)checkForModifierTap {
    if(VERBOSE) NSLog(@"%s", _cmd);
	usleep(10000);
	char keyMap[16];

	char modRequireMap[16];
	char modExcludeMap[16];
    
//    logKeyMap((char *)&modRequireMap);
//    logKeyMap((char *)&modExcludeMap);
    
    KeyMapInit((char *)&modRequireMap);
	KeyMapAddKeyCode((char *)&modRequireMap, keyCode);

	KeyMapInit((char *)&modExcludeMap);
	KeyMapAddKeyCode((char *)&modExcludeMap, keyCode);
	if (keyCode != NSAlphaShiftCode) KeyMapAddKeyCode((char *)&modExcludeMap, NSAlphaShiftCode);
	KeyMapInvert((char *)&modExcludeMap);


	GetKeys((void *)keyMap);
//    logKeyMap((char *)&keyMap);

	if (!KeyMapAND((char *)&keyMap, (char *)&modRequireMap) || KeyMapAND((char *)&keyMap, (char *)&modExcludeMap)) return NO;

	NSTimeInterval startDate = [NSDate timeIntervalSinceReferenceDate];
	NSTimeInterval window = [self modifierActivationCount] == 2 ? 0.3 : 0.15;
	while(([NSDate timeIntervalSinceReferenceDate] - startDate) < window) {
		GetKeys((void *)keyMap);
//        logKeyMap((char *)&keyMap);

		if (KeyMapAND((char *)&keyMap, (char *)&modExcludeMap))break; //Other keys pressed

		if (!KeyMapAND((char *)&keyMap, (char *)&modRequireMap)) { // Modifier released
			[self sendAction];
			return YES;
		}
		usleep(10000);
	}

	return NO;
}*/

- (unsigned int)modifierActivationMask { return modifierActivationMask;  }
- (void)setModifierActivationMask:(unsigned int)value {
	modifierActivationMask = 1 << value;
    
/*	switch (modifierActivationMask) {
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
	}*/
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
