/*
	NDHotKeyEvent.m

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

#import "NDHotKeyEvent.h"
#import "NDKeyboardLayout.h"

@interface NDHotKeyEvent ()
+ (NSHashTable *)allHotKeyEvents;
- (void)addHotKey;
- (void)removeHotKey;
- (BOOL)setCollectiveEnabled:(BOOL)aFlag;
- (BOOL)collectiveEnable;
@end

static NSString		* kArchivingKeyCodeKey = @"KeyCodeKey",
					* kArchivingModifierFlagsKey = @"ModifierFlagsKey",
					* kArchivingSelectorReleasedCodeKey = @"SelectorReleasedCodeKey",
					* kArchivingSelectorPressedCodeKey = @"SelectorPressedCodeKey";
const OSType		NDHotKeyDefaultSignature = 'NDHK';

static OSStatus	switchHotKey( NDHotKeyEvent * self, BOOL aFlag );

/*
 * class implementation NDHotKeyEvent
 */
@implementation NDHotKeyEvent

static NSHashTable		* allHotKeyEvents = NULL;
static EventHandlerRef	hotKeysEventHandler = NULL;
static OSType			signature = 0;

static pascal OSErr eventHandlerCallback( EventHandlerCallRef anInHandlerCallRef, EventRef anInEvent, void * self );

static NSUInteger hashValueHashFunction( NSHashTable * aTable, const void * aHotKeyEvent );
static BOOL isEqualHashFunction( NSHashTable * aTable, const void * aFirstHotKeyEvent, const void * aSecondHotKeyEvent);
static NSString * describeHashFunction( NSHashTable * aTable, const void * aHotKeyEvent );

UInt32 _idForKeyCodeAndModifer( UInt16 aKeyCode, NSUInteger aModFlags )
{
	return aKeyCode | aModFlags;
}

void _getKeyCodeAndModiferForId( UInt32 anId, UInt16 *aKeyCode, NSUInteger *aModFlags )
{
	*aModFlags = NSDeviceIndependentModifierFlagsMask&anId;
	*aKeyCode = (UInt16)anId;
}

struct HotKeyMappingEntry
{
	UInt32				hotKeyId;
	NDHotKeyEvent		* hotKeyEvent;
};

/*
 * +install
 */
+ (BOOL)install
{
	if( hotKeysEventHandler == NULL )
	{
		NSHashTable *		theHotKeyEvents = [self allHotKeyEvents];
		EventTypeSpec		theTypeSpec[] =
		{
			{ kEventClassKeyboard, kEventHotKeyPressed },
			{ kEventClassKeyboard, kEventHotKeyReleased }
		};
		
		@synchronized([self class]) {;
		if( theHotKeyEvents != nil && hotKeysEventHandler == NULL )
		{
			if( InstallEventHandler( GetEventDispatcherTarget(), NewEventHandlerUPP((EventHandlerProcPtr)eventHandlerCallback), 2, theTypeSpec, theHotKeyEvents, &hotKeysEventHandler ) != noErr )
				NSLog(@"Could not install Event handler");
		}
		};
	}
	
	return hotKeysEventHandler != NULL;
}

+ (void)uninstall
{
	if( hotKeysEventHandler != NULL )
		RemoveEventHandler( hotKeysEventHandler );
}

/*
 * +initialize:
 */
+ (void)initialize
{
	[NDHotKeyEvent setVersion:1];			// the character attribute has been removed
#ifdef NDHotKeyEventThreadSafe
#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_4
	while( hotKeysLock == nil )
	{
		NSLock		* theInstance = [[NSLock alloc] init];

		if( !CompareAndSwap( nil, (unsigned long int)theInstance, (unsigned long int*)&hotKeysLock) )
			[theInstance release];			// did not use instance
	}
#endif
#endif
}

/*
 * +setSignature:
 */
+ (void)setSignature:(OSType)aSignature
{
	NSAssert( signature == 0 || aSignature == signature, @"The signature used by NDHotKeyEvent can only be set once safely" );
	signature = aSignature;
}

/*
 * +signature
 */
+ (OSType)signature
{
	signature = signature ? signature : NDHotKeyDefaultSignature;
	return signature;
}

/*
 * +setAllEnabled:
 */
