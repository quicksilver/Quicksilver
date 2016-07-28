/*
	NDKeyboardLayout.h

	Created by Nathan Day on 01.18.10 under a MIT-style license. 
	Copyright (c) 2010 Nathan Day

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
	@header NDKeyboardLayout.h
	@abstract Header file for NDKeyboardLayout
	@author Nathan Day
 */

#import <Cocoa/Cocoa.h>
#import <CoreServices/CoreServices.h>
#import <Carbon/Carbon.h>

struct ReverseMappingEntry;

/*!
	@function NDCocoaModifierFlagsForCarbonModifierFlags
	Convert Carbon modifer flags to Cocoa modifier flags.
	@param modifierFlags one or more of the flags <tt>shiftKey</tt>, <tt>controlKey</tt>, <tt>optionKey</tt>, <tt>cmdKey</tt>
 */
NSUInteger NDCocoaModifierFlagsForCarbonModifierFlags( UInt32 modifierFlags );
/*!
	@function NDCarbonModifierFlagsForCocoaModifierFlags
	Convert Cocoa modifer flags to Carbon modifier flags.
	@param modifierFlags ￼one or more of the flags <tt>NSShiftKeyMask</tt>, <tt>NSControlKeyMask</tt>, <tt>NSAlternateKeyMask</tt>, <tt>NSCommandKeyMask</tt>
 */
UInt32 NDCarbonModifierFlagsForCocoaModifierFlags( NSUInteger modifierFlags );

/*!
	@class NDKeyboardLayout
	@abstract Class for translating between key codes and key characters.
	@discussion The key code for each key character can change between hardware and with localisation, <tt>NDKeyboardLayout</tt> handles translation between key codes and key characters as well as for generating strings for display purposes.
	@helps Used by <tt>NDHotKeyEvent</tt>.
 */
@interface NDKeyboardLayout : NSObject
{
@private
	CFDataRef					keyboardLayoutData;
	struct ReverseMappingEntry	* mappings;
	NSUInteger					numberOfMappings;
}

/*!
	@method keyboardLayout
	Get a keyboard layout for the current keyboard
 */
+ (id)keyboardLayout;

/*!
	@method keyboardLayout
	Get a keyboard layout for the most recently used ASCII-capable keyboard
 */
+ (id)mostRecentlyUsedASCIICapableKeyboardLayout;
/*!
	@method init
	initialise a keyboard layout for the current keyboard, if that fails a keyboard layout for one of the languages
	returned from <tt>[NSLocale preferredLanguages]</tt> is attempted and if finally if that fails a keyboard layout
	for the most recently used ASCII-capable keyboard is created. If that fails then this method returns <tt>nil</tt>.
 */
- (id)init;
/*!
	@method initWithLanguage:
	@abstract initialise a keyboard layout.
	@discussion Initialises a KeyboardLayout with an <tt>TISInputSourceRef</tt> for the supplied language.
 */
- (id)initWithLanguage:(NSString *)langauge;
/*!
	@method initWithInputSource:
	@abstract initialise a keyboard layout.
	@discussion Initialises a KeyboardLayout with an <tt>TISInputSourceRef</tt>, this method is called with the result from <tt>initWithInputSource:TISCopyCurrentKeyboardInputSource()</tt>.
 */
- (id)initWithInputSource:(TISInputSourceRef)source;

/*!
	@method stringForCharacter:modifierFlags:
	@abstract Get a string for display purposes. 
	@discussion <tt>stringForCharacter:modifierFlags:</tt> returns a string that can be displayed to the user, For example command-z would produce &#x2318;Z, shift-T would produce &#x21E7;T.
	@param character The unmodified character on the keyboard.
	@param modifierFlags Modifier flags <tt>NSControlKeyMask</tt>, <tt>NSAlternateKeyMask</tt>, <tt>NSShiftKeyMask</tt>, <tt>NSCommandKeyMask</tt> and <tt>NSNumericPadKeyMask</tt>.
 */
- (NSString*)stringForCharacter:(unichar)character modifierFlags:(UInt32)modifierFlags;
/*!
	@method stringForKeyCode:modifierFlags:
	@abstract Get a string for display purposes. 
	@discussion <tt>stringForKeyCode:modifierFlags:</tt> returns a string that can be displayed to the user. This method is called by <tt>stringForCharacter::modifierFlags</tt> and is problem more useful most of the time.
	@param keyCode A value specifying the virtual key code that is to be translated. For ADB keyboards, virtual key codes are in the range from 0 to 127.
	@param modifierFlags Modifier flags <tt>NSControlKeyMask</tt>, <tt>NSAlternateKeyMask</tt>, <tt>NSShiftKeyMask</tt>, <tt>NSCommandKeyMask</tt> and <tt>NSNumericPadKeyMask</tt>.
 */
- (NSString*)stringForKeyCode:(UInt16)keyCode modifierFlags:(UInt32)modifierFlags;
/*!
	@method characterForKeyCode:
	@abstract Get the key character for a given key code.
	@discussion The character returned is the unmodified version on the keyboard.
	@param keyCode A value specifying the virtual key code that is to be translated. For ADB keyboards, virtual key codes are in the range from 0 to 127.
	@result The character for the unmodified version of the key.
 */
- (unichar)characterForKeyCode:(UInt16)keyCode;
/*!
	@method keyCodeForCharacter:numericPad:
	@abstract Get the key code for a given key character.
	@discussion The character pass in must  be the unshifter character for the key, for example to get the key code for the '?' on keyboards where you type shift-/ to get '?' you should pass in the character '/" 
	@param character The unmodified character on the keyboard.
	@param numericPad For the keycode of a key on the keypad where the same character is also on the main keyboard this flag needs to be <tt>YES</tt>.
 */
- (UInt16)keyCodeForCharacter:(unichar)character numericPad:(BOOL)numericPad;
/*!
	@method keyCodeForCharacter:
	@abstract Get the key code for a given key character.
	@discussion Calls <tt>keyCodeForCharacter:numericPad:</tt> with the keypad flag set to <tt>NO</tt>
	@param character The unmodified character on the keyboard.
	@result A value specifying the virtual key code that is to be translated. For ADB keyboards, virtual key codes are in the range from 0 to 127.
 */
- (UInt16)keyCodeForCharacter:(unichar)character;

@end
