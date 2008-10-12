/*!
	@header NDHotKeyEvent.h
	@abstract Header file for the class <tt>NDHotKeyEvent</tt>
	@discussion <p><tt>NDHotKeyEvent</tt> provides a thread safe Objective-C interface to HotKey events as well as some additional feature to key track of all the hot keys in your application.</p>

	<p><h4>Thread Saftey</h4>By default the class object <tt>NDHotKeyEvent</tt> is not thread safe as the underlying functions that it relies on are not thread safe and the mechanism for keeping track of all of the <tt>NDHotKeyEvent</tt> instances is not thread safe either. Thread saftey can be enable be defining the flag <tt>NDHotKeyEventThreadSafe</tt> before compiling.</p>
	<p>Even with the flag <tt>NDHotKeyEventThreadSafe</tt> defined instances of <tt>NDHotKeyEvent</tt> will still not be thread safe, that is, it is safe to invoke methods of different instance with different threads as well as class methods, but it is not safe to invoke methods of the same instance with different threads.</p>
	<p>The functions <tt>stringForKeyCodeAndModifierFlags</tt> and <tt>unicharForKeyCode</tt> are never thread safe.</p>
 
	<p>Created by Nathan Day on Wed Feb 26 2003.<br>
	Copyright &copy; 2002 Nathan Day. All rights reserved.</p>
 */

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

/*!
	@defined NDHotKeyEventThreadSafe
	@abstract A flag to enable thread safety.
	@discussion By default the class object <tt>NDHotKeyEvent</tt> is not thread safe. Defining the this flag will make th class methods of <tt>NDHotKeyEvent</tt> thread safe, see introduction for more details..
 */
enum
{
/*!
	@const NDHotKeyNoEvent
	@abstract A value returned from the method <tt>-[NDHotKeyEvent currentEventType]</tt>
	@discussion This value is returned if the hot key has not been pressed yet.
 */
 	NDHotKeyNoEvent = 0,
/*!
	@const NDHotKeyPressedEvent
	@abstract A value returned from the method <tt>-[NDHotKeyEvent currentEventType]</tt>
	@discussion This value is returned if hot key was pressed last.
 */
 	NDHotKeyPressedEvent,
/*!
	@const NDHotKeyReleasedEvent
	@abstract A value returned from the method <tt>-[NDHotKeyEvent currentEventType]</tt>
	@discussion This value is returned if hot key was released last.
 */
	NDHotKeyReleasedEvent
};

/*!
	@const NDHotKeyDefaultSignature
	@abstract The default signature
	@discussion This is the default signature that will be used if you start using <tt>NDHotKeyEvent</tt> without setting the signature first.
 */
extern const OSType			NDHotKeyDefaultSignature;

/*!
	@class NDHotKeyEvent
	@abstract Class to represent a HotKey
	@discussion <p>This class is a wrapper for Carbon Event HotKeys and provides some feature to key track of all the hot keys in your application. It can be used to be notified of key down as well as key up evernts and when a hot key is being taken by another object (see the protocol <tt>NDHotKeyEventTragetWillChange</tt>)</p>
 
 */
@interface NDHotKeyEvent : NSObject <NSCoding>
{
@private
	EventHotKeyRef		reference;
	unsigned short		keyCode;
	unichar				character;
	unsigned int		modifierFlags;
	int					currentEventType;
	id					target;
	SEL					selectorReleased,
						selectorPressed;
	struct
	{
		unsigned			individual		: 1;
		unsigned			collective		: 1;
	}						isEnabled;
}

/*!
	@method install
	@abstract Install the event key handler
	@discussion <tt>install</tt> is called before hot keys can be used. You normally don't need to invoke this method your self but in a multithreaded you might want to invoke this method before creating any threads. <tt>install</tt> is designed to be thread safe but the effects of calling Apples <tt>InstallEventHandler()</tt> funtion from anything other than the main thread is unknown.
	@result Returns true if <tt>install</tt> succeeded.
 */
+ (BOOL)install;

	/*!
	@method setSignature:
	@abstract Set the hot key signature for this application
	@discussion This should only be called once, before trying to enable any hot keys.
	@param signature The four char code signature to identify all hot keys for this application, could your applications signature.
 */
+ (void)setSignature:(OSType)signature;

/*!
	@method signature
	@abstract Get the hot key signature for this application
	@discussion Used to identify the hot key handler for this application.
	@result The four char code signature.
 */
+ (OSType)signature;