+ (BOOL)setAllEnabled:(BOOL)aFlag
{
	BOOL				theAllSucceeded = YES;
	NSHashTable		* theHashTable = [NDHotKeyEvent allHotKeyEvents];

	/*
	 * need to install before to make sure the method 'setCollectiveEnabled:'
	 * doesn't try install since install tries to aquire the lock 'hotKeysLock'
	 */
	if( theHashTable && [NDHotKeyEvent install] )
	{
		NSHashEnumerator			theEnumerator;
		struct HotKeyMappingEntry	* theHotKeyMapEntry;
		@synchronized([self class]) {;
			theEnumerator =  NSEnumerateHashTable( theHashTable );

			while( (theHotKeyMapEntry = (struct HotKeyMappingEntry*)NSNextHashEnumeratorItem(&theEnumerator) ) )
			{
				if( ![theHotKeyMapEntry->hotKeyEvent setCollectiveEnabled:aFlag] )
					theAllSucceeded = NO;
			}

			NSEndHashTableEnumeration( &theEnumerator );
		};
	}

	return theAllSucceeded;
}

/*
 * +isEnabledKeyCharacter:modifierFlags:
 */
+ (BOOL)isEnabledKeyCharacter:(unichar)aKeyCharacter modifierFlags:(NSUInteger)aModifierFlags
{
	return [[self findHotKeyForKeyCode:[[NDKeyboardLayout keyboardLayout] keyCodeForCharacter:aKeyCharacter numericPad:(aModifierFlags&NSNumericPadKeyMask) != 0] modifierFlags:aModifierFlags] isEnabled];
}

/*
 * +isEnabledKeyCode:modifierFlags:
 */
+ (BOOL)isEnabledKeyCode:(UInt16)aKeyCode modifierFlags:(NSUInteger)aModifierFlags
{
	return [[self findHotKeyForKeyCode:aKeyCode modifierFlags:aModifierFlags] isEnabled];
}

+ (NDHotKeyEvent *)getHotKeyForKeyCharacter:(unichar)aKeyCharacter modifierFlags:(NSUInteger)aModifierFlags
{
	return [self getHotKeyForKeyCode:[[NDKeyboardLayout keyboardLayout] keyCodeForCharacter:aKeyCharacter numericPad:(aModifierFlags&NSNumericPadKeyMask) != 0] modifierFlags:aModifierFlags];
}

/*
 * +getHotKeyForKeyCode:character:modifierFlags:
 */
+ (NDHotKeyEvent *)getHotKeyForKeyCode:(UInt16)aKeyCode modifierFlags:(NSUInteger)aModifierFlags
{
	NDHotKeyEvent		* theHotKey = nil;

	theHotKey = [self findHotKeyForKeyCode:aKeyCode modifierFlags:aModifierFlags];
	return theHotKey ? theHotKey : [self hotKeyWithKeyCode:aKeyCode modifierFlags:aModifierFlags];
}

+ (NDHotKeyEvent *)findHotKeyForKeyCharacter:(unichar)aKeyCharacter modifierFlags:(NSUInteger)aModifierFlags
{
	return [self findHotKeyForKeyCode:[[NDKeyboardLayout keyboardLayout] keyCodeForCharacter:aKeyCharacter numericPad:(aModifierFlags&NSNumericPadKeyMask) != 0] modifierFlags:aModifierFlags];
}

/*
 * +findHotKeyForKeyCode:modifierFlags:
 */
+ (NDHotKeyEvent *)findHotKeyForKeyCode:(UInt16)aKeyCode modifierFlags:(NSUInteger)aModifierFlags
{
#if 1
	return [self findHotKeyForId:_idForKeyCodeAndModifer(aKeyCode, aModifierFlags)];
#else
	NDHotKeyEvent		* theFoundHotKeyEvent = nil;
	NSHashTable			* theHashTable = [NDHotKeyEvent allHotKeyEvents];

	if( theHashTable )
	{		
		NSHashEnumerator			theEnumerator =  NSEnumerateHashTable( allHotKeyEvents );
		struct HotKeyMappingEntry	* theHotKeyMapEntry;
		@synchronized([self class]) {;
		
		while( (theHotKeyMapEntry = (struct HotKeyMappingEntry*)NSNextHashEnumeratorItem(&theEnumerator) ) )
		{
			NDHotKeyEvent		* theHotKeyEvent = theHotKeyMapEntry->hotKeyEvent;
			if( [theHotKeyEvent keyCode] == aKeyCode && [theHotKeyEvent modifierFlags] == aModifierFlags )
			{
				theFoundHotKeyEvent = theHotKeyEvent;
				break;
			}
		}
		
		NSEndHashTableEnumeration( &theEnumerator );
		};
	}
	return theFoundHotKeyEvent;
#endif
}

