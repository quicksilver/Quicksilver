/*
 *  NDHotKeyEvent.m
 *  NDHotKeyEvent
 *
 *  Created by Nathan Day on Wed Feb 26 2003.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "NDHotKeyEvent.h"

@interface NDHotKeyEvent (Private)
+ (NSHashTable *)allHotKeyEvents;
- (BOOL)addHotKey;
- (void)removeHotKey;
- (BOOL)setCollectiveEnabled:(BOOL)aFlag;
- (BOOL)collectiveEnable;
@end

static NSString		* kArchivingKeyCodeKey = @"KeyCodeKey",
							* kArchivingCharacterKey = @"CharacterKey",
							* kArchivingModifierFlagsKey = @"ModifierFlagsKey",
							* kArchivingSelectorReleasedCodeKey = @"SelectorReleasedCodeKey",
							* kArchivingSelectorPressedCodeKey = @"SelectorPressedCodeKey";
const OSType			NDHotKeyDefaultSignature = 'NDHK';

static OSStatus	switchHotKey( NDHotKeyEvent * self, BOOL aFlag );

/*
 * class implementation NDHotKeyEvent
 */
@implementation NDHotKeyEvent

#ifdef NDHotKeyEventThreadSafe
	#warning Thread saftey has been enabled for NDHotKeyEvent class methods
	#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_4
		#define	NDHotKeyEventLock @synchronized([self class]) {
		#define	NDHotKeyEventUnlock }
	#else
		static NSLock				* hotKeysLock = NULL;
		#define	NDHotKeyEventLock [hotKeysLock lock]
		#define	NDHotKeyEventUnlock [hotKeysLock unlock]
	#endif
#else
	#warning The NDHotKeyEvent class methods are NOT thread safe
	#define	NDHotKeyEventLock // lock
	#define	NDHotKeyEventUnlock // unlock
#endif

static NSHashTable		* allHotKeyEvents = NULL;
static BOOL					isInstalled = NO;
static OSType				signature = 0;

unsigned int cocoaModifierFlagsToCarbonModifierFlags( unsigned int aModifierFlags );

pascal OSErr eventHandlerCallback( EventHandlerCallRef anInHandlerCallRef, EventRef anInEvent, void * self );

unsigned hashValueHashFunction( NSHashTable * aTable, const void * aHotKeyEvent );
BOOL isEqualHashFunction( NSHashTable * aTable, const void * aFirstHotKeyEvent, const void * aSecondHotKeyEvent);
NSString * describeHashFunction( NSHashTable * aTable, const void * aHotKeyEvent );

struct HotKeyMappingEntry
{
	unsigned short		keyCode;
	unsigned int		modifierFlags;
	NDHotKeyEvent		* hotKeyEvent;
};

/*
 * +install
 */
+ (BOOL)install
{
	if( isInstalled == NO )
	{
		NSHashTable *		theHotKeyEvents = [self allHotKeyEvents];
		EventTypeSpec		theTypeSpec[] =
								{
									{ kEventClassKeyboard, kEventHotKeyPressed },
									{ kEventClassKeyboard, kEventHotKeyReleased }
								};

		NDHotKeyEventLock;
			if( theHotKeyEvents != nil && isInstalled == NO )
			{
				if( InstallEventHandler( GetEventDispatcherTarget(), NewEventHandlerUPP((EventHandlerProcPtr)eventHandlerCallback), 2, theTypeSpec, theHotKeyEvents, nil ) == noErr )
				{
					isInstalled = YES;
				}
				else
				{
					NSLog(@"Could not install Event handler");
				}
			}
		NDHotKeyEventUnlock;
	}

	return isInstalled;
}

#ifdef NDHotKeyEventThreadSafe
#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_4
/*
 * +initialize:
 */
