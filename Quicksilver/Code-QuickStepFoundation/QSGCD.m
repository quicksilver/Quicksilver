//
//  QSGCD.m
//  Quicksilver
//
//  Created by Patrick Robertson on 13/01/2013.
//
//

#import "QSGCD.h"

const char* kQueueCatalogEntry = "QueueCatalogEntry";

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
    if (dispatch_get_specific(kQueueCatalogEntry) == dispatch_queue_get_specific(queue, kQueueCatalogEntry)) {
        block();
    } else {
        dispatch_sync(queue, block);
    }
}