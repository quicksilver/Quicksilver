//
//  NSScreen_BLTRExtensions.h
//  Quicksilver
//
//  Created by Alcor on 12/19/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSScreen (BLTRExtensions)
+ (NSScreen *)screenWithNumber:(NSInteger)number;
- (NSInteger) screenNumber;
- (NSString *)deviceName;
- (BOOL)usesOpenGLAcceleration;
@end