+ (void)initialize
{
	while( hotKeysLock == nil )
	{
		NSLock		* theInstance = [[NSLock alloc] init];

		if( !CompareAndSwap( nil, (unsigned long int)theInstance, (unsigned long int*)&hotKeysLock) )
			[theInstance release];			// did not use instance
	}
}
#endif
#endif

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
		NSHashEnumerator				theEnumerator;
		struct HotKeyMappingEntry	* theHotKeyMapEntry;
		NDHotKeyEventLock;
			theEnumerator =  NSEnumerateHashTable( theHashTable );

			while( (theHotKeyMapEntry = (struct HotKeyMappingEntry*)NSNextHashEnumeratorItem(&theEnumerator) ) )
			{
				if( ![theHotKeyMapEntry->hotKeyEvent setCollectiveEnabled:aFlag] )
					theAllSucceeded = NO;
			}

			NSEndHashTableEnumeration( &theEnumerator );
		NDHotKeyEventUnlock;
	}

	return theAllSucceeded;
}

/*
 * +isEnabledKeyCode:modifierFlags:
 */
+ (BOOL)isEnabledKeyCode:(unsigned short)aKeyCode modifierFlags:(unsigned int)aModifierFlags
{
	return [[self findHotKeyForKeyCode:aKeyCode modifierFlags:aModifierFlags] isEnabled];
}

/*
 * +getHotKeyForKeyCode:character:modifierFlags:
 */
+ (NDHotKeyEvent *)getHotKeyForKeyCode:(unsigned short)aKeyCode character:(unichar)aChar modifierFlags:(unsigned int)aModifierFlags
{
	NDHotKeyEvent		* theHotKey = nil;

	theHotKey = [self findHotKeyForKeyCode:aKeyCode modifierFlags:aModifierFlags];
	return theHotKey ? theHotKey : [self hotKeyWithKeyCode:aKeyCode character:aChar modifierFlags:aModifierFlags];
}

/*
 * +findHotKeyForKeyCode:modifierFlags:
 */
+ (NDHotKeyEvent *)findHotKeyForKeyCode:(unsigned short)aKeyCode modifierFlags:(unsigned int)aModifierFlags
{
	struct HotKeyMappingEntry		* theFoundEntry = NULL;
	NSHashTable							* theHashTable = [NDHotKeyEvent allHotKeyEvents];

	if( theHashTable )
	{
		struct HotKeyMappingEntry		theDummyEntry;

		theDummyEntry.keyCode = aKeyCode;
		theDummyEntry.modifierFlags = aModifierFlags;
		theDummyEntry.hotKeyEvent = nil;

		NDHotKeyEventLock;
			theFoundEntry = NSHashGet( theHashTable, (void*)&theDummyEntry);
			if( theFoundEntry != NULL )
				[[theFoundEntry->hotKeyEvent retain] autorelease];
		NDHotKeyEventUnlock;
	}

	return (theFoundEntry) ? theFoundEntry->hotKeyEvent : nil;
}

/*
 * +hotKeyWithEvent:
 */
+ (id)hotKeyWithEvent:(NSEvent *)anEvent
{
	return [self hotKeyWithEvent:anEvent target:nil selector:NULL];
}

/*
 * +hotKeyWithEvent::target:selector:
 */
+ (id)hotKeyWithEvent:(NSEvent *)anEvent target:(id)aTarget selector:(SEL)aSelector
{
	return [self hotKeyWithEvent:anEvent target:aTarget selector:aSelector];
}

/*
 * +hotKeyWithKeyCode:character:modifierFlags:
 */
+ (id)hotKeyWithKeyCode:(unsigned short)aKeyCode character:(unichar)aChar modifierFlags:(unsigned int)aModifierFlags
{
	return [self hotKeyWithKeyCode:aKeyCode character:aChar modifierFlags:aModifierFlags target:nil selector:NULL];
}

/*
 * +hotKeyWithKeyCode:character:modifierFlags:target:selector:
 */
+ (id)hotKeyWithKeyCode:(unsigned short)aKeyCode character:(unichar)aChar modifierFlags:(unsigned int)aModifierFlags target:(id)aTarget selector:(SEL)aSelector
{
	return [[[self alloc] initWithKeyCode:aKeyCode character:aChar modifierFlags:aModifierFlags target:aTarget selector:aSelector] autorelease];
}

+ (id)hotKeyWithWithPropertyList:(id)aPropertyList
{
	return [[[self alloc] initWithPropertyList:aPropertyList] autorelease];
}

