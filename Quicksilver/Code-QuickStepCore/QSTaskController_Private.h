//
//  QSTaskController_Private.h
//  Quicksilver
//
//  Created by Etienne on 18/09/13.
//
//

#import <QSCore/QSCore.h>
#import <QSCore/QSTaskController.h>

@interface QSTaskController ()

@property (copy) NSMutableDictionary *tasksDictionary;
@property (assign) dispatch_queue_t taskQueue;

- (void)taskStarted:(QSTask *)task;
- (void)taskStopped:(QSTask *)task;

@end
