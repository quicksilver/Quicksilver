//
//  NSObject+ReaperExtensions.m
//  Quicksilver
//
//  Created by Alcor on 9/13/04.

//

#import "NSObject+ReaperExtensions.h"


@implementation NSObject (QSDelayedPerforming)
- (void)performSelector:(SEL)aSelector withObject:(id)anArgument afterDelay:(NSTimeInterval)delay extend:(BOOL)extend{
	if (extend)
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:aSelector object:anArgument];
	[self performSelector:aSelector withObject:anArgument afterDelay:delay];		
}

- (void)doomSelector:(SEL)selector delay:(NSTimeInterval)delay extend:(BOOL)extend{
	[self performSelector:selector withObject:nil afterDelay:delay extend:extend];		
}

@end