/*!
	@method setAllEnabled:
	@abstract Set enabled for all instances of <tt>NDHotKeyEvent</tt>
	@discussion Used to enable or disable all hot keys. This method is not the same as sending the message <tt>setEnabled:</tt> to every single <tt>NDHotKeyEvent</tt> instance. Enabling with this method only enables the hot keys that where enable prior to using this method to disable all hot keys.
	@param flag <tt>YES</tt> to enable, <tt>NO</tt> to disable.
	@result Returns <tt>YES</tt> if succesful.
 */
+ (BOOL)setAllEnabled:(BOOL)flag;

/*!
	@method isEnabledKeyCode:modifierFlags:
	@abstract Is hot key combination enabled.
	@abstract Test to see if a key code and modifier flaf combination are enabled.
	@param keyCode The key code used by the keyboard, can vary across hardware.
	@param modifierFlags The modifer flags, ( <tt>NSCommandKeyMask</tt>, <tt>NSControlKeyMask</tt>, <tt>NSAlternateKeyMask</tt>, <tt>NSShiftKeyMask</tt> ).
	@result Returns <tt>YES</tt> if enabled.
 */
+ (BOOL)isEnabledKeyCode:(unsigned short)keyCode modifierFlags:(unsigned int)modifierFlags;

/*!
	@method getHotKeyForKeyCode:modifierFlags:
	@abstract Get an <tt>NDHotKeyEvent</tt>
	@discussion Gets a <tt>NDHotKeyEvent</tt> for the supplied key code and modifer flags by either finding one that has already been created or by creating a new one..
	@param keyCode The key code used by the keyboard, can vary across hardware.
	@param aChar The character, used for display purposes only.
	@param modifierFlags The modifer flags, ( <tt>NSCommandKeyMask</tt>, <tt>NSControlKeyMask</tt>, <tt>NSAlternateKeyMask</tt>, <tt>NSShiftKeyMask</tt> ).
	@result The <tt>NDHotKeyEvent</tt> obejct or nil if failure.
 */
+ (NDHotKeyEvent *)getHotKeyForKeyCode:(unsigned short)keyCode character:(unichar)aChar modifierFlags:(unsigned int)modifierFlags;
/*!
	@method findHotKeyForKeyCode:modifierFlags:
	@abstract Find an <tt>NDHotKeyEvent</tt>
	@discussion Finds the <tt>NDHotKeyEvent</tt> for the supplied key code and modifer flags.
	@param keyCode The key code used by the keyboard, can vary across hardware.
	@param modifierFlags The modifer flags, ( <tt>NSCommandKeyMask</tt>, <tt>NSControlKeyMask</tt>, <tt>NSAlternateKeyMask</tt>, <tt>NSShiftKeyMask</tt> ).
	@result The <tt>NDHotKeyEvent</tt> obejct or nil if none found.
 */
+ (NDHotKeyEvent *)findHotKeyForKeyCode:(unsigned short)keyCode modifierFlags:(unsigned int)modifierFlags;

/*!
	@method hotKeyWithEvent:
	@abstract Get a <tt>NDHotKeyEvent</tt> object.
	@discussion Returns a new hot key for the supplied event, if there is already a hot key for the supplied key code and modifer flags then nil is returned.
	@param event The event generated from the user presssing the desired hot key combination.
	@result An new <tt>NDHotKeyEvent</tt> or nil if failure.
 */
+ (id)hotKeyWithEvent:(NSEvent *)event;
/*!
	@method hotKeyWithEvent:target:selector:
	@abstract Get a <tt>NDHotKeyEvent</tt> object.
	@discussion Returns a new hot key for the supplied event, if there is already a hot key for the supplied key code and modifer flags then nil is returned.
	@param event The event generated from the user presssing the desired hot key combination.
	@param target The target of hot key event.
	@param selector The selector sent when hot key is released
	@result An new <tt>NDHotKeyEvent</tt> or nil if failure.
 */
+ (id)hotKeyWithEvent:(NSEvent *)event target:(id)target selector:(SEL)selector;
/*!
	@method hotKeyWithKeyCode:character:modifierFlags:
	@abstract Get a <tt>NDHotKeyEvent</tt> object.
	@discussion Returns a new hot key for the supplied hot key combination, if there is already a hot key for the supplied key code and modifer flags then nil is returned.
	@param keyCode The key code used by the keyboard, can vary across hardware.
	@param aChar The character, used for display purposes only.
	@param modifierFlags The modifer flags, ( <tt>NSCommandKeyMask</tt>, <tt>NSControlKeyMask</tt>, <tt>NSAlternateKeyMask</tt>, <tt>NSShiftKeyMask</tt> ).
	@result An new <tt>NDHotKeyEvent</tt> or nil if failure.
 */
+ (id)hotKeyWithKeyCode:(unsigned short)keyCode character:(unichar)aChar modifierFlags:(unsigned int)modifer;

