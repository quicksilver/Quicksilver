/*
 *  NSEvent+BLTRExtensions.h
 *  Quicksilver
 *
 *  Created by Alcor on 9/3/04.
 *  Copyright 2004 Blacktree. All rights reserved.
 *
 */

#include <Carbon/Carbon.h>


#define NSProcessNotificationEvent 21

#define NSFrontProcessSwitched 2
#define NSProcessWillLaunchSubType 4
#define NSProcessDidTerminateSubType 8
#define NSProcessDidLaunchSubType 512
#define NSProccessFocusedSubType -3838
#define NSProccessBouncedSubType -3839


@interface NSEvent (BLTRExtensions)
+ (NSTimeInterval) doubleClickTime;
- (NSInteger) standardModifierFlags;
@end
