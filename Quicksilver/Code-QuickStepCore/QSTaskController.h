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

@property (readonly, copy) NSArray *tasks;

+ (instancetype)sharedInstance;
- (QSTask *)taskWithIdentifier:(NSString *)identifier;

/**
 * Update the task with identifier status and progress.
 *
 * Deprecated because you should just update the tasks' status and progress directly.
 */
- (void)updateTask:(NSString *)identifier status:(NSString *)status progress:(CGFloat)progress  __attribute__((deprecated));

/**
 * Stops a running task.
 *
 * Deprecated because you should just have to call -stop on your task.
 */
- (void)removeTask:(NSString *)identifier __attribute__((deprecated));

@end
