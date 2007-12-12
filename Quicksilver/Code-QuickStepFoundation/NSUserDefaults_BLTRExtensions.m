//
// NSUserDefaults_BLTRExtensions.m
// Quicksilver
//
// Created by Alcor on 8/17/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "NSUserDefaults_BLTRExtensions.h"

@implementation NSUserDefaults (BLTRExtensions)
- (NSColor *)colorForKey:(NSString *)key {
	return [NSUnarchiver unarchiveObjectWithData:[self dataForKey:key]];
}
@end