/*
 * +findHotKeyForKeyCode:modifierFlags:
 */
+ (NDHotKeyEvent *)findHotKeyForId:(UInt32)anID
{
	struct HotKeyMappingEntry	* theFoundEntry = NULL;
	NSHashTable					* theHashTable = [NDHotKeyEvent allHotKeyEvents];
	
	if( theHashTable )
	{
		struct HotKeyMappingEntry		theDummyEntry = {anID,nil};
		
		@synchronized([self class]) {;
		theFoundEntry = NSHashGet( theHashTable, (void*)&theDummyEntry);
		if( theFoundEntry != NULL )
			[[theFoundEntry->hotKeyEvent retain] autorelease];
		};
	}
	
	return (theFoundEntry) ? theFoundEntry->hotKeyEvent : nil;
}

/*
 * +hotKeyWithEvent:
 */
+ (id)hotKeyWithEvent:(NSEvent *)anEvent
{
	return [[[self alloc] initWithEvent:anEvent] autorelease];
}

/*
 * +hotKeyWithEvent::target:selector:
 */
+ (id)hotKeyWithEvent:(NSEvent *)anEvent target:(id)aTarget selector:(SEL)aSelector
{
	return [[[self alloc] initWithEvent:anEvent target:aTarget selector:aSelector] autorelease];
}

/*
 * +hotKeyWithKeyCode:modifierFlags:
 */
+ (id)hotKeyWithKeyCharacter:(unichar)aKeyCharacter modifierFlags:(NSUInteger)aModifierFlags
{
	return [[[self alloc] initWithKeyCode:[[NDKeyboardLayout keyboardLayout] keyCodeForCharacter:aKeyCharacter numericPad:(aModifierFlags&NSNumericPadKeyMask) != 0] modifierFlags:aModifierFlags target:nil selector:(SEL)0] autorelease];
}

/*
 * +hotKeyWithKeyCode:modifierFlags:
 */
+ (id)hotKeyWithKeyCode:(UInt16)aKeyCode modifierFlags:(NSUInteger)aModifierFlags
{
	return [[[self alloc] initWithKeyCode:aKeyCode modifierFlags:aModifierFlags target:nil selector:(SEL)0] autorelease];
}

/*
 * +hotKeyWithKeyCharacter:modifierFlags:target:selector:
 */
+ (id)hotKeyWithKeyCharacter:(unichar)aKeyCharacter modifierFlags:(NSUInteger)aModifierFlags target:(id)aTarget selector:(SEL)aSelector
{
	return [[[self alloc] initWithKeyCode:[[NDKeyboardLayout keyboardLayout] keyCodeForCharacter:aKeyCharacter numericPad:(aModifierFlags&NSNumericPadKeyMask) != 0] modifierFlags:aModifierFlags target:aTarget selector:aSelector] autorelease];
}

/*
 * +hotKeyWithKeyCode:modifierFlags:target:selector:
 */
+ (id)hotKeyWithKeyCode:(UInt16)aKeyCode modifierFlags:(NSUInteger)aModifierFlags target:(id)aTarget selector:(SEL)aSelector
{
	return [[[self alloc] initWithKeyCode:aKeyCode modifierFlags:aModifierFlags target:aTarget selector:aSelector] autorelease];
}

+ (id)hotKeyWithWithPropertyList:(id)aPropertyList
{
	return [[[self alloc] initWithPropertyList:aPropertyList] autorelease];
}

+ (NSString *)description
{
	NSHashTable		* theHashTable = [NDHotKeyEvent allHotKeyEvents];
	NSString		* theDescription = nil;
	if( theHashTable )
	{
		@synchronized([self class]) {;
			theDescription = NSStringFromHashTable(theHashTable);
		};
	}
	return theDescription;
}

/*
 * -init
 */
- (id)init
{
	[self release];
	NSAssert( NO, @"You can not initialize a Hot Key with the init method" );
	return nil;
}

- (id)initWithEvent:(NSEvent *)anEvent
{
	return [self initWithEvent:anEvent target:nil selector:NULL];
}

