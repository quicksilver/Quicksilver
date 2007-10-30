//
//  NSScreen_BLTRExtensions.h
//  Quicksilver
//
//  Created by Alcor on 12/19/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSScreen (BLTRExtensions)
-(int)screenNumber;
-(NSString *)deviceName;
+(NSScreen *)screenWithNumber:(int)number;
-(BOOL)usesOpenGLAcceleration;
@end
