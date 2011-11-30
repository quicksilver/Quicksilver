/*
	NSValue+NDFourCharCode.m

	Created by Nathan Day on 24.12.04 under a MIT-style license. 
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

#import "NSValue+NDFourCharCode.h"

@interface NDFourCharCodeValue : NSNumber
{
@private
	FourCharCode	fourCharCode;
}
- (id)initWithFourCharCode:(FourCharCode)aFourCharCode;
@end

@implementation NSValue (NDFourCharCode)

/*
	+ valueWithFourCharCode:
 */
+ (NSValue *)valueWithFourCharCode:(FourCharCode)aFourCharCode
{
	return [[[NDFourCharCodeValue alloc] initWithFourCharCode:aFourCharCode] autorelease];
}

/*
	+ valueWithAEKeyword:
 */
+ (NSValue *)valueWithAEKeyword:(AEKeyword)anAEKeyword
{
	return [[[NDFourCharCodeValue alloc] initWithFourCharCode:anAEKeyword] autorelease];
}

/*
	+ valueWithOSType:
 */
+ (NSValue *)valueWithOSType:(OSType)anOSType
{
	return [[[NDFourCharCodeValue alloc] initWithFourCharCode:anOSType] autorelease];
}

/*
	- fourCharCode
 */
- (FourCharCode)fourCharCode
{
	return 0;
}

/*
	- aeKeyword
 */
- (AEKeyword)aeKeyword
{
	return [self fourCharCode];
}

/*
	- osType
 */
- (OSType)osType
{
	return [self fourCharCode];
}

@end

@implementation NSNumber (NDFourCharCode)

/*
	- fourCharCode
 */
- (FourCharCode)fourCharCode
{
	FourCharCode		theValue = 0;
	const char			* theObjCType = [self objCType];
	if( sizeof(FourCharCode) <= sizeof(unsigned long) && strcmp(theObjCType, @encode(unsigned long)) == 0 )
		theValue = [(id)self unsignedLongValue];
	else if( sizeof(FourCharCode) <= sizeof(long) && strcmp(theObjCType, @encode(long)) == 0 )
		theValue = [(id)self longValue];
	else if( sizeof(FourCharCode) <= sizeof(unsigned int) && strcmp(theObjCType, @encode(unsigned int)) == 0 )
		theValue = [(id)self unsignedIntValue];
	else if( sizeof(FourCharCode) <= sizeof(unsigned int) && strcmp(theObjCType, @encode(int)) == 0 )
		theValue = [(id)self intValue];
	
	return theValue;
}

@end

@implementation NDFourCharCodeValue

/*
	- initWithCoder:
 */
- (id)initWithCoder:(NSCoder *)aDecoder
{
	if( (self = [super init]) != nil )
		[aDecoder decodeValueOfObjCType:@encode(FourCharCode) at:(void *)&fourCharCode];
	return self;
}

/*
	- encodeWithCoder:
 */
- (void)encodeWithCoder:(NSCoder *)anEncoder
{
	[anEncoder encodeValueOfObjCType:@encode(FourCharCode) at:(void *)&fourCharCode];
}

/*
	- initWithBytes:objCType:
 */
- (id)initWithBytes:(const void *)aValue objCType:(const char *)aType
{
	if( strcmp( aType, @encode(FourCharCode)) == 0 )
	{
		self = [self initWithFourCharCode:*(FourCharCode*)aValue];
	}
	else
	{
		[self release];
		self = nil;
	}
	return self;
}

/*
	- initWithFourCharCode:
 */
- (id)initWithFourCharCode:(FourCharCode)aFourCharCode
{
	if( (self = [self init]) != nil )
	{
		fourCharCode = aFourCharCode;
	}
	return self;
}

/*
	- objCType
 */
- (const char *)objCType
{
	return @encode(FourCharCode);
}

/*
	- getValue:
 */
- (void)getValue:(void *)aBuffer
{
	aBuffer = malloc(sizeof(FourCharCode));
	if( aBuffer )
		memcpy(aBuffer, (const void *)&fourCharCode, sizeof(fourCharCode));
}

/*
	- fourCharCode
 */
- (FourCharCode)fourCharCode
{
	return fourCharCode;
}

/*
	- aeKeyword
 */
- (AEKeyword)aeKeyword
{
	return fourCharCode;
}

/*
	- osType
 */
- (OSType)osType
{
	return fourCharCode;
}

- (unsigned long)unsignedLongValue
{
	return fourCharCode;
}

- (NSString *)stringValue
{
	return [NSString stringWithFormat:@"'%c%c%c%c'", (char)(fourCharCode>>24),(char)(fourCharCode>>16),(char)(fourCharCode>>8),(char)fourCharCode ];
}

- (NSComparisonResult)compare:(NSNumber *)anOtherNumber
{
	FourCharCode	theOtherFourCharCode = [anOtherNumber fourCharCode];
	return fourCharCode < theOtherFourCharCode
		? NSOrderedAscending
		: fourCharCode > theOtherFourCharCode
			? NSOrderedDescending
			: NSOrderedSame;
}

- (BOOL)isEqualToNumber:(NSNumber *)aNumber
{
	return fourCharCode == [aNumber fourCharCode];
}

- (NSString *)descriptionWithLocale:(NSDictionary *)aLocale;
{
	return [NSString stringWithFormat:@"'%c%c%c%c'", (char)(fourCharCode>>24),(char)(fourCharCode>>16),(char)(fourCharCode>>8),(char)fourCharCode ];
}
/*
	- description
 */
- (NSString *)description
{
	return [NSString stringWithFormat:@"'%c%c%c%c'", (char)(fourCharCode>>24),(char)(fourCharCode>>16),(char)(fourCharCode>>8),(char)fourCharCode ];
}

/*
	- isEqualToValue:
 */
- (BOOL)isEqualToValue:(NSValue *)aValue
{
	return [aValue isKindOfClass:[NDFourCharCodeValue class]]
		? [(id)aValue fourCharCode] == fourCharCode
		: [aValue respondsToSelector:@selector(unsignedLongValue)]
			? [(id)aValue unsignedLongValue] == fourCharCode
			: NO;
}

/*
	- hash
 */
- (unsigned int)hash
{
	return (unsigned int)fourCharCode;
}

/*
	- copyWithZone:
 */
- (id)copyWithZone:(NSZone *)aZone
{
	return (aZone == [self zone]) ? [self retain] : [[NDFourCharCodeValue allocWithZone:aZone] initWithFourCharCode:fourCharCode];
}

@end