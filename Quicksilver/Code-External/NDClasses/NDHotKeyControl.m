/*
	NDHotKeyControl.m

	Created by Nathan Day on 21.06.06 under a MIT-style license.
	Copyright (c) 2008 Nathan Day

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
 */

#import "NDHotKeyControl.h"
#import "NDHotKeyEvent.h"
#import "NDKeyboardLayout.h"

/*
 * class implementation NDHotKeyControl
 */
@implementation NDHotKeyControl

/*
 * -initWithFrame:
 */
- (id)initWithFrame:(NSRect)aFrame
{
    if ( (self = [super initWithFrame:aFrame]) != nil )
	 {
		 [self setEditable:NO];
		 requiresModifierKeys = YES;
		 readyForEvent = NO;
		 stayReadyForEvent = NO;
   }
    return self;
}

/*
 * -initWithCoder:
 */
- (id)initWithCoder:(NSCoder *)aCoder
{
	if( (self = [super initWithCoder:aCoder]) != nil )
	{
		[self setEditable:NO];
		requiresModifierKeys = YES;
		readyForEvent = NO;
		stayReadyForEvent = NO;
	}
	return self;
}

- (IBAction)readyForHotKeyEventChanged:(id)aSender
{
	if( [aSender isKindOfClass:[NSMatrix class]] )
		aSender = [aSender selectedCell];

	if( [aSender isKindOfClass:[NSButton class]] || [aSender isKindOfClass:[NSButtonCell class]] )
	{
		if( [aSender state] == NSOnState )
		{
			[self setReadyForHotKeyEvent:YES];
			lastReadyForEventSender = aSender;
			[self setStringValue:@""];
		}
		else
		{
			[self setReadyForHotKeyEvent:NO];
			lastReadyForEventSender = nil;
		}
	}
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
	return [[NDKeyboardLayout keyboardLayout] characterForKeyCode:[self keyCode]];
}

/*
 * -modifierFlags
 */
- (NSUInteger)modifierFlags
{
	return modifierFlags;
}

/*
 * -performKeyEquivalent:
 */
- (BOOL)performKeyEquivalent:(NSEvent*)anEvent
{
	BOOL		theResult = NO;
	if( [self readyForHotKeyEvent] )
	{
		[self keyDown:anEvent];
		theResult = YES;
	}
	else
		theResult = [super performKeyEquivalent:anEvent];
	return theResult;
}

/*
 * -keyDown:
 */
- (void)keyDown:(NSEvent *)anEvent
{
	NSUInteger		theModifierFlags = [anEvent modifierFlags];
	unichar			theChar = [[anEvent charactersIgnoringModifiers] characterAtIndex:0];
	theModifierFlags &= (NSShiftKeyMask|NSControlKeyMask|NSAlternateKeyMask|NSCommandKeyMask);

	if( (theModifierFlags != 0 || !requiresModifierKeys || theChar > 255) && theChar != 0 )
	{
		NDKeyboardLayout		* theKeyboardLayout = [NDKeyboardLayout keyboardLayout];

		NSParameterAssert( theKeyboardLayout != nil );

		keyCode = [anEvent keyCode];
		modifierFlags = theModifierFlags;

		[self setStringValue:[theKeyboardLayout stringForKeyCode:keyCode modifierFlags:modifierFlags]];
		[self performClick:self];
		if( ![self stayReadyForEvent] )
			[self setReadyForHotKeyEvent:NO];
	}
}

/*
 * -hotKeyEvent
 */
- (NDHotKeyEvent *)hotKeyEvent
{
	return [NDHotKeyEvent getHotKeyForKeyCode:[self keyCode] modifierFlags:[self modifierFlags]];
}

- (void)setRequiresModifierKeys:(BOOL)aFlag
{
	requiresModifierKeys = aFlag;
}

- (BOOL)requiresModifierKeys
{
	return requiresModifierKeys;
}

- (void)setReadyForHotKeyEvent:(BOOL)aFlag
{
	readyForEvent = aFlag;

	[NDHotKeyEvent setAllEnabled:!readyForEvent];
	if( readyForEvent == NO && lastReadyForEventSender )
	{
		[lastReadyForEventSender setState:NSOffState];
		lastReadyForEventSender = nil;
	}
}

- (BOOL)readyForHotKeyEvent
{
	return readyForEvent;
}

- (void)setStayReadyForEvent:(BOOL)aFlag
{
	stayReadyForEvent = aFlag;
}

- (BOOL)stayReadyForEvent
{
	return stayReadyForEvent;
}


@end

