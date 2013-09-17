
#import "QSTaskController.h"
#import "QSTaskController_Private.h"
#import "QSTask.h"

NSString *const QSTaskAddedNotification    = @"QSTaskAddedNotification";
NSString *const QSTaskChangedNotification  = @"QSTaskChangedNotification";
NSString *const QSTaskRemovedNotification  = @"QSTaskRemovedNotification";
NSString *const QSTasksStartedNotification = @"QSTasksStartedNotification";
NSString *const QSTasksEndedNotification   = @"QSTasksEndedNotification";

NSString *const kTaskStatus      =  @"Status";
NSString *const kTaskProgress    =  @"Progress";
NSString *const kTaskResult      =  @"Result";
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

- (id)init {
    self = [super init];
	if (self == nil) return nil;

    _tasksDictionary = [[NSMutableDictionary alloc] initWithCapacity:5];
    _taskQueue = dispatch_queue_create("QSTaskController", DISPATCH_QUEUE_CONCURRENT);

	return self;
}

- (QSTask *)taskWithIdentifier:(NSString *)identifier {
    NSAssert(identifier != nil, @"Task identifier shouldn't be nil");

    return self.tasksDictionary[identifier];
}

- (void)taskStarted:(QSTask *)task {
    NSAssert(task != nil, @"Task shouldn't be nil");

    QSGCDQueueAsync(self.taskQueue, ^{
        self.tasksDictionary[task.identifier] = task;

        if (self.tasksDictionary.count == 1) {
            [[NSNotificationCenter defaultCenter] postNotificationName:QSTasksStartedNotification object:nil];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:QSTaskAddedNotification object:task];
    });
}

- (void)taskStopped:(QSTask *)task {
    NSAssert(task != nil, @"Task shouldn't be nil");

    QSGCDQueueAsync(self.taskQueue, ^{
        [self.tasksDictionary removeObjectForKey:task.identifier];

        [[NSNotificationCenter defaultCenter] postNotificationName:QSTaskRemovedNotification object:nil];

        if (self.tasksDictionary.count == 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:QSTasksEndedNotification object:nil];
        }
    });
}

- (void)updateTask:(NSString *)identifier status:(NSString *)status progress:(CGFloat)progress {
    NSAssert(identifier != nil, @"Task identifier shouldn't be nil");

	QSTask *task = [QSTask taskWithIdentifier:identifier];

	task.status = status;
	task.progress = progress;

	[[NSNotificationCenter defaultCenter] postNotificationName:QSTaskChangedNotification object:task];
}

- (void)removeTask:(NSString *)identifier {
    QSTask *task = self.tasksDictionary[identifier];
    [task stop];
}

- (NSArray *)tasks {
    return self.tasksDictionary.allValues;
}

@end