+ (NSString *)description
{
	NSHashTable		* theHashTable = [NDHotKeyEvent allHotKeyEvents];
	NSString			* theDescription = nil;
	if( theHashTable )
	{
		NDHotKeyEventLock;
			theDescription = NSStringFromHashTable(theHashTable);
		NDHotKeyEventUnlock;
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
					   character:[[anEvent charactersIgnoringModifiers] characterAtIndex:0]
				   modifierFlags:theModifierFlags
						  target:aTarget
						selector:aSelector];
}

/*
 * -initWithKeyCode:character:modifierFlags:
 */
- (id)initWithKeyCode:(unsigned short)aKeyCode character:(unichar)aChar modifierFlags:(unsigned int)aModifierFlags
{
	return [self initWithKeyCode:aKeyCode character:aChar modifierFlags:aModifierFlags target:nil selector:NULL];
}

/*
 * -initWithKeyCode:character:modifierFlags:target:selector:
 */
- (id)initWithKeyCode:(unsigned short)aKeyCode character:(unichar)aChar modifierFlags:(unsigned int)aModifierFlags target:(id)aTarget selector:(SEL)aSelector
{
	if( (self = [super init]) != nil )
	{
		keyCode = aKeyCode;
		character = aChar;
		modifierFlags = aModifierFlags;
		target = aTarget;
		selectorReleased = aSelector;
		currentEventType = NDHotKeyNoEvent;
		isEnabled.collective = YES;

		if( ![self addHotKey] )
		{
			[self release];
			self = nil;
		}
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
			character = [[aDecoder decodeObjectForKey:kArchivingCharacterKey] unsignedShortValue];
			modifierFlags = [[aDecoder decodeObjectForKey:kArchivingModifierFlagsKey] unsignedIntValue];
			
			selectorReleased = NSSelectorFromString( [aDecoder decodeObjectForKey:kArchivingSelectorReleasedCodeKey] );
			selectorPressed = NSSelectorFromString( [aDecoder decodeObjectForKey:kArchivingSelectorPressedCodeKey] );
		}
		else
		{
			[aDecoder decodeValueOfObjCType:@encode(unsigned short) at:&keyCode];
			[aDecoder decodeValueOfObjCType:@encode(unichar) at:&character];
			[aDecoder decodeValueOfObjCType:@encode(unsigned int) at:&modifierFlags];

			selectorReleased = NSSelectorFromString( [aDecoder decodeObject] );
			selectorPressed = NSSelectorFromString( [aDecoder decodeObject] );
		}

		if( ![self addHotKey] )
		{
			[self release];
			self = nil;
		}
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)anEncoder
{
	if( [anEncoder allowsKeyedCoding] )
	{
		[anEncoder encodeObject:[NSNumber numberWithUnsignedShort:keyCode] forKey:kArchivingKeyCodeKey];
		[anEncoder encodeObject:[NSNumber numberWithUnsignedShort:character] forKey:kArchivingCharacterKey];
		[anEncoder encodeObject:[NSNumber numberWithUnsignedInt:modifierFlags] forKey:kArchivingModifierFlagsKey];

		[anEncoder encodeObject:NSStringFromSelector( selectorReleased ) forKey:kArchivingSelectorReleasedCodeKey];
		[anEncoder encodeObject:NSStringFromSelector( selectorPressed ) forKey:kArchivingSelectorPressedCodeKey];
	}
	else
	{
		[anEncoder encodeValueOfObjCType:@encode(unsigned short) at:&keyCode];
		[anEncoder encodeValueOfObjCType:@encode(unichar) at:&character];
		[anEncoder encodeValueOfObjCType:@encode(unsigned int) at:&modifierFlags];

		[anEncoder encodeObject:NSStringFromSelector( selectorReleased )];
		[anEncoder encodeObject:NSStringFromSelector( selectorPressed )];
	}
}

