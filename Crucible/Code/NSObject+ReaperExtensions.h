//
//  NSObject+ReaperExtensions.h
//  Quicksilver
//
//  Created by Alcor on 9/13/04.

//

#import <Cocoa/Cocoa.h>

#define QSDefaultReapInterval 600.0f

@interface NSObject (QSDelayedPerforming)
- (void)performSelector:(SEL)aSelector withObject:(id)anArgument afterDelay:(NSTimeInterval)delay extend:(BOOL)extend;
@end
