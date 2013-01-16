//
//  QSGCD.h
//  Quicksilver
//
//  Created by Patrick Robertson on 13/01/2013.
//
//

void runOnMainQueueSync(void (^block)(void));
void runOnQueueSync(dispatch_queue_t queue,void (^block)(void));
