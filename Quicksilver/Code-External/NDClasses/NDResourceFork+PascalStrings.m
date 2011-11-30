/*
 *  NDResourceFork+PascalStrings.m category
 *  NDResourceFork
 *
 *  Created by Nathan Day on Tue Feb 11 2003.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "NDResourceFork+PascalStrings.h"
#import "NSString+NDCarbonUtilities.h"

/*
 * category implementation NDResourceFork (PascalStrings)
 */
@implementation NDResourceFork (PascalStrings)

/*
 * -addString:type:Id:name:
 *		adds a string to the resource fork as a pascal string
 */
- (BOOL)addString:(NSString *)aString type:(ResType)aType Id:(short)anID name:(NSString *)aName
{
	unsigned int		theLength;
	NSMutableData		* theData;

	theLength = [aString length];

	theLength = ( theLength > 255 ) ? 255 : theLength;

	theData = [NSMutableData dataWithLength:theLength + 1];
	[aString getPascalString:[theData mutableBytes] length:[theData length]];

	return [self addData:theData type:aType Id:anID name:aName];
}

/*
 * -addString:type:Id:name:
 *		adds a string to the resource fork as a pascal string
 */
- (BOOL)addString:(NSString *)aString type:(ResType)aType name:(NSString *)aName
{
	unsigned int		theLength;
	NSMutableData		* theData;

	theLength = [aString length];

	theLength = ( theLength > 255 ) ? 255 : theLength;

	theData = [NSMutableData dataWithLength:theLength + 1];
	[aString getPascalString:[theData mutableBytes] length:[theData length]];

	return [self addData:theData type:aType name:aName];
}

/*
 * -stringForType:Id:
 */
- (NSString *)stringForType:(ResType)aType Id:(short)anID
{
	NSData			* theData;

	theData = [self dataForType:aType Id:anID];

	return theData ? [NSString stringWithPascalString:(ConstStr255Param)[theData bytes]] : nil;
}

/*
 * -stringForType:named:
 */
- (NSString *)stringForType:(ResType)aType named:(NSString *)aName
{
	NSData			* theData;

	theData = [self dataForType:aType named:aName];

	return theData ? [NSString stringWithPascalString:(ConstStr255Param)[theData bytes]] : nil;
}

@end





