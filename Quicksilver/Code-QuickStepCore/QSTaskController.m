
#import "QSPreferenceKeys.h"
#import "QSTaskController.h"
#import "QSTaskViewer.h"
#import "QSTask.h"


QSTaskController *QSTasks;

@implementation QSTaskController
+ (QSTaskController * ) sharedInstance {
	if (!QSTasks) QSTasks = [[[self class] allocWithZone:nil] init];
	return QSTasks;
}
+ (void)showViewer { [(QSTaskViewer *)[NSClassFromString(@"QSTaskViewer") sharedInstance] showWindow:self];  }
+ (void)hideViewer { [(QSTaskViewer *)[NSClassFromString(@"QSTaskViewer") sharedInstance] hideWindow:self];  }

- (id)init {
	if (self = [super init]) {
		tasks = [[NSMutableArray alloc] initWithCapacity:1];
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"QSShowTaskViewerAutomatically"]) {
			[NSClassFromString(@"QSTaskViewer") sharedInstance];
		}

	}
	return self;
}

- (void)taskStarted:(QSTask *)task {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL firstItem = ![tasks count];
        if (![tasks containsObject:task])
            [tasks addObject:task];
        
        if (firstItem) {
            [[NSNotificationCenter defaultCenter] postNotificationName:QSTasksStartedNotification object:nil];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:QSTaskAddedNotification object:task];

    });
}
- (void)taskStopped:(QSTask *)task {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (task) {
            [tasks removeObject:task];
            [[NSNotificationCenter defaultCenter] postNotificationName:QSTaskRemovedNotification object:nil];
        }
        
        if (![tasks count]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:QSTasksEndedNotification object:nil];
        }
    });
}

- (NSMutableArray *)tasks {

	return tasks;
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
