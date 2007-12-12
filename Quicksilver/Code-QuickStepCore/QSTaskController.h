#import <AppKit/AppKit.h>

#define QSTaskAddedNotification @"QSTaskAddedNotification"
#define QSTaskChangedNotification @"QSTaskChangedNotification"
#define QSTaskRemovedNotification @"QSTaskRemovedNotification"
#define QSTasksStartedNotification @"QSTasksStartedNotification"
#define QSTasksEndedNotification @"QSTasksEndedNotification"

#define kTaskStatus @"Status"
#define kTaskProgress @"Progress"
#define kTaskResult @"Result"
#define kTaskDisplayType @"Type"

#define kTaskCancelTarget @"cancelTarget"
#define kTaskCancelAction @"cancelAction"

@class QSTask;
@class QSTaskController;
extern QSTaskController *QSTasks; // Shared Instance

@interface QSTaskController : NSObject {
	NSMutableArray *tasks;
}
+ (QSTaskController * ) sharedInstance;
+ (void)hideViewer;
+ (void)showViewer;
- (void)updateTask:(NSString *)taskKey status:(NSString *)status progress:(float)progress;
- (void)removeTask:(NSString *)string;
- (void)taskStarted:(QSTask *)task;
- (void)taskStopped:(QSTask *)task;
- (NSMutableArray *)tasks;

@end
