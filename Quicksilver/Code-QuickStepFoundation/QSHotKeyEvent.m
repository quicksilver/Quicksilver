//
// QSHotKeyEvent.m
// Quicksilver
//
// Created by Alcor on 8/16/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "QSHotKeyEvent.h"
#import "CGSPrivate.h"

@interface NDHotKeyEvent ()
- (instancetype)initWithKeyCharacter:(unichar)aKeyCharacter modifierFlags:(NSUInteger)aModifierFlags target:(id)aTarget selector:(SEL)aSelector;
@end

static NSMutableDictionary *hotKeyDictionary;

@interface QSHotKeyEvent () {
	NSString *_identifier;
}
@end

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

+ (instancetype)hotKeyWithIdentifier:(NSString *)anIdentifier {
	@synchronized (hotKeyDictionary) {
		return [hotKeyDictionary objectForKey:anIdentifier];
	}
}

+ (instancetype)hotKeyWithDictionary:(NSDictionary *)dict {
	if (![dict objectForKey:@"keyCode"] || ![dict objectForKey:@"modifiers"]) {
		return nil;
	}

	UInt16 keyCode = [[dict objectForKey:@"keyCode"] shortValue];
	NSUInteger modifiers = [[dict objectForKey:@"modifiers"] unsignedIntegerValue];
	//    unichar character = [[dict objectForKey:@"character"] characterAtIndex:0];

	return [self getHotKeyForKeyCode:keyCode modifierFlags:modifiers];
}

- (instancetype)initWithKeyCharacter:(unichar)keyCharacter modifierFlags:(NSUInteger)modifer target:(id)target selector:(SEL)selector {
	self = [super initWithKeyCharacter:keyCharacter modifierFlags:modifer target:target selector:selector];
	if (!self) return nil;

	_identifier = [NSString uniqueString];

	return self;
}

- (NSString *)identifier {
	@synchronized (hotKeyDictionary) {
		NSArray *array = [hotKeyDictionary allKeysForObject:self];
		if ([array count]) return [array lastObject];
		return nil;
	}
}

- (NSArray *)identifiers {
	@synchronized (hotKeyDictionary) {
		return [hotKeyDictionary allKeysForObject:self];
	}
}

- (void)setIdentifier:(NSString *)anIdentifier {
	@synchronized (hotKeyDictionary) {
		[hotKeyDictionary setObject:self forKey:anIdentifier];
	}
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