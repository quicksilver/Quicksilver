//
//  NSString_CompletionExtensions.h
//  Quicksilver
//
//  Created by Alcor on Mon Mar 03 2003.
//  Copyright (c) 2003 Blacktree, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBezierPath(RoundRect)
- (void) appendBezierPathWithRoundedRectangle:(NSRect)aRect withRadius:(float) radius;
- (void) appendBezierPathWithRoundedRectangle:(NSRect)aRect withRadius:(float) radius indent:(int)indent;
@end