- (id)initWithEvent:(NSEvent *)anEvent target:(id)aTarget selector:(SEL)aSelector
{
	unsigned long		theModifierFlags = [anEvent modifierFlags] & (NSShiftKeyMask|NSControlKeyMask|NSAlternateKeyMask|NSCommandKeyMask);

	return [self initWithKeyCode:[anEvent keyCode]
				   modifierFlags:theModifierFlags
						  target:aTarget
						selector:aSelector];
}

/*
 * -initWithKeyCharacter:modifierFlags:
 */
- (id)initWithKeyCharacter:(unichar)aKeyCharacter modifierFlags:(NSUInteger)aModifierFlags
{
	return [self initWithKeyCode:[[NDKeyboardLayout keyboardLayout] keyCodeForCharacter:aKeyCharacter numericPad:(aModifierFlags&NSNumericPadKeyMask) != 0] modifierFlags:aModifierFlags target:nil selector:NULL];
}

/*
 * -initWithKeyCode:modifierFlags:
 */
- (id)initWithKeyCode:(UInt16)aKeyCode modifierFlags:(NSUInteger)aModifierFlags
{
	return [self initWithKeyCode:aKeyCode modifierFlags:aModifierFlags target:nil selector:NULL];
}

/*
 * -initWithKeyCharacter:character:modifierFlags:target:selector:
 */
- (id)initWithKeyCharacter:(unichar)aKeyCharacter modifierFlags:(NSUInteger)aModifierFlags target:(id)aTarget selector:(SEL)aSelector
{
	return [self initWithKeyCode:[[NDKeyboardLayout keyboardLayout] keyCodeForCharacter:aKeyCharacter numericPad:(aModifierFlags&NSNumericPadKeyMask) != 0] modifierFlags:aModifierFlags target:aTarget selector:aSelector];
}

/*
 * -initWithKeyCode:character:modifierFlags:target:selector:
 */
- (id)initWithKeyCode:(UInt16)aKeyCode modifierFlags:(NSUInteger)aModifierFlags target:(id)aTarget selector:(SEL)aSelector
{
	if( (self = [super init]) != nil )
	{
		keyCode = aKeyCode;
		modifierFlags = aModifierFlags;
		target = aTarget;
		selectorReleased = aSelector;
		currentEventType = NDHotKeyNoEvent;
		isEnabled.collective = YES;
		[self addHotKey];
	}
	else
	{
		[self release];
		self = nil;
	}

	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if( (self = [super init]) != nil)
	{
		if( [aDecoder allowsKeyedCoding] )
		{
			keyCode = [[aDecoder decodeObjectForKey:kArchivingKeyCodeKey] unsignedShortValue];
			modifierFlags = [[aDecoder decodeObjectForKey:kArchivingModifierFlagsKey] unsignedIntegerValue];
			
			selectorReleased = NSSelectorFromString( [aDecoder decodeObjectForKey:kArchivingSelectorReleasedCodeKey] );
			selectorPressed = NSSelectorFromString( [aDecoder decodeObjectForKey:kArchivingSelectorPressedCodeKey] );
		}
		else
		{
			unichar				theCharacter;
			[aDecoder decodeValueOfObjCType:@encode(UInt16) at:&keyCode];
			if( [aDecoder versionForClassName:@"NDHotKeyNoEvent"] == 0 )
				[aDecoder decodeValueOfObjCType:@encode(unichar) at:&theCharacter];
			[aDecoder decodeValueOfObjCType:@encode(NSUInteger) at:&modifierFlags];

			selectorReleased = NSSelectorFromString( [aDecoder decodeObject] );
			selectorPressed = NSSelectorFromString( [aDecoder decodeObject] );
		}

		[self addHotKey];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)anEncoder
{
	if( [anEncoder allowsKeyedCoding] )
	{
		[anEncoder encodeObject:[NSNumber numberWithUnsignedShort:keyCode] forKey:kArchivingKeyCodeKey];
		[anEncoder encodeObject:[NSNumber numberWithUnsignedInteger:modifierFlags] forKey:kArchivingModifierFlagsKey];

		[anEncoder encodeObject:NSStringFromSelector( selectorReleased ) forKey:kArchivingSelectorReleasedCodeKey];
		[anEncoder encodeObject:NSStringFromSelector( selectorPressed ) forKey:kArchivingSelectorPressedCodeKey];
	}
	else
	{
		[anEncoder encodeValueOfObjCType:@encode(UInt16) at:&keyCode];
		[anEncoder encodeValueOfObjCType:@encode(NSUInteger) at:&modifierFlags];

		[anEncoder encodeObject:NSStringFromSelector( selectorReleased )];
		[anEncoder encodeObject:NSStringFromSelector( selectorPressed )];
	}
}

- (id)initWithPropertyList:(id)aPropertyList
{
	if( aPropertyList )
	{
		NSNumber	* theKeyCode,
					* theModiferFlag;
		SEL			theKeyPressedSelector,
					theKeyReleasedSelector;

		theKeyCode = [aPropertyList objectForKey:kArchivingKeyCodeKey];
		theModiferFlag = [aPropertyList objectForKey:kArchivingModifierFlagsKey];
		theKeyPressedSelector = NSSelectorFromString([aPropertyList objectForKey:kArchivingSelectorPressedCodeKey]);
		theKeyReleasedSelector = NSSelectorFromString([aPropertyList objectForKey:kArchivingSelectorReleasedCodeKey]);

		self = [self initWithKeyCode:[theKeyCode unsignedShortValue] modifierFlags:[theModiferFlag unsignedIntValue]];
	}
	else
	{
		[self release];
		self = nil;
	}

	return self;
}

- (id)propertyList
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithUnsignedShort:[self keyCode]], kArchivingKeyCodeKey,
		[NSNumber numberWithUnsignedInt:[self modifierFlags]], kArchivingModifierFlagsKey,
		NSStringFromSelector( selectorPressed ), kArchivingSelectorPressedCodeKey,
		NSStringFromSelector( selectorReleased ), kArchivingSelectorReleasedCodeKey,
		nil];
}

