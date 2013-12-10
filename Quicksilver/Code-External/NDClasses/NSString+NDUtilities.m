/*
	NSString+NDUtilities.m

	Created by Nathan Day on 14.12.02 under a MIT-style license. 
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

#import "NSString+NDUtilities.h"
#import "IntegerMath.h"

/*
 * class implementation NSString (NDUtilities)
 */
@implementation NSString (NDUtilities)

+ (id)stringWithNonLossyASCIIString:(const char *)anASCIIString
{
	return [[[self alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)anASCIIString length:strlen(anASCIIString) freeWhenDone:NO] encoding:NSNonLossyASCIIStringEncoding] autorelease];
}

+ (id)stringWithFormat:(NSString *)aFormat arguments:(va_list)anArgList
{
	return [[[self alloc] initWithFormat:aFormat arguments:anArgList] autorelease];
}

- (id)initWithNonLossyASCIIString:(const char *)anASCIIString
{
	return [self initWithData:[NSData dataWithBytesNoCopy:(void *)anASCIIString length:(NSUInteger)strlen(anASCIIString) freeWhenDone:NO] encoding:NSNonLossyASCIIStringEncoding];
}

- (const char *)nonLossyASCIIString
{
	NSMutableData	* theData;
	char				theNullTerminator = '\0';
	theData  = [NSMutableData dataWithData:[self dataUsingEncoding:NSNonLossyASCIIStringEncoding]];
	[theData appendBytes:&theNullTerminator length:1];
	return (const char *)[theData bytes];
}

/*
	-isCaseInsensitiveEqualToString:
 */
- (BOOL)isCaseInsensitiveEqualToString:(NSString *)aString
{
	return [self compare:aString options:NSCaseInsensitiveSearch range:NSMakeRange( 0, [self length]) locale:nil] == 0;
}

/*
	-hasCaseInsensitivePrefix:
 */
- (BOOL)hasCaseInsensitivePrefix:(NSString *)aString
{
	return [[self substringToIndex:[aString length]] compare:aString options:NSCaseInsensitiveSearch range:NSMakeRange( 0, [self length]) locale:nil] == 0;
}

/*
	-hasCaseInsensitiveSuffix:
 */
- (BOOL)hasCaseInsensitiveSuffix:(NSString *)aString
{
	return [[self substringToIndex:[aString length]] compare:aString options:NSCaseInsensitiveSearch range:NSMakeRange( 0, [self length]) locale:nil] == 0;
}

/*
	-containsString:
 */
- (BOOL)containsString:(NSString *)aSubString
{
	return [self containsString:aSubString options:0];
}

/*
	-containsString:options:
 */
- (BOOL)containsString:(NSString *)aSubString options:(unsigned)aMask
{
	NSRange	theRange;
	theRange.location = 0;
	theRange.length = [self length];
	return [self containsString:aSubString options:aMask range:theRange];
}

/*
	-containsString:options:range:
 */
- (BOOL)containsString:(NSString *)aSubString options:(unsigned)aMask range:(NSRange)aRange
{
	NSRange		theRange;

	theRange = [self rangeOfString:aSubString options:aMask range:aRange];
	return theRange.location != NSNotFound && theRange.length != 0;
}

/*
	-indexOfCharacter:range:
 */
- (unsigned int)indexOfCharacter:(unichar)aCharacter range:(NSRange)aRange
{
	NSUInteger theIndex, theCount = [self length], theFoundIndex = NSNotFound;

	if( aRange.length + aRange.location > theCount )
		[NSException raise:NSRangeException format:@"[%@ %@]: Range or index out of bounds", NSStringFromClass([self class]), NSStringFromSelector(_cmd)];

	for( theIndex = aRange.location; theIndex < theCount && theFoundIndex == NSNotFound; theIndex++ )
	{
		if([self characterAtIndex:theIndex] == aCharacter)
			theFoundIndex = theIndex;
	}

	return theFoundIndex;
}

/*
	-indexOfCharacter:
 */
- (unsigned int)indexOfCharacter:(unichar)aCharacter
{
	return [self indexOfCharacter:aCharacter range:NSMakeRange( 0, [self length] )];
}

