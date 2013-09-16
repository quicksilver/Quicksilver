//
// NSSortDescriptor+BLTRExtensions.m
// Quicksilver
//
// Created by Alcor on 3/27/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "NSSortDescriptor+BLTRExtensions.h"

@implementation NSSortDescriptor (QSConvenience)
+ (id)descriptorWithKey:(NSString *)key ascending:(BOOL)ascending {
	return[[NSSortDescriptor alloc] initWithKey:key ascending:ascending];
}
+ (id)descriptorWithKey:(NSString *)key ascending:(BOOL)ascending selector:(SEL)selector {
	return[[NSSortDescriptor alloc] initWithKey:key ascending:ascending selector:selector];
}
+ (NSArray *)descriptorArrayWithKey:(NSString *)key ascending:(BOOL)ascending {
	return [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:key ascending:ascending]];
}
+ (NSArray *)descriptorArrayWithKey:(NSString *)key ascending:(BOOL)ascending selector:(SEL)selector {
	return [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:key ascending:ascending selector:selector]];
}
@end
