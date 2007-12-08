//
//  NSUserDefaults_BLTRExtensions.m
//  Quicksilver
//
//  Created by Alcor on 8/17/04.

//

#import "NSUserDefaults_BLTRExtensions.h"


@implementation NSUserDefaults (BLTRExtensions)

- (NSColor *)colorForKey:(NSString *)key{
	return [NSUnarchiver unarchiveObjectWithData:[self dataForKey:key]];
}


@end
