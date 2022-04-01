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
NSUInteger carbonModifierFlagsToCocoaModifierFlags( NSUInteger aModifierFlags ) {
	NSUInteger theCocoaModifierFlags = 0;
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

+ (QSHotKeyEvent *)hotKeyWithIdentifier:(NSString *)anIdentifier {
	return [hotKeyDictionary objectForKey:anIdentifier];
}

@end
