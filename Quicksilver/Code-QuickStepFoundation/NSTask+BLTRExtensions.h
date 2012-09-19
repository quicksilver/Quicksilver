//
//  NSTask+BLTRExtensions.h
//  Quicksilver
//
//  Created by Alcor on 2/7/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSTask (BLTRExtensions)
+ (NSTask *)taskWithLaunchPath:(NSString *)path arguments:(NSArray *)arguments;
+ (NSTask *)taskWithLaunchPath:(NSString *)path arguments:(NSArray *)arguments input:(NSData *)inputData;
- (NSData *)launchAndReturnOutput;
@end