/*!
	@method hotKeyWithKeyCode:character:modifierFlags:target:selector:
	@abstract Get a <tt>NDHotKeyEvent</tt> object.
	@discussion Returns a new hot key for the supplied hot key combination and target object and selector, if there is already a hot key for the supplied key code and modifer flags then nil is returned.
	@param keyCode The key code used by the keyboard, can vary across hardware.
	@param aChar The character, used for display purposes only.
	@param modifierFlags The modifer flags, ( <tt>NSCommandKeyMask</tt>, <tt>NSControlKeyMask</tt>, <tt>NSAlternateKeyMask</tt>, <tt>NSShiftKeyMask</tt> ).
	@param target The target of hot key event.
	@param selector The selector sent when hot key is released
	@result A new <tt>NDHotKeyEvent</tt>
 */
+ (id)hotKeyWithKeyCode:(unsigned short)keyCode character:(unichar)aChar modifierFlags:(unsigned int)modifer target:(id)target selector:(SEL)selector;

/*!
	@method initWithPropertyList:
	@abstract creates a <tt>NDHotKeyEvent</tt> with a property list.
	@discussion This can be used for archiving purposes, but it is possible that it will not work if the users keyboard is changed, ie between machines.
	@param propertyList A property list object
	@result A initialized <tt>NDHotKeyEvent</tt>
 */
+ (id)hotKeyWithWithPropertyList:(id)propertyList;
/*!
	@method initWithKeyCode:character:modifierFlags:target:selector:
	@abstract Initialize a <tt>NDHotKeyEvent</tt> object.
	@discussion Initialize the reciever with the supplied hot key combination contained with the event <tt>event</tt> and target object and selector, if there is already a hot key for the supplied event then nil is returned.
	@param event The key code used by the keyboard, can vary across hardware.
	@result A initialized <tt>NDHotKeyEvent</tt>
 */
- (id)initWithEvent:(NSEvent *)event;
/*!
	@method initWithKeyCode:character:modifierFlags:target:selector:
	@abstract Initialize a <tt>NDHotKeyEvent</tt> object.
	@discussion Initialize the reciever with the supplied hot key combination contained with the event <tt>event</tt> and target object and selector, if there is already a hot key for the supplied event then nil is returned.
	@param keyCode The key code used by the keyboard, can vary across hardware.
	@param aChar The character, used for display purposes only.
	@param modifierFlags The modifer flags, ( <tt>NSCommandKeyMask</tt>, <tt>NSControlKeyMask</tt>, <tt>NSAlternateKeyMask</tt>, <tt>NSShiftKeyMask</tt> ).
	@param target The target of hot key event.
	@param selector The selector sent when hot key is released
	@result A initialized <tt>NDHotKeyEvent</tt>
 */
- (id)initWithEvent:(NSEvent *)event target:(id)target selector:(SEL)selector;
/*!
	@method initWithKeyCode:character:modifierFlags:target:selector:
	@abstract Initialize a <tt>NDHotKeyEvent</tt> object.
	@discussion Initialize the reciever with the supplied hot key combination and target object and selector, if there is already a hot key for the supplied key code and modifer flags then nil is returned.
	@param keyCode The key code used by the keyboard, can vary across hardware.
	@param aChar The character, used for display purposes only.
	@param modifierFlags The modifer flags, ( <tt>NSCommandKeyMask</tt>, <tt>NSControlKeyMask</tt>, <tt>NSAlternateKeyMask</tt>, <tt>NSShiftKeyMask</tt> ).
	@param target The target of hot key event.
	@param selector The selector sent when hot key is released
	@result A initialized <tt>NDHotKeyEvent</tt>
 */
- (id)initWithKeyCode:(unsigned short)keyCode character:(unichar)aChar modifierFlags:(unsigned int)modifer target:(id)target selector:(SEL)selector;

/*!
	@method initWithKeyCode:character:modifierFlags
	@abstract Initialize a <tt>NDHotKeyEvent</tt> object.
	@discussion Initialize the reciever with the supplied hot key combination, if there is already a hot key for the supplied key code and modifer flags then nil is returned.
	@param keyCode The key code used by the keyboard, can vary across hardware.
	@param aChar The character, used for display purposes only.
	@param modifierFlags The modifer flags, ( <tt>NSCommandKeyMask</tt>, <tt>NSControlKeyMask</tt>, <tt>NSAlternateKeyMask</tt>, <tt>NSShiftKeyMask</tt> ).
	@result A initialized <tt>NDHotKeyEvent</tt>
 */
