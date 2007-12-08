//
//  QSIdleWatcher.h
//  Quicksilver
//
//  Created by Alcor on 12/29/04.

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
