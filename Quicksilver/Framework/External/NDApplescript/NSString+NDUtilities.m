/*
 *  NSString+NDUtilities.m category
 *  Popup Dock
 *
 *  Created by Nathan Day on Sun Dec 14 2003.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "NSString+NDUtilities.h"
#import "IntegerMath.h"

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
	NSMutableData	* theData;
	char				theNullTerminator = '\0';
	theData  = [NSMutableData dataWithData:[self dataUsingEncoding:NSNonLossyASCIIStringEncoding]];
	[theData appendBytes:&theNullTerminator length:1];
	return (const char *)[theData bytes];
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
