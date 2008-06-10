/*
 *  NDHotKeyControl.m
 *  NDHotKeyEvent
 *
 *  Created by Nathan Day on Wed Mar 05 2003.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "NDHotKeyControl.h"
#import "NDHotKeyEvent.h"

/*
 * class implementation NDHotKeyControl
 */
@implementation NDHotKeyControl

/*
 * -initWithFrame:
 */
- (id)initWithFrame:(NSRect)aFrame
{
    if (( self = [super initWithFrame:aFrame] ))
	 {
		 [self setEditable:NO];
		 requiresModifierKeys = YES;
   }
    return self;
}

/*
 * -initWithCoder:
 */
- (id)initWithCoder:(NSCoder *)aCoder
{
	if (( self = [super initWithCoder:aCoder] ))
	{
		[self setEditable:NO];
		requiresModifierKeys = YES;
	}
	return self;
}

/*
 * -keyCode
 */
- (unsigned short)keyCode
{
	return keyCode;
}

/*
 * -character
 */
- (unichar)character
{
	return character;
}

/*
 * -modifierFlags
 */
- (unsigned long)modifierFlags
{
	return modifierFlags;
}

/*
 * -performKeyEquivalent:
 */
- (BOOL)performKeyEquivalent:(NSEvent*)anEvent
{
	[self keyDown:anEvent];
	return YES;
}

/*
 * -keyDown:
 */
- (void)keyDown:(NSEvent *)theEvent
{
	unsigned long		theModifierFlags = [theEvent modifierFlags];
	unichar				theChar = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
	theModifierFlags &= (NSShiftKeyMask|NSControlKeyMask|NSAlternateKeyMask|NSCommandKeyMask);

	if( (theModifierFlags != 0 || !requiresModifierKeys || theChar > 255) && theChar != 0 )
	{
		keyCode = [theEvent keyCode];
		modifierFlags = theModifierFlags;
		character = theChar;

		[self setStringValue:stringForKeyCodeAndModifierFlags( keyCode, character, modifierFlags )];
		[self performClick:self];
	}
}

/*
 * -hotKeyEvent
 */
- (NDHotKeyEvent *)hotKeyEvent
{
	return [NDHotKeyEvent getHotKeyForKeyCode:[self keyCode] character:[self character] modifierFlags:[self modifierFlags]];

}

- (void)setRequiresModifierKeys:(BOOL)aFlag
{
	requiresModifierKeys = aFlag;
}

- (BOOL)requiresModifierKeys
{
	return requiresModifierKeys;
}

@end

