/*
	NDKeyboardLayout.m

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

#import "NDKeyboardLayout.h"
#include <libkern/OSAtomic.h>

struct ReverseMappingEntry
{
	UniChar		character;
	BOOL		keypad;
	UInt16		keyCode;
};

struct UnmappedEntry
{
	UniChar		character;
	UInt16		keyCode;
	unichar		description[4];
};

struct UnmappedEntry	unmappedKeys[] =
{
	{NSDeleteFunctionKey, 0x33, {0x232B,'\0','\0','\0'}},
	{NSF17FunctionKey, 0x40, {'F','1','7','\0'}},
	{NSClearDisplayFunctionKey, 0x47, {0x2327,'\0','\0','\0'}},
	{NSF18FunctionKey, 0x4F, {'F','1','8','\0'}},
	{NSF19FunctionKey, 0x50, {'F','1','9','\0'}},
	{NSF5FunctionKey, 0x60, {'F','5','\0','\0'}},
	{NSF6FunctionKey, 0x61, {'F','6','\0','\0'}},
	{NSF7FunctionKey, 0x62, {'F','7','\0','\0'}},
	{NSF3FunctionKey, 0x63, {'F','3','\0','\0'}},
	{NSF8FunctionKey, 0x64, {'F','8','\0','\0'}},
	{NSF9FunctionKey, 0x65, {'F','9','\0','\0'}},
	{NSF11FunctionKey, 0x67, {'F','1','1','\0'}},
	{NSF14FunctionKey, 0x68, {'F','1','4','\0'}},
	{NSF13FunctionKey, 0x69, {'F','1','3','\0'}},
	{NSF16FunctionKey, 0x6A, {'F','1','6','\0'}},
	{NSF10FunctionKey, 0x6D, {'F','1','0','\0'}},
	{NSF12FunctionKey, 0x6F, {'F','1','2','\0'}},
	{NSF15FunctionKey, 0x71, {'F','1','5','\0'}},
	{NSHomeFunctionKey, 0x73, {0x21F1,'\0','\0','\0'}},
	{NSPageUpFunctionKey, 0x74, {0x21DE,'\0','\0','\0'}},
	{NSDeleteCharFunctionKey, 0x75, {0x2326,'\0','\0','\0'}},
	{NSF4FunctionKey, 0x76, {'F','4','\0','\0'}},
	{NSEndFunctionKey, 0x77, {0x21F2,'\0','\0','\0'}},
	{NSF2FunctionKey, 0x78, {'F','2','\0','\0'}},
	{NSPageDownFunctionKey, 0x79, {0x21DF,'\0','\0','\0'}},
	{NSF1FunctionKey, 0x7A, {'F','1','\0','\0'}},
	{NSLeftArrowFunctionKey, 0x7B, {0x2190,'\0','\0','\0'}},
	{NSRightArrowFunctionKey, 0x7C, {0x2192,'\0','\0','\0'}},
	{NSDownArrowFunctionKey, 0x7D, {0x2193,'\0','\0','\0'}},
	{NSUpArrowFunctionKey, 0x7E, {0x2191,'\0','\0','\0'}}
//	{NSF20FunctionKey, 0xXXXX},
//	{NSF21FunctionKey, 0xXXXX},
//	{NSF22FunctionKey, 0xXXXX},
//	{NSF23FunctionKey, 0xXXXX},
//	{NSF24FunctionKey, 0xXXXX},
//	{NSF25FunctionKey, 0xXXXX},
//	{NSF26FunctionKey, 0xXXXX},
//	{NSF27FunctionKey, 0xXXXX},
//	{NSF28FunctionKey, 0xXXXX},
//	{NSF29FunctionKey, 0xXXXX},
//	{NSF30FunctionKey, 0xXXXX},
//	{NSF31FunctionKey, 0xXXXX},
//	{NSF32FunctionKey, 0xXXXX},
//	{NSF33FunctionKey, 0xXXXX},
//	{NSF34FunctionKey, 0xXXXX},
//	{NSF35FunctionKey, 0xXXXX},
//	{NSInsertFunctionKey, 0xXXXX},
//	{NSBeginFunctionKey, 0xXXXX},
//	{NSPrintScreenFunctionKey, 0xXXXX},
//	{NSScrollLockFunctionKey, 0xXXXX},
//	{NSPauseFunctionKey, 0xXXXX},
//	{NSSysReqFunctionKey, 0xXXXX},
//	{NSBreakFunctionKey, 0xXXXX},
//	{NSResetFunctionKey, 0xXXXX},
//	{NSStopFunctionKey, 0xXXXX},
//	{NSMenuFunctionKey, 0xXXXX},
//	{NSUserFunctionKey, 0xXXXX},
//	{NSSystemFunctionKey, 0xXXXX},
//	{NSPrintFunctionKey, 0xXXXX},
//	{NSClearLineFunctionKey, 0xXXXX},
//	{NSInsertLineFunctionKey, 0xXXXX},
//	{NSDeleteLineFunctionKey, 0xXXXX},
//	{NSInsertCharFunctionKey, 0xXXXX},
//	{NSPrevFunctionKey, 0xXXXX},
//	{NSNextFunctionKey, 0xXXXX},
//	{NSSelectFunctionKey, 0xXXXX},
//	{NSExecuteFunctionKey, 0xXXXX},
//	{NSUndoFunctionKey, 0xXXXX},
//	{NSRedoFunctionKey, 0xXXXX},
//	{NSFindFunctionKey, 0xXXXX},
//	{NSHelpFunctionKey, 0xXXXX},
//	{NSModeSwitchFunctionKey, 0xXXXX}
};

static int _reverseMappingEntryCmpFunc( const void * a, const void * b )
{
	struct ReverseMappingEntry		* theA = (struct ReverseMappingEntry*)a,
									* theB = (struct ReverseMappingEntry*)b;
	return theA->character != theB->character ? theA->character - theB->character : theA->keypad - theB->keypad;
}

static struct ReverseMappingEntry * _searchreverseMapping( struct ReverseMappingEntry * aMapping, NSUInteger aLength, struct ReverseMappingEntry * aSearchValue )
{
    NSInteger	low = 0,
				high = aLength - 1,
				mid,
				result;
    
    while( low <= high )
	{
        mid = (low + high)>>1;
        result = _reverseMappingEntryCmpFunc( &aMapping[mid], aSearchValue );
        if( result > 0 )
            high = mid - 1;
        else if( result < 0 )
            low = mid + 1;
        else
            return &aMapping[mid];
    }
    return NULL;
}

static struct UnmappedEntry * _unmappedEntryForKeyCode( UInt16 aKeyCode )
{
    NSInteger	low = 0,
				high = sizeof(unmappedKeys)/sizeof(*unmappedKeys) - 1,
				mid,
				result;
    
    while( low <= high )
	{
        mid = (low + high)>>1;
        result = unmappedKeys[mid].keyCode - aKeyCode;
        if( result > 0 )
            high = mid - 1;
        else if( result < 0 )
            low = mid + 1;
        else
            return &unmappedKeys[mid];
    }
    return '\0';
}

static const size_t			kBufferSize = 4;
static NSUInteger _characterForModifierFlags( unichar aBuff[kBufferSize], UInt32 aModifierFlags )
{
	NSUInteger		thePos = 0;
	memset( aBuff, 0, kBufferSize );
	if(aModifierFlags & NSControlKeyMask)
		aBuff[thePos++] = kControlUnicode;
	
	if(aModifierFlags & NSAlternateKeyMask)
		aBuff[thePos++] = kOptionUnicode;
	
	if(aModifierFlags & NSShiftKeyMask)
		aBuff[thePos++] = kShiftUnicode;
	
	if(aModifierFlags & NSCommandKeyMask)
		aBuff[thePos++] = kCommandUnicode;
	return thePos;
}

/*
 * NDCocoaModifierFlagsForCarbonModifierFlags()
 */
