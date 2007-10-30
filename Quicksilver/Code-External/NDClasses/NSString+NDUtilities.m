/*
 *  NSString+NDUtilities.m category
 *  Popup Dock
 *
 *  Created by Nathan Day on Sun Dec 14 2003.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "NSString+NDUtilities.h"

/*
 * class implementation NSString (NDUtilities)
 */
@implementation NSString (NDUtilities)

+ (id)stringWithNonLossyASCIIString:(const char *)anASCIIString
{
	return [[[self alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)anASCIIString  length:strlen(anASCIIString) freeWhenDone:NO] encoding:NSNonLossyASCIIStringEncoding] autorelease];
}

+ (id)stringWithFormat:(NSString *)aFormat arguments:(va_list)anArgList
{
	return [[[self alloc] initWithFormat:aFormat arguments:anArgList] autorelease];
}

- (id)initWithNonLossyASCIIString:(const char *)anASCIIString
{
	return [self initWithData:[NSData dataWithBytesNoCopy:(void *)anASCIIString  length:strlen(anASCIIString) freeWhenDone:NO] encoding:NSNonLossyASCIIStringEncoding];
}

- (const char *)nonLossyASCIIString
{
	return (const char *)[[self dataUsingEncoding:NSNonLossyASCIIStringEncoding] bytes];
}

/*
 * -isCaseInsensitiveEqualToString:
 */
- (BOOL)isCaseInsensitiveEqualToString:(NSString *)aString
{
	return [self compare:aString options:NSCaseInsensitiveSearch range:NSMakeRange( 0, [self length]) locale:nil] == 0;
}

/*
 * -hasCaseInsensitivePrefix:
 */
- (BOOL)hasCaseInsensitivePrefix:(NSString *)aString
{
	return [[self substringToIndex:[aString length]] compare:aString options:NSCaseInsensitiveSearch range:NSMakeRange( 0, [self length]) locale:nil] == 0;
}

/*
 * -hasCaseInsensitiveSuffix:
 */
- (BOOL)hasCaseInsensitiveSuffix:(NSString *)aString
{
	return [[self substringToIndex:[aString length]] compare:aString options:NSCaseInsensitiveSearch range:NSMakeRange( 0, [self length]) locale:nil] == 0;
}

/*
 * -containsString:
 */
- (BOOL)containsString:(NSString *)aSubString
{
	return [self containsString:aSubString options:0];
}

/*
 * -containsString:options:
 */
- (BOOL)containsString:(NSString *)aSubString options:(unsigned)aMask
{
	NSRange	theRange;
	theRange.location = 0;
	theRange.length = [self length];
	return [self containsString:aSubString options:aMask range:theRange];
}

/*
 * -containsString:options:range:
 */
- (BOOL)containsString:(NSString *)aSubString options:(unsigned)aMask range:(NSRange)aRange
{
	NSRange		theRange;

	theRange = [self rangeOfString:aSubString options:aMask range:aRange];
	return theRange.location != NSNotFound && theRange.length != 0;
}

/*
 * -indexOfCharacter:range:
 */
- (unsigned int)indexOfCharacter:(unichar)aCharacter range:(NSRange)aRange
{
	unsigned int	theIndex,
						theCount = [self length],
						theFoundIndex = NSNotFound;

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
 * -indexOfCharacter:
 */
- (unsigned int)indexOfCharacter:(unichar)aCharacter
{
	return [self indexOfCharacter:aCharacter range:NSMakeRange( 0, [self length] )];
}

/*
 * -containsCharacter:
 */
- (BOOL)containsCharacter:(unichar)aCharacter
{
	return [self indexOfCharacter:aCharacter] != NSNotFound;
}

/*
 * -containsCharacter:range:
 */
- (BOOL)containsCharacter:(unichar)aCharacter range:(NSRange)aRange
{
	return [self indexOfCharacter:aCharacter range:aRange] != NSNotFound;
}

/*
 * -containsAnyCharacterFromSet:
 */
- (BOOL)containsAnyCharacterFromSet:(NSCharacterSet *)aSet
{
	return [self rangeOfCharacterFromSet:aSet].location != NSNotFound;
}

/*
 * -containsAnyCharacterFromSet:options:
 */
- (BOOL)containsAnyCharacterFromSet:(NSCharacterSet *)aSet options:(unsigned int)aMask
{
	return [self rangeOfCharacterFromSet:aSet options:aMask].location != NSNotFound;
}

/*
 * -containsAnyCharacterFromSet:options:range:
 */
- (BOOL)containsAnyCharacterFromSet:(NSCharacterSet *)aSet options:(unsigned int)aMask range:(NSRange)aRange
{
	return [self rangeOfCharacterFromSet:aSet options:aMask range:aRange].location != NSNotFound;
}

/*
 * -containsOnlyCharactersFromSet:
 */
- (BOOL)containsOnlyCharactersFromSet:(NSCharacterSet *)aSet
{
	return [self rangeOfCharacterFromSet:[aSet invertedSet]].location == NSNotFound;
}

/*
 * -containsOnlyCharactersFromSet:options:
 */
- (BOOL)containsOnlyCharactersFromSet:(NSCharacterSet *)aSet options:(unsigned int)aMask
{
	return [self rangeOfCharacterFromSet:[aSet invertedSet] options:aMask].location == NSNotFound;
}

/*
 * -containsOnlyCharactersFromSet:options:range:
 */
- (BOOL)containsOnlyCharactersFromSet:(NSCharacterSet *)aSet options:(unsigned int)aMask range:(NSRange)aRange
{
	return [self rangeOfCharacterFromSet:[aSet invertedSet] options:aMask range:aRange].location == NSNotFound;
}

/*
 * -componentsSeparatedByString:withOpeningQuote:closingQuote:singleQuote:includeEmptyComponents:
 */
- (NSArray *)componentsSeparatedByString:(NSString *)aSeparator withOpeningQuote:(NSString *)aOpeningQuote closingQuote:(NSString *)aClosingQuote singleQuote:(NSString *)aSingleQuote includeEmptyComponents:(BOOL)aFlag
{
	NSMutableArray			* theComponentArray = [NSMutableArray array];
	unsigned int			theTokenEnd = 0,
								theLength = [self length],
								theSeperatorLen = [aSeparator length],
								theSingleQuoteLen = [aSingleQuote length],
								theOpeningQuoteLen = [aOpeningQuote length],
								theClosingQuoteLen = [aClosingQuote length];
	BOOL						theInQuotes = NO;

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