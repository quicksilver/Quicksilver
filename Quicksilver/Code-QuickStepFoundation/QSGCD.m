//
//  QSGCD.m
//  Quicksilver
//
//  Created by Patrick Robertson on 13/01/2013.
//
//

#import "QSGCD.h"

const char *kQueueCatalogEntry = "QueueCatalogEntry";

void runOnMainQueueSync(void (^block)(void))
{
    QSGCDMainSync(block);
}

void runOnQueueSync(dispatch_queue_t queue, void (^block)(void))
{
    QSGCDQueueSync(queue, block);
}

extern inline void QSGCDQueueSync(dispatch_queue_t queue, void (^block)(void));
extern inline void QSGCDQueueAsync(dispatch_queue_t queue, void (^block)(void));
extern inline void QSGCDQueueDelayed(dispatch_queue_t queue, NSTimeInterval delay, void (^block)(void));

extern inline void QSGCDMainSync(void (^block)(void));
extern inline void QSGCDMainAsync(void (^block)(void));
extern inline void QSGCDMainDelayed(NSTimeInterval delay, void (^block)(void));

extern inline void QSGCDSync(void (^block)(void));
extern inline void QSGCDAsync(void (^block)(void));
extern inline void QSGCDDelayed(NSTimeInterval delay, void (^block)(void));

BOOL QSGCDWait(NSTimeInterval timeout, void (^startBlock)(void), BOOL (^checkBlock)(void)) {
	__block BOOL success = NO;
	dispatch_semaphore_t waitSemaphore = dispatch_semaphore_create(0);
	QSGCDAsync(^{
		startBlock();

		while (!checkBlock()) {
			usleep(50000);
		}

		success = YES;
		dispatch_semaphore_signal(waitSemaphore);
	});

	dispatch_semaphore_wait(waitSemaphore, dispatch_time(DISPATCH_TIME_NOW, timeout * NSEC_PER_SEC));

	return success;
}
