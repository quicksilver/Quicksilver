//
//  NSString_CompletionExtensions.h
//  Quicksilver
//
//  Created by Alcor on Mon Mar 03 2003.

//

#import <Foundation/Foundation.h>

@interface NSBezierPath(RoundRect)
- (void) appendBezierPathWithRoundedRectangle:(NSRect)aRect withRadius:(float) radius;
- (void) appendBezierPathWithRoundedRectangle:(NSRect)aRect withRadius:(float) radius indent:(int)indent;
@end