/*
 * -release
 */
- (oneway void)release
{
	/*
	 *	We need to remove the hot key from the hash table before it's retain count reaches zero
	 */
	if( [self retainCount] == 1 )
	{
		NSHashTable		* theHashTable = [NDHotKeyEvent allHotKeyEvents];
		if( theHashTable )
		{
			struct HotKeyMappingEntry		theDummyEntry = {[self hotKeyId],nil};

			@synchronized([self class]) {;
				if( [self retainCount] == 1 )		// check again because it might have changed
				{
					switchHotKey( self, NO );
					id		theHotKeyEvent = NSHashGet( theHashTable, (void*)&theDummyEntry );
					if( theHotKeyEvent )
						NSHashRemove( theHashTable, theHotKeyEvent );
				}
			};
		}
	}
	[super release];
}

#if 0
- (void)dealloc
{
	if( reference )
	{
		if( UnregisterEventHotKey( reference ) != noErr )	// in lock from release
			NSLog( @"Failed to unregister hot key %@", self );
	}
	[super dealloc];
}
#endif

/*
 * -setEnabled:
 */
- (BOOL)setEnabled:(BOOL)aFlag
{
	BOOL		theResult = YES;

	if( [NDHotKeyEvent install] )
	{
		/*
		 * if individual and collective YES then currently ON, otherwise currently off
		 */
		@synchronized([self class]) {;
			if( aFlag == YES && isEnabled.collective == YES  && isEnabled.individual == NO )
			{
				theResult = (switchHotKey( self, YES ) == noErr);
			}
			else if( aFlag == NO && isEnabled.collective == YES  && isEnabled.individual == YES )
			{
				theResult = (switchHotKey( self, NO ) == noErr);
			}
		};

		if( theResult )
			isEnabled.individual = aFlag;
		else
			NSLog(@"%s failed ", aFlag ? "enable" : "disable" );
	}
	else
		theResult = NO;

	return theResult;
}

- (void)setIsEnabled:(BOOL)aFlag
{
	[self setEnabled:aFlag];
}

/*
 * -isEnabled
 */
- (BOOL)isEnabled
{
	return isEnabled.individual && isEnabled.collective;
}

/*
 * -target
 */
- (id)target
{
	return target;
}

/*
* -selector
*/
- (SEL)selector
{
	return selectorReleased;
}

/*
 * -selectorReleased
 */
- (SEL)selectorReleased
{
	return selectorReleased;
}

/*
* -selectorPressed
*/
- (SEL)selectorPressed
{
	return selectorPressed;
}

/*
 * -currentEventType
 *		(NDHotKeyNoEvent | NDHotKeyPressedEvent | NDHotKeyReleasedEvent)
 */
- (int)currentEventType
{
	return currentEventType;
}

