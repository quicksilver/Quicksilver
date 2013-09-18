
#import "QSPreferenceKeys.h"
#import "QSTaskController.h"
#import "QSTaskViewer.h"
#import "QSTask.h"

NSString *const QSTaskAddedNotification = @"QSTaskAddedNotification";
NSString *const QSTaskChangedNotification = @"QSTaskChangedNotification";
NSString *const QSTaskRemovedNotification = @"QSTaskRemovedNotification";
NSString *const QSTasksStartedNotification = @"QSTasksStartedNotification";
NSString *const QSTasksEndedNotification = @"QSTasksEndedNotification";

NSString *const kTaskStatus =  @"Status";
NSString *const kTaskProgress =  @"Progress";
NSString *const kTaskResult =  @"Result";
NSString *const kTaskDisplayType =  @"Type";

NSString *const kTaskCancelTarget =  @"cancelTarget";
NSString *const kTaskCancelAction =  @"cancelAction";


QSTaskController *QSTasks;

@implementation QSTaskController
+ (QSTaskController * ) sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        QSTasks = [[[self class] allocWithZone:nil] init];
    });
	return QSTasks;
}

+ (void)showViewer { [(QSTaskViewer *)[NSClassFromString(@"QSTaskViewer") sharedInstance] showWindow:self];  }
+ (void)hideViewer { [(QSTaskViewer *)[NSClassFromString(@"QSTaskViewer") sharedInstance] hideWindow:self];  }

- (id)init {
	if (self = [super init]) {
		_tasks = [[NSMutableArray alloc] initWithCapacity:1];
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"QSShowTaskViewerAutomatically"]) {
			[NSClassFromString(@"QSTaskViewer") sharedInstance];
		}
        _taskQueue = dispatch_queue_create("QSTaskController", DISPATCH_QUEUE_CONCURRENT);
	}
	return self;
}

- (void)taskStarted:(QSTask *)task {
    dispatch_async(self.taskQueue, ^{
        BOOL firstItem = ![self.tasks count];
        if (![self.tasks containsObject:task])
            [self.tasks addObject:task];

        if (firstItem) {
            [[NSNotificationCenter defaultCenter] postNotificationName:QSTasksStartedNotification object:nil];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:QSTaskAddedNotification object:task];

    });
}
- (void)taskStopped:(QSTask *)task {
    dispatch_async(self.taskQueue, ^{
        if (task)
            [self.tasks removeObject:task];
        [[NSNotificationCenter defaultCenter] postNotificationName:QSTaskRemovedNotification object:nil];
        
        if (![self.tasks count]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:QSTasksEndedNotification object:nil];
        }
    });
}

// old support methods
- (id)taskWithIdentifier:(NSString *)taskKey {
	QSTask *task = [QSTask taskWithIdentifier:taskKey];
	//	BOOL firstItem = NO;
	//	BOOL newItem = NO;
	[task startTask:nil];
	return task;
}

- (void)updateTask:(NSString *)taskKey status:(NSString *)status progress:(CGFloat)progress {
	QSTask *task = [self taskWithIdentifier:taskKey];

	[task setStatus:status];
	[task setProgress:progress];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSTaskChangedNotification object:task];
}

- (void)removeTask:(NSString *)string {
	[[QSTask findTaskWithIdentifier:string] stopTask:nil];
}

@end
