//
//  QSGCD.m
//  Quicksilver
//
//  Created by Patrick Robertson on 13/01/2013.
//
//

#import "QSGCD.h"

void runOnMainQueueSync(void (^block)(void))
{
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

void runOnQueueSync(dispatch_queue_t queue,void (^block)(void))
{
    if (dispatch_get_current_queue() == queue) {
        block();
    } else {
        dispatch_sync(queue, block);
    }
}