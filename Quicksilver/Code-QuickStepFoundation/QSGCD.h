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

inline void QSGCDQueueSync(dispatch_queue_t queue, void (^block)(void))
{
    if (dispatch_queue_get_label(queue) == dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)) {
        block();
    } else {
        dispatch_sync(queue, block);
    }
}

inline void QSGCDQueueAsync(dispatch_queue_t queue, void (^block)(void))
{
    dispatch_async(queue, block);
}

inline void QSGCDQueueDelayed(dispatch_queue_t queue, NSTimeInterval delay, void (^block)(void))
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
    dispatch_after(popTime, queue, block);
}

inline void QSGCDMainSync(void (^block)(void))
{
    QSGCDQueueSync(dispatch_get_main_queue(), block);
}

inline void QSGCDMainAsync(void (^block)(void))
{
    QSGCDQueueAsync(dispatch_get_main_queue(), block);
}

inline void QSGCDMainDelayed(NSTimeInterval delay, void(^block)(void))
{
    QSGCDQueueDelayed(dispatch_get_main_queue(), delay, block);
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

inline void QSGCDDelayed(NSTimeInterval delay, void (^block)(void))
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    QSGCDQueueDelayed(queue, delay, block);
}

// Remove those when the plugins are call-free
// Don't forget to remove definitions in .m file
void runOnMainQueueSync(void (^block)(void)) QS_DEPRECATED_MSG("Use QSGCDMainSync");
void runOnQueueSync(dispatch_queue_t queue, void (^block)(void)) QS_DEPRECATED_MSG("Use QSGCDQueueSync");

#endif // __QSGCD__
