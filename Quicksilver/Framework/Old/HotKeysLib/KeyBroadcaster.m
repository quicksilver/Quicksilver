//
//  KeyBroadcaster.m
//  HotKeyTest
//
//  Created by Quentin D. Carnicelli on Tue Jun 18 2002.
//  Copyright (c) 2001 Subband inc.. All rights reserved.
//

#import "KeyBroadcaster.h"

#import <Carbon/Carbon.h>

NSString* KeyBraodcasterKeyEvent = @"KeyBraodcasterKeyEvent";

@implementation KeyBroadcaster

- (void)_broadcastKeyCode: (short)keycode andModifiers: (long)modifiers
{
	NSNumber* keycodeObj = [NSNumber numberWithShort: keycode];
	NSNumber* modifiersObj = [NSNumber numberWithLong: modifiers];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									keycodeObj, @"KeyCode",
									modifiersObj, @"Modifiers",
									nil];
	
	[[NSNotificationCenter defaultCenter]
		postNotificationName: KeyBraodcasterKeyEvent
		object: self
		userInfo: userInfo];
}

- (void)keyDown: (NSEvent*)event
{
	short keyCode;
	long modifiers;
	
	keyCode = [event keyCode];
	modifiers = [event modifierFlags];

	modifiers = [KeyBroadcaster cocoaToCarbonModifiers: modifiers];

	[self _broadcastKeyCode: keyCode andModifiers: modifiers];
}

- (BOOL)performKeyEquivalent: (NSEvent*)event
{
	[self keyDown: event];

	return YES;
}

+ (long)cocoaToCarbonModifiers: (long)cocoaModifiers
{
	static long cocoaToCarbon[6][2] =
	{
		{ NSCommandKeyMask, cmdKey},
		{ NSAlternateKeyMask, optionKey},
		{ NSControlKeyMask, controlKey},
		{ NSShiftKeyMask, shiftKey},
		//{ NSAlphaShiftKeyMask, alphaLock }, //Ignore this?
	};

	long carbonModifiers = 0;
	int i;
	
	for( i = 0 ; i < 6; i++ )
		if( cocoaModifiers & cocoaToCarbon[i][0] )
			carbonModifiers += cocoaToCarbon[i][1];
	
	return carbonModifiers;
}


@end
