//
//  NSString_CompletionExtensions.h
//  Quicksilver
//
//  Created by Alcor on Mon Mar 03 2003.
//  Copyright (c) 2003 Blacktree, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBezierPath(RoundRect)
- (void)appendBezierPathWithRoundedRectangle:(NSRect) aRect withRadius:(CGFloat) radius;
- (void)appendBezierPathWithRoundedRectangle:(NSRect) aRect withRadius:(CGFloat) radius indent:(NSInteger)indent;
@end
