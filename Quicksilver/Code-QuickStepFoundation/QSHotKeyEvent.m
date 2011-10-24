//
// QSHotKeyEvent.m
// Quicksilver
//
// Created by Alcor on 8/16/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "QSHotKeyEvent.h"
#import "CGSPrivate.h"

/*
 * cocoaModifierFlagsToCarbonModifierFlags()
 */
unsigned int carbonModifierFlagsToCocoaModifierFlags( unsigned int aModifierFlags ) {
	unsigned int theCocoaModifierFlags = 0;
	if (aModifierFlags & shiftKey)
		theCocoaModifierFlags |= NSShiftKeyMask;
    if (aModifierFlags & alphaLock)
		theCocoaModifierFlags |= NSAlphaShiftKeyMask;
	if (aModifierFlags & controlKey)
		theCocoaModifierFlags |= NSControlKeyMask;
	if (aModifierFlags & optionKey)
		theCocoaModifierFlags |= NSAlternateKeyMask;
	if (aModifierFlags & cmdKey)
		theCocoaModifierFlags |= NSCommandKeyMask;
    if (aModifierFlags & kEventKeyModifierFnMask)
        theCocoaModifierFlags |= NSFunctionKeyMask;
    if (aModifierFlags & kEventKeyModifierNumLockMask)
        theCocoaModifierFlags |= NSNumericPadKeyMask;
	return theCocoaModifierFlags;
}

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

- (void)setIdentifier:(NSString *)anIdentifier {
	[hotKeyDictionary setObject:self forKey:anIdentifier];
}

+ (QSHotKeyEvent *)hotKeyWithIdentifier:(NSString *)anIdentifier {
	return [hotKeyDictionary objectForKey:anIdentifier];
}
+ (QSHotKeyEvent *)hotKeyWithDictionary:(NSDictionary *)dict {
	if (![dict objectForKey:@"keyCode"] || ![dict objectForKey:@"modifiers"]) {
		return nil;
	}

	return (QSHotKeyEvent *)[self getHotKeyForKeyCode:[[dict objectForKey:@"keyCode"] shortValue] character:[[dict objectForKey:@"character"] characterAtIndex:0] modifierFlags:[[dict objectForKey:@"modifiers"] unsignedIntValue]];
}
@end

@implementation NDHotKeyEvent (QSMods)

+ (id)getHotKeyForKeyCode:(unsigned short)aKeyCode character:(unichar)aChar carbonModifierFlags:(unsigned int)aModifierFlags {
	return [self getHotKeyForKeyCode:aKeyCode character:aChar modifierFlags:carbonModifierFlagsToCocoaModifierFlags(aModifierFlags)];
}

+ (id)getHotKeyForKeyCode:(unsigned short)aKeyCode character:(unichar)aChar safeModifierFlags:(unsigned int)aModifierFlags {
	if (aModifierFlags< (1 << (rightControlKeyBit+1) )) //Carbon Modifiers
		return [self getHotKeyForKeyCode:aKeyCode character:aChar carbonModifierFlags:aModifierFlags];
	else
		return [self getHotKeyForKeyCode:aKeyCode character:aChar modifierFlags:aModifierFlags];

}

- (BOOL)setTarget:(id)aTarget selector:(SEL)aSelector { return [self setTarget:aTarget selectorReleased:(SEL)0 selectorPressed:aSelector]; }

@end
