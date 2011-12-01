/*
	NDHotKeyControl.h

	Created by Nathan Day on 29.03.08 under a MIT-style license.
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

/*!
	@header NDHotKeyControl.h
	@abstract Header file for a subclass of NSTextField for getting hot key combinations from the user.
	@discussion The <tt>NDHotKeyControl</tt> can be used to get a  <tt>NDHotKeyEvent</tt> for the last key combination pressed by the user.
	@updated 2010-01-18
 */

#import <AppKit/AppKit.h>

@class	NDHotKeyEvent;

/*!
	@class NDHotKeyControl
	@abstract Subclass of NSTextField for getting hot key combinations from the user.
	@discussion The <tt>NDHotKeyControl</tt> can be used to get a  <tt>NDHotKeyEvent</tt> for the last key combination pressed by the user.
 */
@interface NDHotKeyControl : NSTextField
{
@private
	UInt16				keyCode;
	NSUInteger			modifierFlags;
	BOOL				requiresModifierKeys,
						readyForEvent,
						stayReadyForEvent;
	id					lastReadyForEventSender;
}

- (IBAction)readyForHotKeyEventChanged:(id)sender;
/*!
	@method keyCode
	@abstract Get key code.
	@discussion Returns the key code for the last key combination the user pressed while the reciever was active.
	@result A <tt>UInt16</tt> containing key code.
 */
- (UInt16)keyCode;

/*!
	@method character
	@abstract Get unicode character.
	@discussion Returns the unicode character for the last key combination the user pressed while the reciever was active.
	@result A <tt>unichar</tt> containing character.
 */
- (unichar)character;

/*!
	@method modifierFlags
	@abstract Get modifer flags.
	@discussion Returns the modifer flags for the last key combination the user pressed while the reciever was active.
	@result A <tt>unsigned long</tt> containing modifer flags.
 */
- (NSUInteger)modifierFlags;

/*!
	@method hotKeyEvent
	@abstract Get <tt>NDHotKeyEvent</tt>
	@discussion Returns the <tt>NDHotKeyEvent</tt> instance for the last key combination the user pressed while the reciever was active. The <tt>NDHotKeyEvent</tt> returned will either be one that has already been created or a newly created one otherwise.
	@result A <tt>NDHotKeyEvent</tt> for the hot key event.
 */
- (NDHotKeyEvent *)hotKeyEvent;

/*!
	@method setRequiresModifierKeys:
	@abstract Set whether hot keys entered need modifiers keys.
	@discussion This does not include function key which do not require modifier keys no matter what the value you pass for the argument <tt><i>flag</i></tt>
	@param flag If <tt>NO</tt> then the reciever only accepts hot keys combination containing modifer keys.
 */
- (void)setRequiresModifierKeys:(BOOL)flag;
/*!
	@method requiresModifierKeys
	@abstract Returns whether hot keys entered need modifiers keys.
	@discussion This does not include key which do not require modifier keys no matter what the value is returned.
	@result If <tt>NO</tt> then the reciever only accepts hot keys combination containing modifer keys.
 */
- (BOOL)requiresModifierKeys;

/*!
	@method setReadyForHotKeyEvent:
	@abstract Set up the control to accept input
	@discussion Setting <tt>readyForHotKeyEvent</tt> to <tt>YES</tt> will disable all Hot Key Events and then prepare <tt>NDHotKeyControl</tt> for keyboard input. Setting <tt>readyForHotKeyEvent</tt> to <tt>NO</tt> will re-enables all Hot Key Events and then stops <tt>NDHotKeyControl</tt> for accepting keyboard input.
	@param flag <#description#>
 */
- (void)setReadyForHotKeyEvent:(BOOL)flag;
/*!
	@method readyForHotKeyEvent
	@abstract Is the control set up to accept input
	@discussion Returns the current state of <tt>readyForHotKeyEvent</tt> as set by the method <tt>setReadyForHotKeyEvent:</tt>.
 */
- (BOOL)readyForHotKeyEvent;
/*!
	@method setStayReadyForEvent:
	@abstract Will the control remain continually active.
	@discussion By default <tt>NDHotKeyControl</tt> will accept one key and then call <tt>[self setReadyForHotKeyEvent:NO]</tt>, <tt>setStayReadyForEvent:</tt> allows you to change this behaviour so that <tt>NDHotKeyControl</tt> will continue accepting keys until it is manually deactivated.
 */
- (void)setStayReadyForEvent:(BOOL)flag;
/*!
	@method stayReadyForEvent
	@abstract Will the control remain continually active.
	@discussion By default <tt>NDHotKeyControl</tt> will accept one key and then call <tt>[self setReadyForHotKeyEvent:NO]</tt>, if <tt>stayReadyForEvent</tt> returns <tt>YES</tt>, <tt>NDHotKeyControl</tt> will continue accepting keys until it is manually deactivated.
 */
- (BOOL)stayReadyForEvent;


@end