/*
	-containsAnyCharacterFromSet:
 */
- (BOOL)containsAnyCharacterFromSet:(NSCharacterSet *)aSet
{
	return [self rangeOfCharacterFromSet:aSet].location != NSNotFound;
}

/*
	-containsAnyCharacterFromSet:options:
 */
- (BOOL)containsAnyCharacterFromSet:(NSCharacterSet *)aSet options:(unsigned int)aMask
{
	return [self rangeOfCharacterFromSet:aSet options:aMask].location != NSNotFound;
}

/*
	-containsAnyCharacterFromSet:options:range:
 */
- (BOOL)containsAnyCharacterFromSet:(NSCharacterSet *)aSet options:(unsigned int)aMask range:(NSRange)aRange
{
	return [self rangeOfCharacterFromSet:aSet options:aMask range:aRange].location != NSNotFound;
}

/*
	-containsOnlyCharactersFromSet:
 */
- (BOOL)containsOnlyCharactersFromSet:(NSCharacterSet *)aSet
{
	return [self rangeOfCharacterFromSet:[aSet invertedSet]].location == NSNotFound;
}

/*
	-containsOnlyCharactersFromSet:options:
 */
- (BOOL)containsOnlyCharactersFromSet:(NSCharacterSet *)aSet options:(unsigned int)aMask
{
	return [self rangeOfCharacterFromSet:[aSet invertedSet] options:aMask].location == NSNotFound;
}

/*
	-containsOnlyCharactersFromSet:options:range:
 */
- (BOOL)containsOnlyCharactersFromSet:(NSCharacterSet *)aSet options:(unsigned int)aMask range:(NSRange)aRange
{
	return [self rangeOfCharacterFromSet:[aSet invertedSet] options:aMask range:aRange].location == NSNotFound;
}

/*
	-indexOfMatchingStringInList:defaultValue:
 */
- (unsigned int)indexOfMatchingStringInList:(NSString **)anArray defaultValue:(unsigned int)aDefaultValue
{
	unsigned int		theIndex = 0,
						theFoundIndex = UINT_MAX;

	for( theIndex = 0; anArray[theIndex] != nil && theFoundIndex == UINT_MAX; theIndex++ )
	{
		if( [self isEqualToString:anArray[theIndex]] )
			theFoundIndex = theIndex;									// RETURN
	}
	return theFoundIndex != UINT_MAX ? theFoundIndex : aDefaultValue;
}

/*
	-stringByQuoting
 */
- (NSString *)stringByQuoting
{
	NSMutableString		* theString = [NSMutableString stringWithString:self];
	[theString replaceOccurrencesOfString:@"\\"
							   withString:@"\\\\"
								  options:0
									range:NSMakeRange(0,[self length])];
	[theString replaceOccurrencesOfString:@"\""
							   withString:@"\\\""
								  options:0
									range:NSMakeRange(0,[self length])];
	return [NSString stringWithFormat:@"\"%@\"", theString];
}

- (NSRange)rangeOfStringEnclosedIn:(NSString *)aStartString and:(NSString *)anEndString includeEncloseString:(BOOL)anIncludeEnclose mode:(int)aMode
{
	NSRange		theRange = NSMakeRange( UINT_MAX, UINT_MAX );
	unsigned int	theLenOfStart = [aStartString length],
						theLenOfEnd = [anEndString length];
	
	switch( aMode )
	{
		default:
		case simpleEnclosed:
			theRange = [self rangeOfString:aStartString];
			theRange.length = [self length] - theRange.location;
			theRange.length = [self rangeOfString:anEndString options:0 range:theRange].location - theRange.location;
			
			if( anIncludeEnclose )
				theRange.length += theLenOfEnd;
			else
			{
				theRange.location += theLenOfStart;
				theRange.length -= theLenOfStart;
			}
			break;
		case outerEnclosed:
			break;
		case innerEnclosed:
			break;
	}
	return theRange;
}

