//
// NSTask+BLTRExtensions.m
// Quicksilver
//
// Created by Alcor on 2/7/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "NSTask+BLTRExtensions.h"


@implementation NSTask (BLTRExtensions)

+ (NSTask *)taskWithLaunchPath:(NSString *)path arguments:(NSArray *)arguments {
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:path];
	[task setArguments:arguments];
	return [task autorelease];
}

- (NSData *)launchAndReturnOutput {
	[self setStandardOutput:[NSPipe pipe]];
	[self launch];
	[self waitUntilExit];
	return [[[self standardOutput] fileHandleForReading] readDataToEndOfFile];
}

@end
