//
//  QSTask.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 6/29/05. Adapted by Florian Heckl on 20/08/10.
//

#import <Cocoa/Cocoa.h>

typedef void(^QSTaskCancelBlock)(void);

@interface QSTask : NSObject

@property (readonly, copy) NSString *identifier;
@property (copy) NSString *name;
@property (copy) NSString *status;
@property (assign) CGFloat progress;/**< Between 0.0 and 1.0, negative disables it */
@property (copy) NSImage *icon;

@property (readonly, copy) NSMutableArray *subtasks;
@property (readonly, weak) QSTask *parentTask;

@property (readonly, getter=isRunning) BOOL running;

@property (copy) QSTaskCancelBlock cancelBlock;
@property BOOL showProgress;

+ (instancetype)taskWithIdentifier:(NSString *)identifier;

- (void)addSubtask:(QSTask *)task;

- (void)start;
- (void)stop;

- (void)cancel;

@end
