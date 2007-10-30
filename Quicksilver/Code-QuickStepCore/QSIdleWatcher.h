//
//  QSIdleWatcher.h
//  Quicksilver
//
//  Created by Alcor on 12/29/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define QSIdleNotification @"QSIdleNotification"
#define QSIdleActivityNotification @"QSIdleActivityNotification"

@interface QSIdleWatcher : NSObject {
	NSTimer *idleCheckTimer;
	double lastIdle;
	NSDate *idleDate;
	NSMutableArray *callbacks;
}

@end
