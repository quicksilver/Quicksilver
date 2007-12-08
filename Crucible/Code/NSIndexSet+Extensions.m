//
//  NSIndexSet+Extensions.m
//  Quicksilver
//
//  Created by Alcor on 3/16/05.

//

#import "NSIndexSet+Extensions.h"


@implementation NSIndexSet (ArrayInit)
+ (NSIndexSet *)indexSetFromArray:(NSArray *)indexes
{
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    NSNumber *idx;
    for (idx in indexes)
    {
		[indexSet addIndex:[idx intValue]];
    }
    return indexSet;
}
@end