/*
 * -setTarget:selector:
 */
- (BOOL)setTarget:(id)aTarget selector:(SEL)aSelector
{
	return [self setTarget:aTarget selectorReleased:aSelector selectorPressed:(SEL)0];
}

/*
 * -setTarget:selectorReleased:selectorPressed:
 */
- (BOOL)setTarget:(id)aTarget selectorReleased:(SEL)aSelectorReleased selectorPressed:(SEL)aSelectorPressed
{
	[self setEnabled:NO];
	if( target && target != aTarget )
	{
		[self setEnabled:NO];
		if( ![target respondsToSelector:@selector(targetWillChangeToObject:forHotKeyEvent:)] || [target targetWillChangeToObject:aTarget forHotKeyEvent:self] )
		{
			target = aTarget;
			selectorReleased = aSelectorReleased;
			selectorPressed = aSelectorPressed;
		}
	}
	else
	{
		target = aTarget;
		selectorReleased = aSelectorReleased;
		selectorPressed = aSelectorPressed;
	}

	return target == aTarget;		// was change succesful
}

/*
 * -performHotKeyReleased
 */
- (void)performHotKeyReleased
{
	NSAssert( target, @"NDHotKeyEvent tried to perfrom release with no target" );
	
	currentEventType = NDHotKeyReleasedEvent;
	if( selectorReleased )
	{
		if([target respondsToSelector:selectorReleased])
			[target performSelector:selectorReleased withObject:self];
		else if( [target respondsToSelector:@selector(makeObjectsPerformSelector:withObject:)] )
			[target makeObjectsPerformSelector:selectorReleased withObject:self];
	}
	currentEventType = NDHotKeyNoEvent;
}

/*
 * -performHotKeyPressed
 */
- (void)performHotKeyPressed
{
	NSAssert( target, @"NDHotKeyEvent tried to perfrom press with no target" );

	currentEventType = NDHotKeyPressedEvent;
	if( selectorPressed )
	{
		if([target respondsToSelector:selectorPressed])
			[target performSelector:selectorPressed withObject:self];
		else if( [target respondsToSelector:@selector(makeObjectsPerformSelector:withObject:)] )
			[target makeObjectsPerformSelector:selectorPressed withObject:self];
	}
	currentEventType = NDHotKeyNoEvent;
}

/*
 * -keyCode
 */
- (UInt16)keyCode
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

- (UInt32)hotKeyId
{
	return _idForKeyCodeAndModifer( [self keyCode], [self modifierFlags] );
}

/*
 * -stringValue
 */
- (NSString *)stringValue
{
	return [[NDKeyboardLayout keyboardLayout] stringForKeyCode:[self keyCode] modifierFlags:[self modifierFlags]];
}


/*
 * -isEqual:
 */
- (BOOL)isEqual:(id)anObject
{
	return [super isEqual:anObject] || ([anObject isKindOfClass:[self class]] == YES && [self keyCode] == [(NDHotKeyEvent*)anObject keyCode] && [self modifierFlags] == [anObject modifierFlags]);
}

/*
 * -hash
 */
- (NSUInteger)hash
{
	return ((NSUInteger)keyCode & ~modifierFlags) | (modifierFlags & ~((NSUInteger)keyCode));		// xor
}

/*
 * -description
 */
- (NSString *)description
{
	return [NSString stringWithFormat:@"{\n\tKey Combination: %@,\n\tEnabled: %s\n\tKey Press Selector: %@\n\tKey Release Selector: %@\n}\n",
					[self stringValue],
					[self isEnabled] ? "yes" : "no",
					NSStringFromSelector([self selectorPressed]),
					NSStringFromSelector([self selectorReleased])];
}

/*
 * eventHandlerCallback()
 */
pascal OSErr eventHandlerCallback( EventHandlerCallRef anInHandlerCallRef, EventRef anInEvent, void * anInUserData )
{
//	NSHashTable			* allHotKeyEvents = (NSHashTable *)anInUserData;
	EventHotKeyID		theHotKeyID;
	OSStatus			theError;

	NSCAssert( GetEventClass( anInEvent ) == kEventClassKeyboard, @"Got event that is not a hot key event" );

	theError = GetEventParameter( anInEvent, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(EventHotKeyID), NULL, &theHotKeyID );

	if( theError == noErr )
	{
		NDHotKeyEvent		* theHotKeyEvent;
		UInt32				theEventKind;
		
		NSCAssert( [NDHotKeyEvent signature] == theHotKeyID.signature, @"Got hot key event with wrong signature" );

		theHotKeyEvent = [NDHotKeyEvent findHotKeyForId:theHotKeyID.id];

		theEventKind = GetEventKind( anInEvent );
		if( kEventHotKeyPressed == theEventKind )
		{
			[theHotKeyEvent performHotKeyPressed];
		}
		else if( kEventHotKeyReleased == theEventKind )
		{
			[theHotKeyEvent performHotKeyReleased];
		}
	}

	return theError;
}

