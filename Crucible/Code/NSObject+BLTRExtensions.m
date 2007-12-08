//
//  NSObject+BLTRExtensions.m
//  Quicksilver
//
//  Created by Alcor on 6/4/05.

//

#import "NSObject+BLTRExtensions.h"


@implementation NSObject (BLTRExtensions)
- (NSBundle *)classBundle{	
	return [NSBundle bundleForClass:[self class]];
}
@end