- (id)initWithPropertyList:(id)aPropertyList
{
	if( aPropertyList )
	{
		NSString		* theCharacter;
		NSNumber		* theKeyCode,
						* theModiferFlag;
		SEL			theKeyPressedSelector,
						theKeyReleasedSelector;

		theKeyCode = [aPropertyList objectForKey:kArchivingKeyCodeKey];
		theCharacter = [aPropertyList objectForKey:kArchivingCharacterKey];
		theModiferFlag = [aPropertyList objectForKey:kArchivingModifierFlagsKey];
		theKeyPressedSelector = NSSelectorFromString([aPropertyList objectForKey:kArchivingSelectorPressedCodeKey]);
		theKeyReleasedSelector = NSSelectorFromString([aPropertyList objectForKey:kArchivingSelectorReleasedCodeKey]);

		self = [self initWithKeyCode:[theKeyCode unsignedShortValue] character:[theCharacter characterAtIndex:0] modifierFlags:[theModiferFlag unsignedIntValue]];
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
		[NSString stringWithCharacters:&character length:1] , kArchivingCharacterKey,
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
			struct HotKeyMappingEntry		theDummyEntry;

			theDummyEntry.keyCode = [self keyCode];
			theDummyEntry.modifierFlags = [self modifierFlags];
			theDummyEntry.hotKeyEvent = nil;

			NDHotKeyEventLock;
				switchHotKey( self, NO );
				if( [self retainCount] == 1 )		// check again because it might have changed
				{
					id		theHotKeyEvent = NSHashGet( theHashTable, (void*)&theDummyEntry );
					if( theHotKeyEvent )
						NSHashRemove( theHashTable, theHotKeyEvent );
				}
			NDHotKeyEventUnlock;
		}
	}
//	else
	[super release];
}

- (void)dealloc
{
	if( UnregisterEventHotKey( reference ) != noErr )	// in lock from release
		NSLog( @"Failed to unregister hot key %@", self );
	[super dealloc];
}

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
		NDHotKeyEventLock;
			if( aFlag == YES && isEnabled.collective == YES  && isEnabled.individual == NO )
			{
				theResult = (switchHotKey( self, YES ) == noErr);
			}
			else if( aFlag == NO && isEnabled.collective == YES  && isEnabled.individual == YES )
			{
				theResult = (switchHotKey( self, NO ) == noErr);
			}
		NDHotKeyEventUnlock;

		if( theResult )
			isEnabled.individual = aFlag;
		else
			NSLog(@"%s failed ", aFlag ? "enable" : "disable" );
	}
	else
		theResult = NO;

	return theResult;
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
	
	if( selectorReleased && [target respondsToSelector:selectorReleased])
	{
		currentEventType = NDHotKeyReleasedEvent;
		[target performSelector:selectorReleased withObject:self];
		currentEventType = NDHotKeyNoEvent;
	}
}

/*
 * -performHotKeyPressed
 */