- (id)initWithKeyCode:(unsigned short)keyCode character:(unichar)aChar modifierFlags:(unsigned int)modifer;

/*!
	@method initWithPropertyList:
	@abstract Initializes the reciever with a property list.
	@discussion This can be used for archiving purposes, but it is possible that it will not work if the users keyboard is changed, ie between machines. The following properties are initialised
	<ul>
		<li>Key Code</li>
		<li>Character</li>
		<li>Modifier Flags</li>
		<li>Selector Pressed</li>
		<li>Selector Released</li>
	</ul>
	@param propertyList A property list object
	@result A initialized <tt>NDHotKeyEvent</tt>
  */
- (id)initWithPropertyList:(id)propertyList;
/*!
	@method propertyList
	@abstract Returns a property list for the reciever.
	@discussion This can be used for archiving purposes, but it is possible that it will not work if the users keyboard is changed, ie between machines. The property list returned contains the following properties;
	<ul>
		<li>Key Code</li>
		<li>Character</li>
		<li>Modifier Flags</li>
		<li>Selector Pressed</li>
		<li>Selector Released</li>
	</ul>
	@result The property list object.
  */
- (id)propertyList;

/*!
	@method initWithCoder:
	@abstract Initializes a newly allocated instance from data in <tt>decoder</tt>.
	@discussion Decodes the following properties of a <tt>NDHotKeyEvent</tt>;
	<ul>
		<li>Key Code</li>
		<li>Character</li>
		<li>Modifier Flags</li>
		<li>Selector Pressed</li>
		<li>Selector Released</li>
	</ul>
	Will use Keyed Coding if <code>[<i>decoder</i> allowsKeyedCoding] == YES</code>.
	@param decoder A subclass of <tt>NSCoder</tt>
	@result A initialized <tt>NDHotKeyEvent</tt>
 */
- (id)initWithCoder:(NSCoder *)decoder;

/*!
	@method encodeWithCoder:
	@abstract Encodes the receiver using <tt>encoder</tt>
	@discussion Encodes the following properties of a <tt>NDHotKeyEvent</tt>;
	<ul>
		<li>Key Code</li>
		<li>Character</li>
		<li>Modifier Flags</li>
		<li>Selector Pressed</li>
		<li>Selector Released</li>
	</ul>
	Will use Keyed Coding if <code>[<i>encoder</i> allowsKeyedCoding] == YES</code>.
	@param encoder A subclass of <tt>NSCoder</tt>.
 */
- (void)encodeWithCoder:(NSCoder *)encoder;

/*!
	@method setEnabled:
	@abstract Set the hot key enabled or disable.
	@discussion <tt>setEnabled:</tt> registers or unregisters the recievers hot key combination.
	@param flag <tt>YES</tt> to enable, <tt>NO</tt> to disable.
	@result Returns <tt>YES</tt> if successful
 */
- (BOOL)setEnabled:(BOOL)flag;

/*!
	@method isEnabled
	@abstract Find out if a hot key is enabled.
	@discussion Returns <tt>YES</tt> if the hot key is registered.
	@result <tt>YES</tt> if enabled.
 */
- (BOOL)isEnabled;

/*!
	@method target
	@abstract Get the hot key event target.
	@discussion Returns the object that is sent the key pressed and key released hot key events, see the methods <tt>-selector</tt>, <tt>-selectorReleased</tt> and <tt>selectorPressed</tt>.
	@result The target object.
 */
- (id)target;

/*!
	@method selector
	@abstract The selector for a key released event.
	@discussion This is the selector sent when the hot key combination for the reciever is released. This is the same selector has returned from the method <tt>[NDHotKeyEvent selectorReleased]</tt>
	@result The method selector.
 */
- (SEL)selector;

/*!
	@method selectorReleased
	@abstract The selector for a key released event.
	@discussion This is the selector sent when the hot key combination for the reciever is released. This is the same selector has returned from the method <tt>[NDHotKeyEvent selector]</tt>
	@result The method selector.
 */
- (SEL)selectorReleased;

/*!
	@method selectorPressed
	@abstract The selector for a key pressed event.
	@discussion This is the selector sent when the hot key combination for the reciever is pressed.
	@result The method selector.
 */
- (SEL)selectorPressed;

/*!
	@method currentEventType
	@abstract Get the current hot key event type.
	@discussion This value returns what event last occured. Can be used in your target when it is sent a event message to find out what event occured, possible values are
	<blockquote>
		<table border = "1"  width = "90%">
			<thead><tr><th>Value</th><th>Description</th></tr></thead>
			<tr><td align = "center"><tt>NDHotKeyNoEvent</tt></td><td>The hot key has not been pressed yet.</td></tr>
			<tr><td align = "center"><tt>NDHotKeyPressedEvent</tt></td><td>The hot key was pressed last.</td></tr>
			<tr><td align = "center"><tt>NDHotKeyReleasedEvent</tt></td><td>The hot key was released last.</td></tr>
		</table>
	</blockquote>
	@result The last event type.
 */