NSUInteger NDCocoaModifierFlagsForCarbonModifierFlags( UInt32 aModifierFlags )
{
	NSUInteger	theCocoaModifierFlags = 0;
	
	if(aModifierFlags & shiftKey)
		theCocoaModifierFlags |= NSShiftKeyMask;
	
	if(aModifierFlags & controlKey)
		theCocoaModifierFlags |= NSControlKeyMask;
	
	if(aModifierFlags & optionKey)
		theCocoaModifierFlags |= NSAlternateKeyMask;
	
	if(aModifierFlags & cmdKey)
		theCocoaModifierFlags |= NSCommandKeyMask;
	
	return theCocoaModifierFlags;
}

/*
 * NDCarbonModifierFlagsForCocoaModifierFlags()
 */
UInt32 NDCarbonModifierFlagsForCocoaModifierFlags( NSUInteger aModifierFlags )
{
	UInt32	theCarbonModifierFlags = 0;
	
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

@interface NDKeyboardLayout (Private)
- (const UCKeyboardLayout *)keyboardLayout;
@end

@implementation NDKeyboardLayout

#pragma mark Utility Methods

- (void)generateMappings
{
	mappings = (struct ReverseMappingEntry*)calloc( 128 + sizeof(unmappedKeys)/sizeof(*unmappedKeys), sizeof(struct ReverseMappingEntry) );

	numberOfMappings = 0;
	
	for( NSUInteger i = 0; i < 128; i++ )
	{
		UInt32			theDeadKeyState = 0;
		UniCharCount	theLength = 0;

		if( UCKeyTranslate( [self keyboardLayout],
							   i,
							   kUCKeyActionDisplay,
							   0,
							   LMGetKbdType(),
							   kUCKeyTranslateNoDeadKeysBit,
							   &theDeadKeyState,
							   1,
							   &theLength,
							   &mappings[numberOfMappings].character ) == noErr && theLength > 0 && isprint(mappings[numberOfMappings].character) )
		{
			mappings[numberOfMappings].keyCode = i;
			numberOfMappings++;
		}
	}
	
	/*	add unmapped keys	*/
	for( NSUInteger i = 0; i < sizeof(unmappedKeys)/sizeof(*unmappedKeys); i++ )
	{
		mappings[numberOfMappings].character = unmappedKeys[i].character;
		mappings[numberOfMappings].keyCode = unmappedKeys[i].keyCode;
		numberOfMappings++;
	}
	
	mappings = (struct ReverseMappingEntry*)realloc( (void*)mappings, numberOfMappings*sizeof(struct ReverseMappingEntry) );

	// sort so we can perform binary searches
	qsort( (void *)mappings, numberOfMappings, sizeof(struct ReverseMappingEntry), _reverseMappingEntryCmpFunc );

	/* find keypad keys and set the keypad flag	*/
	for( NSUInteger i = 1; i < numberOfMappings; i++ )
	{
		NSParameterAssert( mappings[i-1].keyCode != mappings[i].keyCode );
		if( mappings[i-1].character == mappings[i].character )	// assume large keycode is a keypad
		{
			if( mappings[i-1].keyCode > mappings[i].keyCode )		// make the keypad entry is second
			{
				UInt16		theTemp = mappings[i-1].keyCode;
				mappings[i-1].keyCode = mappings[i].keyCode;
				mappings[i].keyCode = theTemp;
			}
			mappings[i].keypad = YES;
		}
	}

#ifdef DEBUGGING_CODE
	for( NSUInteger i = 1; i < numberOfMappings; i++ )
	{
		fprintf( stderr, "%d -> %c[%d]%s\n",
				mappings[i].keyCode,
				(char)mappings[i].character,
				mappings[i].character,
				mappings[i].keypad ? " keypad" : ""
				);
		NSAssert3( mappings[i-1].character <= mappings[i].character, @"[%d] %d <= %d", i, mappings[i-1].character, mappings[i].character );
	}
#endif
}

#pragma mark Constructor Methods

+ (id)keyboardLayout
{
	static volatile NDKeyboardLayout		* kCurrentKeyboardLayout = nil;
	if( kCurrentKeyboardLayout == nil )
	{
		@synchronized(self)
		{	/*
				Try different method until we succeed.
			 */
			if( kCurrentKeyboardLayout == nil )
				kCurrentKeyboardLayout = [[self alloc] initWithInputSource:TISCopyInputMethodKeyboardLayoutOverride()];
			if( kCurrentKeyboardLayout == nil )
				kCurrentKeyboardLayout = [[self alloc] initWithInputSource:TISCopyCurrentKeyboardLayoutInputSource()];
			if( kCurrentKeyboardLayout == nil )
				kCurrentKeyboardLayout = [[self alloc] initWithInputSource:TISCopyCurrentASCIICapableKeyboardLayoutInputSource()];
		}
	}

	return kCurrentKeyboardLayout;
}

- (id)init
{
	[self release];
	return [[NDKeyboardLayout keyboardLayout] retain];
}

- (id)initWithLanguage:(NSString *)aLangauge
{
	return [self initWithInputSource:TISCopyInputSourceForLanguage((CFStringRef)aLangauge)];
}

- (id)initWithInputSource:(TISInputSourceRef)aSource
{
	if( (self = [super init]) != nil )
	{
		if( aSource != NULL && (keyboardLayoutData = (CFDataRef)CFMakeCollectable(TISGetInputSourceProperty(aSource, kTISPropertyUnicodeKeyLayoutData))) != nil )
			CFRetain( keyboardLayoutData );
		else
		{
			[self release];
			self = nil;
		}
	}
	return self;
}

- (void)dealloc
{
	if( mappings != NULL )
		free( (void*)mappings );
	if( keyboardLayoutData != NULL )
		CFRelease( keyboardLayoutData );
	[super dealloc];
}

- (NSString*)stringForCharacter:(unichar)aCharacter modifierFlags:(UInt32)aModifierFlags
{
	return [self stringForKeyCode:[self keyCodeForCharacter:aCharacter numericPad:(aModifierFlags&NSNumericPadKeyMask) != 0] modifierFlags:aModifierFlags];
}

- (NSString*)stringForKeyCode:(UInt16)aKeyCode modifierFlags:(UInt32)aModifierFlags
{
	NSString				* theResult = nil;
	struct UnmappedEntry	* theEntry = _unmappedEntryForKeyCode( aKeyCode );		// is it one of the unmapped values
	
	if( theEntry != NULL )
	{
		unichar		theCharacter[sizeof(theEntry->description)/sizeof(*theEntry->description)+4+1];
		memset( theCharacter, 0, sizeof(theCharacter) );
		NSUInteger	thePos = _characterForModifierFlags(theCharacter,aModifierFlags);
		memcpy( theCharacter+thePos, theEntry->description, sizeof(theEntry->description) );
		theResult = [NSString stringWithCharacters:theCharacter length:sizeof(theEntry->description)/sizeof(*theEntry->description)+thePos];
	}
	else
	{
		UInt32			theDeadKeyState = 0;
		UniCharCount	theLength = 0;
		UniChar			theCharacter[260];

		NSUInteger		thePos = _characterForModifierFlags(theCharacter,aModifierFlags);

		if( UCKeyTranslate( [self keyboardLayout], aKeyCode,
							 kUCKeyActionDisplay,
							 NDCarbonModifierFlagsForCocoaModifierFlags(aModifierFlags),
							 LMGetKbdType(),
							 kUCKeyTranslateNoDeadKeysBit,
							 &theDeadKeyState,
							 sizeof(theCharacter)/sizeof(*theCharacter)-thePos,
							 &theLength,
							 theCharacter+thePos ) == noErr )
		{

			theResult = [[NSString stringWithCharacters:theCharacter length:theLength+thePos] uppercaseString];
		}
	}
	return theResult;
}

- (unichar)characterForKeyCode:(UInt16)aKeyCode
{
	unichar					theChar = 0;		// is it one of the unmapped values
	struct UnmappedEntry *	theEntry = _unmappedEntryForKeyCode( aKeyCode );		// is it one of the unmapped values

	if( theEntry != NULL )
	{
		theChar  = theEntry->character;
	}
	else
	{
		UInt32			theDeadKeyState = 0;
		UniCharCount	theLength = 0;
		UniChar			theCharacter[256];
		
		if( UCKeyTranslate( [self keyboardLayout], aKeyCode,
						   kUCKeyActionDisplay,
						   0,
						   LMGetKbdType(),
						   kUCKeyTranslateNoDeadKeysBit,
						   &theDeadKeyState,
						   sizeof(theCharacter)/sizeof(*theCharacter),
						   &theLength,
						   theCharacter ) == noErr )
		{
			theChar = theCharacter[0];
		}
	}
	return toupper(theChar);
}

- (UInt16)keyCodeForCharacter:(unichar)aCharacter
{
	return [self keyCodeForCharacter:aCharacter numericPad:NO];
}

- (UInt16)keyCodeForCharacter:(unichar)aCharacter numericPad:(BOOL)aNumericPad
{
	struct ReverseMappingEntry	theSearchValue = { tolower(aCharacter), aNumericPad, 0 };
	struct ReverseMappingEntry	* theEntry = NULL;
	if( mappings == NULL )
		[self generateMappings];
	theEntry = _searchreverseMapping( mappings, numberOfMappings, &theSearchValue );
	return theEntry ? theEntry->keyCode : '\0';
}

@end

@implementation NDKeyboardLayout (Private)
- (const UCKeyboardLayout *)keyboardLayout
{
	return (const UCKeyboardLayout *)CFDataGetBytePtr(keyboardLayoutData);
}

@end

