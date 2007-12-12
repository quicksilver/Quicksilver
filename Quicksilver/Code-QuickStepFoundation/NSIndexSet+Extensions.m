//
// NSIndexSet+Extensions.m
// Quicksilver
//
// Created by Alcor on 3/16/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "NSIndexSet+Extensions.h"

@implementation NSIndexSet (ArrayInit)
+ (NSIndexSet *)indexSetFromArray:(NSArray *)indexes {
	NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
	NSEnumerator *indexEnumerator = [indexes objectEnumerator];
	NSNumber *idx;
	while (idx = [indexEnumerator nextObject])
		[indexSet addIndex:[idx intValue]];
	return indexSet;
}
@end