- (int)currentEventType;

/*!
	@method setTarget:selector:
	@abstract Set the hot key target.
	@discussion Set the target object and selector to be sent when the hot key is released.
	@param target The traget object.
	@param selector The selector.
	@result returns <tt>YES</tt> if successful.
 */
- (BOOL)setTarget:(id)target selector:(SEL)selector;

/*!
	@method setTarget:selectorReleased:selectorPressed:
	@abstract Set the hot key target.
	@discussion Set the target object and selector to be sent when the hot key is pressed and wehn it is released.
	@param target The traget object.
	@param selectorReleased The key released selector.
	@param selectorPressed The key pressed selector.
	@result returns <tt>YES</tt> if successful.
 */
- (BOOL)setTarget:(id)target selectorReleased:(SEL)selectorReleased selectorPressed:(SEL)selectorPressed;

/*!
	@method performHotKeyReleased
	@abstract Invoke the target with the release selector.
	@discussion Use to send the selector for a release event, though this method can be called by you.
 */
- (void)performHotKeyReleased;

/*!
	@method performHotKeyPressed
	@abstract Invoke the target with the press selector.
	@discussion Use to send the selector for a presse event, though this method can be called by you.
 */
- (void)performHotKeyPressed;

/*!
	@method keyCode
	@abstract Get the hot key key code.
	@discussion The key code for the hot key, this is hardware specific.
	@result The key code.
 */
- (unsigned short)keyCode;

/*!
	@method character
	@abstract Get the hot key character.
	@discussion This is the character for the key code, without modifier keys. The character is for display purposes only and dose not determine the key code.
	@result A uni code character.
 */
- (unichar)character;

/*!
	@method modifierFlags
	@abstract Get the hot key modifer key flags.
	@discussion The <tt>modifierFlags</tt> can be a bitwise and combination of <tt>NSControlKeyMask</tt>, <tt>NSAlternateKeyMask</tt>, <tt>NSShiftKeyMask</tt>, and <tt>NSCommandKeyMask</tt>.
	@result The modifer key flags.
 */
- (unsigned int)modifierFlags;

/*!
	@method stringValue
	@abstract Get a string got the hot keys.
	@discussion This is a string that can be used for display purposes.
	@result A <tt>NSString</tt>
 */
- (NSString *)stringValue;

@end

/*!
	@protocol NSObject(NDHotKeyEventTragetWillChange)
	@abstract Informal protocol used to inform a <tt>NDHotKeyEvent</tt> target of events.
	@discussion The informal protocol <tt>NDHotKeyEventTragetWillChange</tt> defines a method used to notify a <tt>NDHotKeyEvent</tt> target that the target will change.
 */
@interface NSObject (NDHotKeyEventTragetWillChange)

/*!
	@method targetWillChangeToObject:forHotKeyEvent:
	@abstract Message sent to a target object to inform it that the target is going to change.
	@discussion This method can be used to notify the receiver that it will no longer be the target for a <tt>NDHotKeyEvent</tt> or used to prevent the target from changing by returning <tt>NO</tt>
	@param target The new target for the <tt>NDHotKeyEvent</tt>
	@param hotKeyEvent The <tt>NDHotKeyEvent</tt> for which the target is changing.
	@result Return <tt>NO</tt> to prevent the target from changing, otherwise return <tt>YES</tt>.
  */
- (BOOL)targetWillChangeToObject:(id)target forHotKeyEvent:(NDHotKeyEvent *)hotKeyEvent;

@end

/*!
	@function stringForKeyCodeAndModifierFlags
	@abstract Get a string for hot key parameters.
	@discussion Returns a string representation of the passed in hot key values.
	@param keyCode A key code.
	@param aChar A character representation of the key code.
	@param modifierFlags modifer flags, comman, option, shift and control. 
	@result A <tt>NSString</tt> representing the hot key combination.
 */
NSString * stringForKeyCodeAndModifierFlags( unsigned short keyCode, unichar aChar, unsigned int modifierFlags );
/*!
	@function unicharForKeyCode
	@abstract Get a unicode charater for the key combination.
	@discussion The uncode chararter for the key combination.
	@param keyCode The key code used by the keyboard, can vary across hardware. 
	@result A <tt>unichar</tt>
 */
unichar unicharForKeyCode( unsigned short keyCode );