- (void)performHotKeyPressed
{
	NSAssert( target, @"NDHotKeyEvent tried to perfrom press with no target" );

	if( selectorPressed && [target respondsToSelector:selectorPressed])
	{
		currentEventType = NDHotKeyPressedEvent;
		[target performSelector:selectorPressed withObject:self];
		currentEventType = NDHotKeyNoEvent;
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
	return character;
}

/*
 * -modifierFlags
 */
- (unsigned int)modifierFlags
{
	return modifierFlags;
}

/*
 * -stringValue
 */
- (NSString *)stringValue
{
	NSString		* theStringValue = nil;
	NDHotKeyEventLock;
		theStringValue = stringForKeyCodeAndModifierFlags( [self keyCode], [self character], [self modifierFlags] );
	NDHotKeyEventUnlock;
	
	return theStringValue;
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
- (unsigned int)hash
{
	return ((unsigned int)keyCode & ~modifierFlags) | (modifierFlags & ~((unsigned int)keyCode));		// xor
}

/*
 * -description
 */
- (NSString *)description
{
	return [NSString stringWithFormat:@"{\n\tKey Combination: %@,\n\tEnabled: %s\n\tKey Press Selector: %@\n\tKey Release Selector: %@\n}\n", [self stringValue],
					[self isEnabled] ? "yes" : "no",
					NSStringFromSelector([self selectorPressed]),
					NSStringFromSelector([self selectorReleased])];
}

/*
 * cocoaModifierFlagsToCarbonModifierFlags()
 */
unsigned int cocoaModifierFlagsToCarbonModifierFlags( unsigned int aModifierFlags )
{
	unsigned int	theCarbonModifierFlags = 0;

	if(aModifierFlags & NSShiftKeyMask)
		theCarbonModifierFlags |= shiftKey;

	if(aModifierFlags & NSControlKeyMask)
		theCarbonModifierFlags |= controlKey;

	if(aModifierFlags & NSAlternateKeyMask)
		theCarbonModifierFlags |= optionKey;

	if(aModifierFlags & NSCommandKeyMask)
		theCarbonModifierFlags |= cmdKey;

	return theCarbonModifierFlags;
}

/*
 * eventHandlerCallback()
 */
pascal OSErr eventHandlerCallback( EventHandlerCallRef anInHandlerCallRef, EventRef anInEvent, void * anInUserData )
{
//	NSHashTable			* allHotKeyEvents = (NSHashTable *)anInUserData;
	EventHotKeyID		theHotKeyID;
	OSStatus				theError;

	NSCAssert( GetEventClass( anInEvent ) == kEventClassKeyboard, @"Got event that is not a hot key event" );

	theError = GetEventParameter( anInEvent, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(EventHotKeyID), NULL, &theHotKeyID );

	if( theError == noErr )
	{
		NDHotKeyEvent		* theHotKeyEvent;
		UInt32				theEventKind;
		
		NSCAssert( [NDHotKeyEvent signature] == theHotKeyID.signature, @"Got hot key event with wrong signature" );

		theHotKeyEvent = (NDHotKeyEvent*)theHotKeyID.id;

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
unsigned hashValueHashFunction( NSHashTable * aTable, const void * aHotKeyEntry )
{
	struct HotKeyMappingEntry		* theHotKeyEntry;
	unsigned int		theKeyCode,
							theModifiers;

	theHotKeyEntry = (struct HotKeyMappingEntry*)aHotKeyEntry;
	theKeyCode = (unsigned int)theHotKeyEntry->keyCode;
	theModifiers = (unsigned int)theHotKeyEntry->modifierFlags;
	return  theKeyCode ^ theModifiers;		// xor
}

/*
 * isEqualHashFunction()
 */
BOOL isEqualHashFunction( NSHashTable * aTable, const void * aFirstHotKeyEntry, const void * aSecondHotKeyEntry)
{
	struct HotKeyMappingEntry		* theFirst,
											* theSecond;

	theFirst = (struct HotKeyMappingEntry*)aFirstHotKeyEntry;
	theSecond = (struct HotKeyMappingEntry*)aSecondHotKeyEntry;
	return theFirst->keyCode == theSecond->keyCode && theFirst->modifierFlags == theSecond->modifierFlags;
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

@end

@implementation NDHotKeyEvent (Private)

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

		NDHotKeyEventLock;
			if( allHotKeyEvents == NULL )
				allHotKeyEvents = NSCreateHashTableWithZone( theHashCallBacks, 0, NULL);
		NDHotKeyEventUnlock;
	}

	return allHotKeyEvents;
}

/*
 * -addHotKey
 */
- (BOOL)addHotKey
{
	BOOL				theSuccess = NO;
	NSHashTable		* theHashTable = [NDHotKeyEvent allHotKeyEvents];
	if( theHashTable )
	{
		struct HotKeyMappingEntry		* theEntry;

		theEntry = (struct HotKeyMappingEntry *)malloc(sizeof(struct HotKeyMappingEntry));

		theEntry->keyCode = [self keyCode];
		theEntry->modifierFlags = [self modifierFlags];
		theEntry->hotKeyEvent = self;

		NDHotKeyEventLock;
			theSuccess = NSHashInsertIfAbsent( theHashTable, (void*)theEntry ) == NULL;
		NDHotKeyEventUnlock;
	}

	return theSuccess;
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
		struct HotKeyMappingEntry		theDummyEntry;
		id										theHotKeyEvent;

		theDummyEntry.keyCode = [self keyCode];
		theDummyEntry.modifierFlags = [self modifierFlags];
		theDummyEntry.hotKeyEvent = nil;

		NDHotKeyEventLock;
			theHotKeyEvent = NSHashGet( theHashTable, (void*)&theDummyEntry);
			if( theHotKeyEvent )
				NSHashRemove( theHashTable, theHotKeyEvent );
		NDHotKeyEventUnlock;
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
		NDHotKeyEventLock;
			if( aFlag == YES && isEnabled.collective == NO  && isEnabled.individual == YES )
			{
				theResult = (switchHotKey( self, YES ) == noErr);
			}
			else if( aFlag == NO && isEnabled.collective == YES  && isEnabled.individual == YES )
			{
				theResult = (switchHotKey( self, NO ) == noErr);
			}
		NDHotKeyEventUnlock;

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
		theHotKeyID.id = (unsigned int)self;

		NSCAssert( theHotKeyID.signature, @"HotKeyEvent signature has not been set yet" );
		NSCParameterAssert(sizeof(unsigned long) >= sizeof(id) );

		theError = RegisterEventHotKey( self->keyCode, cocoaModifierFlagsToCarbonModifierFlags(self->modifierFlags), theHotKeyID, GetEventDispatcherTarget(), 0, &self->reference );
	}
	else
	{
		theError = UnregisterEventHotKey( self->reference );
	}

	return theError;
}

@end

static NSString * stringForCharacter( const unsigned short aKeyCode, unichar aCharacter );
static NSString * stringForModifiers( unsigned int aModifierFlags );	

/*
 * stringForKeyCodeAndModifierFlags()
 */
NSString * stringForKeyCodeAndModifierFlags( unsigned short aKeyCode, unichar aChar, unsigned int aModifierFlags )
{
	return [stringForModifiers(aModifierFlags) stringByAppendingString:stringForCharacter( aKeyCode, aChar )];
}

/*
 * unicharForKeyCode()
 */
	static unichar unicodeForFunctionKey( UInt32 aKeyCode );	
unichar unicharForKeyCode( unsigned short aKeyCode )
{
	static UInt32			theState = 0;
	const void				* theKeyboardLayoutData;
	KeyboardLayoutRef		theCurrentKeyBoardLayout;
	UInt32					theChar = kNullCharCode;
	
	if( KLGetCurrentKeyboardLayout( &theCurrentKeyBoardLayout ) == noErr && KLGetKeyboardLayoutProperty( theCurrentKeyBoardLayout, kKLKCHRData, &theKeyboardLayoutData) == noErr )
	{
		theChar = KeyTranslate ( theKeyboardLayoutData, aKeyCode, &theState );

		switch( theChar )
		{
			case kHomeCharCode: theChar = NSHomeFunctionKey; break;
//			case kEnterCharCode: theChar = ; break;
			case kEndCharCode: theChar = NSEndFunctionKey; break;
			case kHelpCharCode: theChar = NSHelpFunctionKey; break;
//			case kBellCharCode: theChar = ; break;
//			case kBackspaceCharCode: theChar = ; break;
//			case kTabCharCode: theChar = ; break;
//			case kLineFeedCharCode: theChar = ; break;
			case kPageUpCharCode: theChar = NSPageUpFunctionKey; break;
			case kPageDownCharCode: theChar = NSPageDownFunctionKey; break;
//			case kReturnCharCode: theChar = ; break;
			case kFunctionKeyCharCode: theChar = unicodeForFunctionKey( aKeyCode ); break;
//			case kCommandCharCode: theChar = ; break;
//			case kCheckCharCode: theChar = ; break;
//			case kDiamondCharCode : theChar = ; break;
//			case kAppleLogoCharCode: theChar = ; break;
//			case kEscapeCharCode: theChar = ; break;
			case kClearCharCode:
				theChar = (aKeyCode==0x47) ? NSInsertFunctionKey : theChar;
				break;
			case kLeftArrowCharCode: theChar = NSLeftArrowFunctionKey; break;
			case kRightArrowCharCode: theChar = NSRightArrowFunctionKey; break;
			case kUpArrowCharCode: theChar = NSUpArrowFunctionKey; break;
			case kDownArrowCharCode: theChar = NSDownArrowFunctionKey; break;
//			case kSpaceCharCode: theChar = ; break;
			case kDeleteCharCode: theChar = NSDeleteCharFunctionKey; break;
//			case kBulletCharCode: theChar = ; break;
//			case kNonBreakingSpaceCharCode: theChar = ; break;
		}
	}
	
	return theChar;
}
	static unichar unicodeForFunctionKey( UInt32 aKeyCode )
	{
		switch( aKeyCode )
		{
			case 0x7A: return NSF1FunctionKey;
			case 0x78: return NSF2FunctionKey;
			case 0x63: return NSF3FunctionKey;
			case 0x76: return NSF4FunctionKey;
			case 0x60: return NSF5FunctionKey;
			case 0x61: return NSF6FunctionKey;
			case 0x62: return NSF7FunctionKey;
			case 0x64: return NSF8FunctionKey;
			case 0x65: return NSF9FunctionKey;
			case 0x6D: return NSF10FunctionKey;
			case 0x67: return NSF11FunctionKey;
			case 0x6F: return NSF12FunctionKey;
			default: return 0x00;
		}
	}

NSString * stringForCharacter( const unsigned short aKeyCode, unichar aCharacter )
{
	NSString		* theString = nil;
	switch( aCharacter )
	{
		case NSUpArrowFunctionKey:
			aCharacter = 0x2191;
			theString = [NSString stringWithCharacters:&aCharacter length:1];
			 break;
		case NSDownArrowFunctionKey:
			aCharacter = 0x2193;
			theString = [NSString stringWithCharacters:&aCharacter length:1];
			break;
		case NSLeftArrowFunctionKey:
			aCharacter = 0x2190;
			theString = [NSString stringWithCharacters:&aCharacter length:1];
			break;
		case NSRightArrowFunctionKey:
			aCharacter = 0x2192;
			theString = [NSString stringWithCharacters:&aCharacter length:1];
			break;
		case NSF1FunctionKey: theString = @"F1"; break;
		case NSF2FunctionKey: theString = @"F2"; break;
		case NSF3FunctionKey: theString = @"F3"; break;
		case NSF4FunctionKey: theString = @"F4"; break;
		case NSF5FunctionKey: theString = @"F5"; break;
		case NSF6FunctionKey: theString = @"F6"; break;
		case NSF7FunctionKey: theString = @"F7"; break;
		case NSF8FunctionKey: theString = @"F8"; break;
		case NSF9FunctionKey: theString = @"F9"; break;
		case NSF10FunctionKey: theString = @"F10"; break;
		case NSF11FunctionKey: theString = @"F11"; break;
		case NSF12FunctionKey: theString = @"F12"; break;
		case NSF13FunctionKey: theString = @"F13"; break;
		case NSF14FunctionKey: theString = @"F14"; break;
		case NSF15FunctionKey: theString = @"F15"; break;
		case NSF16FunctionKey: theString = @"F16"; break;
		case NSF17FunctionKey: theString = @"F17"; break;
		case NSF18FunctionKey: theString = @"F18"; break;
		case NSF19FunctionKey: theString = @"F19"; break;
		case NSF20FunctionKey: theString = @"F20"; break;
		case NSF21FunctionKey: theString = @"F21"; break;
		case NSF22FunctionKey: theString = @"F22"; break;
		case NSF23FunctionKey: theString = @"F23"; break;
		case NSF24FunctionKey: theString = @"F24"; break;
		case NSF25FunctionKey: theString = @"F25"; break;
		case NSF26FunctionKey: theString = @"F26"; break;
		case NSF27FunctionKey: theString = @"F27"; break;
		case NSF28FunctionKey: theString = @"F28"; break;
		case NSF29FunctionKey: theString = @"F29"; break;
		case NSF30FunctionKey: theString = @"F30"; break;
		case NSF31FunctionKey: theString = @"F31"; break;
		case NSF32FunctionKey: theString = @"F32"; break;
		case NSF33FunctionKey: theString = @"F33"; break;
		case NSF34FunctionKey: theString = @"F34"; break;
		case NSF35FunctionKey: theString = @"F35"; break;
		case NSInsertFunctionKey: theString = @"Ins"; break;
		case NSDeleteFunctionKey: theString = @"Delete"; break;
		case NSHomeFunctionKey:
			aCharacter = 0x2196;
			theString = [NSString stringWithCharacters:&aCharacter length:1];
			break;
		case NSBeginFunctionKey: theString = @"Begin"; break;
		case NSEndFunctionKey: theString = @"End"; break;
		case NSPageUpFunctionKey:
		//	aCharacter = 0x21DE;
		//	theString = [NSString stringWithCharacters:&aCharacter length:1];
			theString = @"PgUp";
			break;
		case NSPageDownFunctionKey:
//			aCharacter = 0x21DF;
//			theString = [NSString stringWithCharacters:&aCharacter length:1];
			theString = @"PgDn";
			break;
		case NSPrintScreenFunctionKey: theString = @"Print"; break;
		case NSScrollLockFunctionKey: theString = @"ScrollLock"; break;
		case NSPauseFunctionKey: theString = @"Pause"; break;
		case NSSysReqFunctionKey: theString = @"SysReq"; break;
		case NSBreakFunctionKey: theString = @"Break"; break;
		case NSResetFunctionKey: theString = @"Reset"; break;
		case NSStopFunctionKey: theString = @"Stop"; break;
		case NSMenuFunctionKey: theString = @"Menu"; break;
		case NSUserFunctionKey: theString = @"User"; break;
		case NSSystemFunctionKey: theString = @"System"; break;
		case NSPrintFunctionKey: theString = @"Print"; break;
		case NSClearLineFunctionKey: theString = @"ClearLine"; break;
		case NSClearDisplayFunctionKey: theString = @"ClearDisplay"; break;
		case NSInsertLineFunctionKey: theString = @"InsertLine"; break;
		case NSDeleteLineFunctionKey: theString = @"DeleteLine"; break;
		case NSInsertCharFunctionKey: theString = @"InsertChar"; break;
		case NSDeleteCharFunctionKey:
			aCharacter = 0x2326;
			theString = [NSString stringWithCharacters:&aCharacter length:1];
			break;
		case NSPrevFunctionKey: theString = @"Prev"; break;
		case NSNextFunctionKey: theString = @"Next"; break;
		case NSSelectFunctionKey: theString = @"Select"; break;
		case NSExecuteFunctionKey: theString = @"Exec"; break;
		case NSUndoFunctionKey: theString = @"Undo"; break;
		case NSRedoFunctionKey: theString = @"Redo"; break;
		case NSFindFunctionKey: theString = @"Find"; break;
		case NSHelpFunctionKey: theString = @"Help"; break;
		case NSModeSwitchFunctionKey: theString = @"ModeSwitch"; break;
		case kEscapeCharCode: theString = @"Esc"; break;
		case kTabCharCode:
			aCharacter = 0x21E5;
			theString = [NSString stringWithCharacters:&aCharacter length:1];
			break;
		case kSpaceCharCode: theString = @"Space"; break;
		case kEnterCharCode:
			aCharacter = 0x21B5;
			theString = [NSString stringWithCharacters:&aCharacter length:1];
			break;
		case kReturnCharCode:
			aCharacter = 0x21A9;
			theString = [NSString stringWithCharacters:&aCharacter length:1];
			break;
		case kDeleteCharCode: theString = @"Del"; break;
		case '0'...'9':
		case '=':
		case '/':
		case '*':
		case '-':
		case '+':
		case '.':
			theString = [NSString stringWithCharacters:&aCharacter length:1];
			if( aKeyCode > 60 )
				theString = [NSString stringWithFormat:@"[%@]", theString];
			break;
		default:
			aCharacter = unicharForKeyCode(aKeyCode);

			if( aCharacter >= 'a' && aCharacter <= 'z' )		// convert to uppercase
				aCharacter = aCharacter + 'A' - 'a';

			theString = [NSString stringWithCharacters:&aCharacter length:1];
			break;
	}
	return theString;
}

NSString * stringForModifiers( unsigned int aModifierFlags )
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