+ (NSString *)stringFromDictionary:(NSDictionary *)aDictionary withFormat:(NSString *)aFormat, ...
{
	NSString		*theResult = nil;
	va_list			theArgument;
	va_start( theArgument, aFormat );
	theResult = [NSString stringFromDictionary:aDictionary withFormat:aFormat arguments:theArgument];
	va_end( theArgument );
	return theResult;
}

+ (NSString *)stringFromDictionary:(NSDictionary *)aDictionary withFormat:(NSString *)aFormat arguments:(va_list)anArguments
{
	NSMutableString		* theResult = nil;
	NSScanner			* theScanner = [NSScanner scannerWithString:aFormat];
	NSString			* theSubString = nil;
	id					theKey = va_arg( anArguments, id);
	
	[theScanner setCharactersToBeSkipped:nil];
	theResult = [[NSMutableString alloc] init];

	while( ![theScanner isAtEnd] && theKey != nil )
	{
		if( [theScanner scanUpToString:@"%@" intoString:&theSubString] )
			[theResult appendString:theSubString];
		[theResult appendString:[[aDictionary objectForKey:theKey] description]];
		[theScanner scanString:@"%@" intoString:NULL];
		theKey = va_arg( anArguments, id);
	}
	
	if( ![theScanner isAtEnd] && [theScanner scanUpToString:@"" intoString:&theSubString] )
		[theResult appendString:theSubString];

	return theResult;
}

- (unsigned int)indexOfCharacater:(unichar)aChar
{
	return [self indexOfCharacater:(unichar)aChar options:0 range:NSMakeRange(0, [self length])];
}

- (unsigned int)indexOfCharacater:(unichar)aChar options:(NSStringCompareOptions)anOptions
{
	return [self indexOfCharacater:(unichar)aChar options:anOptions range:NSMakeRange(0, [self length])];
}

- (unsigned int)indexOfCharacater:(unichar)aChar options:(NSStringCompareOptions)anOptions range:(NSRange)aRange
{
	return [self rangeOfString:[NSString stringWithCharacters:&aChar length:1] options:anOptions range:aRange].location;
}

/*
	-componentsSeparatedByString:withOpeningQuote:closingQuote:singleQuote:includeEmptyComponents:
 */
- (NSArray *)componentsSeparatedByString:(NSString *)aSeparator withOpeningQuote:(NSString *)aOpeningQuote closingQuote:(NSString *)aClosingQuote singleQuote:(NSString *)aSingleQuote includeEmptyComponents:(BOOL)aFlag
{
	NSMutableArray		* theComponentArray = [NSMutableArray array];
	unsigned int		theTokenEnd = 0,
						theLength = [self length],
						theSeperatorLen = [aSeparator length],
						theSingleQuoteLen = [aSingleQuote length],
						theOpeningQuoteLen = [aOpeningQuote length],
						theClosingQuoteLen = [aClosingQuote length];
	BOOL				theInQuotes = NO;

	NSMutableString		* theComponet = [NSMutableString string];

	while(  theTokenEnd < theLength )
	{
		if( aSingleQuote && [[self substringFromIndex:theTokenEnd] hasPrefix:aSingleQuote] )
		{
			theTokenEnd += theSingleQuoteLen;

			if( theTokenEnd < theLength )
			{
				[theComponet appendString:[self substringWithRange:NSMakeRange(theTokenEnd , 1)]];
				theTokenEnd++;
			}
		}
		else if( theInQuotes == NO && aOpeningQuote && [[self substringFromIndex:theTokenEnd] hasPrefix:aOpeningQuote] )
		{
			theTokenEnd += theOpeningQuoteLen;
			theInQuotes = YES;
		}
		else if( theInQuotes == YES && aClosingQuote && [[self substringFromIndex:theTokenEnd] hasPrefix:aClosingQuote] )
		{
			theTokenEnd += theClosingQuoteLen;
			theInQuotes = NO;
		}
		else if( theInQuotes == NO && [[self substringFromIndex:theTokenEnd] hasPrefix:aSeparator] )
		{
			if( aFlag || ![theComponet isEqualToString:@""] )
			{
				[theComponentArray addObject:theComponet];
				theComponet = [NSMutableString string];
			}

			theTokenEnd += theSeperatorLen;
		}
		else
		{
			[theComponet appendString:[self substringWithRange:NSMakeRange(theTokenEnd , 1)]];

			theTokenEnd++;
		}
	}
	
	if( ![theComponet isEqualToString:@""] )
	{
		[theComponentArray addObject:theComponet];
		theComponet = [NSMutableString string];
	}
	
	return theComponentArray;
}

