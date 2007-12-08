//
//  NSTask+BLTRExtensions.h
//  Quicksilver
//
//  Created by Alcor on 2/7/05.

//

#import <Cocoa/Cocoa.h>


@interface NSTask (BLTRExtensions)
+ (NSTask *)taskWithLaunchPath:(NSString *)path arguments:(NSArray *)arguments;
- (NSData *)launchAndReturnOutput;
@end
