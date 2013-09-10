//
//  QSGCD.h
//  Quicksilver
//
//  Created by Patrick Robertson on 13/01/2013.
//
//

#ifndef __QSGCD__
#define __QSGCD__

extern const char *kQueueCatalogEntry;

inline void QSGCDMainSync(void (^block)(void))
{
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

inline void QSGCDMainAsync(void (^block)(void))
{
    dispatch_async(dispatch_get_main_queue(), block);
}

inline void QSGCDQueueSync(dispatch_queue_t queue, void (^block)(void))
{
    if (dispatch_queue_get_label(queue) == dispatch_queue_get_label(dispatch_get_current_queue())) {
        block();
    } else {
        dispatch_sync(queue, block);
    }
}

inline void QSGCDQueueAsync(dispatch_queue_t queue, void (^block)(void))
{
    dispatch_async(queue, block);
}

inline void QSGCDSync(void (^block)(void))
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    QSGCDQueueSync(queue, block);
}

inline void QSGCDAsync(void (^block)(void))
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    QSGCDQueueAsync(queue, block);
}

// Remove those when the plugins are call-free
// Don't forget to remove definitions in .m file
void runOnMainQueueSync(void (^block)(void)) __attribute__((deprecated));
void runOnQueueSync(dispatch_queue_t queue, void (^block)(void)) __attribute__((deprecated));

#endif // __QSGCD__