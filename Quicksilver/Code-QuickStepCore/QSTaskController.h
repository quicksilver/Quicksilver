#import <AppKit/AppKit.h>

extern NSString *const QSTaskAddedNotification;
extern NSString *const QSTaskChangedNotification;
extern NSString *const QSTaskRemovedNotification;
extern NSString *const QSTasksStartedNotification;
extern NSString *const QSTasksEndedNotification;

extern NSString *const kTaskStatus;
extern NSString *const kTaskProgress;
extern NSString *const kTaskResult;
extern NSString *const kTaskDisplayType;

extern NSString *const kTaskCancelTarget;
extern NSString *const kTaskCancelAction;

@class QSTask;
@class QSTaskController;
extern QSTaskController *QSTasks; // Shared Instance

@interface QSTaskController : NSObject

@property (retain) NSMutableArray *tasks;
@property (assign) dispatch_queue_t taskQueue;

+ (QSTaskController *)sharedInstance;
+ (void)hideViewer;
+ (void)showViewer;
- (void)updateTask:(NSString *)taskKey status:(NSString *)status progress:(CGFloat)progress;
- (void)removeTask:(NSString *)string;
- (void)taskStarted:(QSTask *)task;
- (void)taskStopped:(QSTask *)task;

@end
