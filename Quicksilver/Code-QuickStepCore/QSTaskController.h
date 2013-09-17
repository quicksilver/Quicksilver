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
- (void)updateTask:(NSString *)identifier status:(NSString *)status progress:(CGFloat)progress;
- (void)removeTask:(NSString *)identifier;

@end
