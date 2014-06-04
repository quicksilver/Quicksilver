//
// QSHotKeyEvent.m
// Quicksilver
//
// Created by Alcor on 8/16/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "QSHotKeyEvent.h"
#import "CGSPrivate.h"

static NSMutableDictionary *hotKeyDictionary;

@implementation QSHotKeyEvent
+ (void)initialize {
	hotKeyDictionary = [[NSMutableDictionary alloc] init];
}
+ (void)disableGlobalHotKeys {
	CGSConnection conn = _CGSDefaultConnection();
	CGSSetGlobalHotKeyOperatingMode(conn, CGSGlobalHotKeyDisable);
}
+ (void)enableGlobalHotKeys {
	CGSConnection conn = _CGSDefaultConnection();
	CGSSetGlobalHotKeyOperatingMode(conn, CGSGlobalHotKeyEnable);
}

- (NSString *)identifier {
	NSArray *array = [hotKeyDictionary allKeysForObject:self];
	if ([array count]) return [array lastObject];
	return nil;
}

- (NSArray *)identifiers {
    return [hotKeyDictionary allKeysForObject:self];
}

- (void)setIdentifier:(NSString *)anIdentifier {
	[hotKeyDictionary setObject:self forKey:anIdentifier];
}

- (void)typeHotkey {
    CGKeyCode keyCode = [self keyCode];
    
    CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
    CGEventSourceSetLocalEventsFilterDuringSuppressionState(source, kCGEventFilterMaskPermitLocalMouseEvents | kCGEventFilterMaskPermitSystemDefinedEvents,kCGEventSuppressionStateSuppressionInterval);
    CGEventRef keyDown = CGEventCreateKeyboardEvent(source, keyCode, YES);
    CGEventSetFlags(keyDown, [self modifierFlags]);
    CGEventRef keyUp = CGEventCreateKeyboardEvent(source, keyCode, NO);
    
    CGEventPost(kCGAnnotatedSessionEventTap, keyDown);
    CGEventPost(kCGAnnotatedSessionEventTap, keyUp);
    CFRelease(keyUp);
    CFRelease(keyDown);
    CFRelease(source);
}

+ (instancetype)hotKeyWithIdentifier:(NSString *)anIdentifier {
	return [hotKeyDictionary objectForKey:anIdentifier];
}

+ (instancetype)hotKeyWithDictionary:(NSDictionary *)dict {
	if (![dict objectForKey:@"keyCode"] || ![dict objectForKey:@"modifiers"]) {
        return nil;
    }

    UInt16 keyCode = [[dict objectForKey:@"keyCode"] shortValue];
    NSUInteger modifiers = [[dict objectForKey:@"modifiers"] unsignedIntegerValue];
//    unichar character = [[dict objectForKey:@"character"] characterAtIndex:0];

    return (QSHotKeyEvent *)[self getHotKeyForKeyCode:keyCode modifierFlags:modifiers];
}
@end

@implementation NDHotKeyEvent (QSMods)

+ (instancetype)getHotKeyForKeyCode:(UInt16)aKeyCode character:(unichar)aChar carbonModifierFlags:(NSUInteger)aModifierFlags {
    return [self getHotKeyForKeyCode:aKeyCode character:aChar safeModifierFlags:aModifierFlags];
}

+ (instancetype)getHotKeyForKeyCode:(UInt16)aKeyCode character:(unichar)aChar safeModifierFlags:(NSUInteger)aModifierFlags {
    // Convert Carbon modifiers
	if (aModifierFlags < (1 << (rightControlKeyBit + 1))) {
        aModifierFlags = NDCocoaModifierFlagsForCarbonModifierFlags(aModifierFlags);
	}

    if (aChar == 0) {
		return [self getHotKeyForKeyCode:aKeyCode modifierFlags:aModifierFlags];
    } else {
        return [self getHotKeyForKeyCharacter:aChar modifierFlags:aModifierFlags];
    }
    
}

@end