/*
	-stringByReplacingString:withString:
 */
- (NSString *)stringByReplacingString:(NSString *)aSearchString withString:(NSString *)aReplaceString
{
#if MAC_OS_X_VERSION_10_5 <= MAC_OS_X_VERSION_MAX_ALLOWED
	return [self stringByReplacingOccurrencesOfString:aSearchString withString:aReplaceString];
#else
	return [[self componentsSeparatedByString:aSearchString] componentsJoinedByString:aReplaceString];
#endif
}

/*
	-stringByReplacingCharacterRunsFromSet:withString:
 */
- (NSString *)stringByReplacingCharacterRunsFromSet:(NSCharacterSet *)aSet withString:(NSString *)aReplacement
{
	NSMutableString		* theResult = [NSMutableString string];
	NSCharacterSet		* theInverseSet = [aSet invertedSet];
	NSRange				theStartRange = [self rangeOfCharacterFromSet:theInverseSet],
						theEndRange = NSMakeRange( 1, 0 );
	unsigned int		theLength = [self length];

	while( theStartRange.location != NSNotFound )
	{
		NSString	* theSubStr = nil;
		theEndRange = [self rangeOfCharacterFromSet:aSet options:0 range:NSMakeRange(theStartRange.location + theStartRange.length, theLength - (theStartRange.location + theStartRange.length))];
		if( theEndRange.location == NSNotFound )
			theEndRange.location = theLength;
		theSubStr = [self substringWithRange:NSMakeRange(theStartRange.location,theEndRange.location-theStartRange.location)];
		[theResult appendString:theSubStr];
		
		theStartRange = [self rangeOfCharacterFromSet:theInverseSet options:0 range:NSMakeRange(theEndRange.location + theEndRange.length, theLength - (theEndRange.location + theEndRange.length))];

		if( theStartRange.location != NSNotFound && aReplacement )
			[theResult appendString:aReplacement];
	}

	return theResult;
}

- (NSRange)rangeOfCharacterRunFromSet:(NSCharacterSet *)aSet
{
	return [self rangeOfCharacterRunFromSet:aSet options:0 range:NSMakeRange(0,[self length])];
}

- (NSRange)rangeOfCharacterRunFromSet:(NSCharacterSet *)aSet options:(NSStringCompareOptions)aMask
{
	return [self rangeOfCharacterRunFromSet:aSet options:aMask range:NSMakeRange(0,[self length])];
}

- (NSRange)rangeOfCharacterRunFromSet:(NSCharacterSet *)aSet options:(NSStringCompareOptions)aMask range:(NSRange)aRange
{
	NSRange			theResultRange = NSMakeRange(NSNotFound, 0),
					theStartRange = [self rangeOfCharacterFromSet:aSet options:aMask range:aRange];
	if( theStartRange.location != NSNotFound )
	{
		NSRange		theEndRange;
		aRange.length -= (theStartRange.location - aRange.location);
		aRange.location = theStartRange.location;
		
		theEndRange = [self rangeOfCharacterFromSet:[aSet invertedSet] options:aMask range:aRange];

		theResultRange.location = theStartRange.location;
		theResultRange.length = theEndRange.location != NSNotFound
									? theEndRange.location - theStartRange.location
									: aRange.location + aRange.length - theStartRange.location;
	}
	return theResultRange;
}

@end

@implementation NSMutableString (NDUtilities)

- (void)prependString:(NSString *)aString
{
	[self insertString:aString atIndex:0];
}

- (void)prependFormat:(NSString *)aFormat, ...
{
	va_list				theArgList;
	va_start( theArgList, aFormat );
	[self insertString:[NSString stringWithFormat:aFormat arguments:theArgList] atIndex:0];
	va_end( theArgList );	
}

@end
