
#import "QSPreferenceKeys.h"
#import "QSTaskViewer.h"
#import "QSDockingWindow.h"
#import "QSTaskViewController.h"
#import "QSTaskController.h"
#import "QSTaskController_Private.h"

#import "NSObject+ReaperExtensions.h"
#import <QSFoundation/QSFoundation.h>

#define HIDE_TIME 0.2

@interface QSTaskViewer ()

@property (strong) IBOutlet NSView *tasksView;
@property (strong) IBOutlet NSTextField *taskCountField;

@property (copy) NSMutableDictionary *taskControllers;

@property BOOL autoShow;
@property (retain) NSTimer *hideTimer;
@property (retain) NSTimer *updateTimer;

@end


@implementation QSTaskViewer

static QSTaskViewer * _sharedInstance;

+ (void)load {
    /* We alloc our shared instance now because we want to pop open when tasks start */
    [self sharedInstance];
}

+ (QSTaskViewer *)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[[self class] alloc] init];
    });
	return _sharedInstance;
}

- (id)init {
    self = [self initWithWindowNibName:@"QSTaskViewer"];

	if (self == nil) {
        return nil;
    }

    _taskControllers = [NSMutableDictionary dictionary];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [nc addObserver:self selector:@selector(taskAdded:) name:QSTaskAddedNotification object:nil];
    [nc addObserver:self selector:@selector(tasksEnded:) name:QSTasksEndedNotification object:nil];
    [nc addObserver:self selector:@selector(addTask:) name:QSTaskAddedNotification object:nil];
    [nc addObserver:self selector:@selector(updateTask:) name:QSTaskChangedNotification object:nil];
    [nc addObserver:self selector:@selector(removeTask:) name:QSTaskRemovedNotification object:nil];

	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)windowDidLoad {
	id win = [self window];
	[win addInternalWidgetsForStyleMask:NSUtilityWindowMask];
	[win setHidesOnDeactivate:NO];
	[win setLevel:NSFloatingWindowLevel];
	[win setBackgroundColor:[NSColor whiteColor]];
	[win setOpaque:YES];
	[win setFrameAutosaveName:@"QSTaskViewerWindow"]; // should use the real methods to do this
	[win display];
	[self resizeTableToFit];
}

- (void)showWindow:(id)sender {
    QSGCDMainAsync(^{
        [(QSDockingWindow *)[self window] show:sender];
        [super showWindow:sender];
    });
}

- (void)hideWindow:(id)sender {
    QSGCDMainAsync(^{
        [self.window close];
    });
}

- (void)setHideTimer {
	[self performSelector:@selector(autoHide) withObject:nil afterDelay:HIDE_TIME extend:YES];
}

- (QSTaskController *)taskController {return QSTasks; }

- (void)taskAdded:(NSNotification *)notif {
	[self showIfNeeded:notif];
}

- (void)tasksEnded:(NSNotification *)notif {
    [self setHideTimer];
}

- (void)showIfNeeded:(NSNotification *)notif {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kQSShowTaskViewerAutomatically]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![[self window] isVisible] || [(QSDockingWindow *)[self window] hidden]) {
                self.autoShow = YES;
                [(QSDockingWindow *)[self window] showKeyless:self];
            }
        });
	}
}

- (void)addTask:(NSNotification *)notif {
    QSTask *task = notif.object;

    QSTaskViewController *taskController = [QSTaskViewController controllerWithTask:notif.object];

    self.taskControllers[task.identifier] = taskController;

    [self updateTaskView];
}

- (void)removeTask:(NSNotification *)notif {
    QSTask *task = notif.object;

    QSTaskViewController *removedController = self.taskControllers[task.identifier];

    [self.taskControllers removeObjectForKey:task.identifier];

    [removedController.view removeFromSuperview];

    [self updateTaskView];
}

- (void)updateTask:(NSNotification *)notif {
    [self updateTaskView];
}

- (void)updateTaskView {
    NSUInteger i = 0;
    for (NSString *taskID in self.taskControllers) {
        QSTaskViewController *controller = self.taskControllers[taskID];
        NSRect frame = controller.view.frame;
        frame.origin = NSMakePoint(0, NSHeight(self.tasksView.frame) - NSHeight(frame) * (i + 1));
        frame.size.width = NSWidth(self.tasksView.enclosingScrollView.frame);
        controller.view.frame = frame;
        controller.view.needsDisplay = YES;
        if (![self.tasksView.subviews containsObject:controller.view]) {
            [self.tasksView addSubview:controller.view];
        }
        i++;
    }

    NSUInteger taskCount = self.taskControllers.count;
    if (taskCount == 0) {
        self.taskCountField.hidden = YES;
    } else {
        self.taskCountField.hidden = NO;
        NSString *cellString = nil;
        if (taskCount == 1) {
            cellString = [NSString stringWithFormat:NSLocalizedString(@"%d task", @"Task viewer task count (singular)"), taskCount];
        } else {
            cellString = [NSString stringWithFormat:NSLocalizedString(@"%d tasks", @"Task viewer task count (plural)"), taskCount];
        }
        self.taskCountField.stringValue = cellString;
    }
    self.taskCountField.needsDisplay = YES;

	if (self.window.isVisible && [[NSUserDefaults standardUserDefaults] boolForKey:kQSResizeTaskViewerAutomatically]) {
		[self resizeTableToFit];
	}
}

- (void)autoHide {
	[(QSDockingWindow *)[self window] hideOrOrderOut:self];
	self.autoShow = NO;
}

- (void)resizeTableToFit {
	NSRect tableRect = self.tasksView.enclosingScrollView.frame;
	NSRect windowRect = self.window.frame;
//	BOOL atBottom = NSMinY(windowRect) <= NSMinY([[[self window] screen] frame]);
    NSUInteger taskCount = self.taskControllers.count;
	CGFloat newHeight = -1 + MAX(taskCount, 1) * 55;
	CGFloat heightChange = newHeight-NSHeight(tableRect);
	windowRect.size.height += heightChange;
//	if (!atBottom)
		windowRect.origin.y -= heightChange;
	[self.window setFrame:constrainRectToRect(windowRect, self.window.screen.frame) display:YES animate:YES];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex { return NO; }


@end
