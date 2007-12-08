//
//  NSString_Purification.m
//  Quicksilver
//
//  Created by Alcor on Fri May 14 2004.

//

#import "NSString_Purification.h"

@implementation NSString (Purification)
- (NSString *)purifiedString{
	NSMutableString *string=[[[self decomposedStringWithCanonicalMapping]mutableCopy]autorelease];
	NSRange range;
	NSCharacterSet *set=[NSCharacterSet nonBaseCharacterSet];
	range=NSMakeRange([string length],0);
	while((range=[string rangeOfCharacterFromSet:set options:NSBackwardsSearch range:NSMakeRange(0,range.location)]).location!=NSNotFound){
		[string deleteCharactersInRange:range];
	}
	if ([self isEqualToString:string]) return self;
	return string;
}
@end