/*
 * hashValueHashFunction()
 */
NSUInteger hashValueHashFunction( NSHashTable * aTable, const void * aHotKeyEntry )
{
	struct HotKeyMappingEntry	* theHotKeyEntry = (struct HotKeyMappingEntry*)aHotKeyEntry;
	return  theHotKeyEntry->hotKeyId;
}

/*
 * isEqualHashFunction()
 */
BOOL isEqualHashFunction( NSHashTable * aTable, const void * aFirstHotKeyEntry, const void * aSecondHotKeyEntry)
{
	struct HotKeyMappingEntry		* theFirst = (struct HotKeyMappingEntry*)aFirstHotKeyEntry,
									* theSecond = (struct HotKeyMappingEntry*)aSecondHotKeyEntry;
	return theFirst->hotKeyId == theSecond->hotKeyId;
}

/*
 * describeHashFunction()
 */
NSString * describeHashFunction( NSHashTable * aTable, const void * aHotKeyEntry )
{
	NDHotKeyEvent		* theHotKey;

	theHotKey = ((struct HotKeyMappingEntry*)aHotKeyEntry)->hotKeyEvent;
	return [theHotKey description];
}

#pragma mark Private methods

/*
 * +allHotKeyEvents
 */
+ (NSHashTable *)allHotKeyEvents
{
	if( allHotKeyEvents == NULL )
	{
		NSHashTableCallBacks		theHashCallBacks;

		theHashCallBacks.hash = hashValueHashFunction;
		theHashCallBacks.isEqual = isEqualHashFunction;
		theHashCallBacks.retain = NULL;
		theHashCallBacks.release = NULL;
		theHashCallBacks.describe = describeHashFunction;

		@synchronized([self class]) {;
			if( allHotKeyEvents == NULL )
				allHotKeyEvents = NSCreateHashTableWithZone( theHashCallBacks, 0, NULL);
		};
	}

	return allHotKeyEvents;
}

/*
 * -addHotKey
 */
- (void)addHotKey
{
	NSHashTable			* theHashTable = [NDHotKeyEvent allHotKeyEvents];
	if( theHashTable )
	{
		struct HotKeyMappingEntry	* theEntry = (struct HotKeyMappingEntry *)malloc(sizeof(struct HotKeyMappingEntry));

		/*
			keep trying to add the hot key to the table until a unique id is found
		 */
		@synchronized([self class]) {;
		theEntry->hotKeyId = [self hotKeyId];
		theEntry->hotKeyEvent = self;

		NSParameterAssert( NSHashInsertIfAbsent( theHashTable, (void*)theEntry ) == NULL );
		};
	}
}

/*
 * -removeHotKey
 */
- (void)removeHotKey
{
	[self setEnabled:NO];

	NSHashTable		* theHashTable = [NDHotKeyEvent allHotKeyEvents];
	if( theHashTable )
	{
		struct HotKeyMappingEntry	theDummyEntry = {[self hotKeyId],nil};
		struct HotKeyMappingEntry	* theEntry = NULL;

		@synchronized([self class]) {;
			theEntry = (struct HotKeyMappingEntry*)NSHashGet( theHashTable, (void*)&theDummyEntry);
			if( theEntry )
			{
				NSParameterAssert( theEntry->hotKeyEvent == self );
				NSHashRemove( theHashTable, theEntry );
			}
		};
	}
}

/*
 * setCollectiveEnabled:
 */
- (BOOL)setCollectiveEnabled:(BOOL)aFlag
{
	BOOL		theResult = YES;
	
	if( [NDHotKeyEvent install] )
	{
		/*
		 * if individual and collective YES then currently ON, otherwise currently off
		 */
		@synchronized([self class]) {;
			if( aFlag == YES && isEnabled.collective == NO  && isEnabled.individual == YES )
			{
				theResult = (switchHotKey( self, YES ) == noErr);
			}
			else if( aFlag == NO && isEnabled.collective == YES  && isEnabled.individual == YES )
			{
				theResult = (switchHotKey( self, NO ) == noErr);
			}
		};

		if( theResult )
			isEnabled.collective = aFlag;
		else
			NSLog(@"%s failed", aFlag ? "enable" : "disable" );
	}
	else
		theResult = NO;

	return theResult;
}

/*
 * collectiveEnable()
 */
- (BOOL)collectiveEnable
{
	return isEnabled.collective;
}

/*
 * switchHotKey()
 */
static OSStatus switchHotKey( NDHotKeyEvent * self, BOOL aFlag )
{
	OSStatus				theError;
	if( aFlag )
	{
		EventHotKeyID 		theHotKeyID;

		theHotKeyID.signature = [NDHotKeyEvent signature];
		theHotKeyID.id = [self hotKeyId];

		NSCAssert( theHotKeyID.signature, @"HotKeyEvent signature has not been set yet" );
		NSCParameterAssert(sizeof(unsigned long) >= sizeof(id) );

		theError = RegisterEventHotKey( self->keyCode, NDCarbonModifierFlagsForCocoaModifierFlags(self->modifierFlags), theHotKeyID, GetEventDispatcherTarget(), 0, &self->reference );
	}
	else
	{
		theError = UnregisterEventHotKey( self->reference );
	}

	return theError;
}

#pragma mark Deprecated Methods

+ (NDHotKeyEvent *)getHotKeyForKeyCode:(UInt16)aKeyCode character:(unichar)aChar modifierFlags:(NSUInteger)aModifierFlags
{
	return [self getHotKeyForKeyCode:aKeyCode modifierFlags:aModifierFlags];
}

/*
 * +hotKeyWithKeyCode:character:modifierFlags:
 */
+ (id)hotKeyWithKeyCode:(UInt16)aKeyCode character:(unichar)aChar modifierFlags:(NSUInteger)aModifierFlags
{
	return [self hotKeyWithKeyCode:aKeyCode modifierFlags:aModifierFlags target:nil selector:NULL];
}

/*
 * +hotKeyWithKeyCode:character:modifierFlags:target:selector:
 */
+ (id)hotKeyWithKeyCode:(UInt16)aKeyCode character:(unichar)aChar modifierFlags:(NSUInteger)aModifierFlags target:(id)aTarget selector:(SEL)aSelector
{
	return [[[self alloc] initWithKeyCode:aKeyCode modifierFlags:aModifierFlags target:aTarget selector:aSelector] autorelease];
}

/*
 * -initWithKeyCode:character:modifierFlags:
 */
- (id)initWithKeyCode:(UInt16)aKeyCode character:(unichar)aChar modifierFlags:(NSUInteger)aModifierFlags
{
	return [self initWithKeyCode:aKeyCode modifierFlags:aModifierFlags target:nil selector:NULL];
}

/*
 * -initWithKeyCode:character:modifierFlags:target:selector:
 */
- (id)initWithKeyCode:(UInt16)aKeyCode character:(unichar)aChar modifierFlags:(NSUInteger)aModifierFlags target:(id)aTarget selector:(SEL)aSelector
{
	return [self initWithKeyCode:aKeyCode modifierFlags:aModifierFlags target:aTarget selector:aSelector];
}

@end

NSString * stringForModifiers( NSUInteger aModifierFlags )
{
	NSMutableString		* theString;
	unichar					theCharacter;

	theString = [NSMutableString string];
	if( aModifierFlags & NSControlKeyMask)
	{
		theCharacter = kControlUnicode;
		[theString appendString:[NSString stringWithCharacters:&theCharacter length:1]];
	}
	
	if( aModifierFlags & NSAlternateKeyMask)
	{
		theCharacter = kOptionUnicode;
		[theString appendString:[NSString stringWithCharacters:&theCharacter length:1]];
	}
	
	if( aModifierFlags & NSShiftKeyMask)
	{
		theCharacter = kShiftUnicode;
		[theString appendString:[NSString stringWithCharacters:&theCharacter length:1]];
	}
	
	if( aModifierFlags & NSCommandKeyMask)
	{
		theCharacter = kCommandUnicode;
		[theString appendString:[NSString stringWithCharacters:&theCharacter length:1]];
	}

	return theString;
}
