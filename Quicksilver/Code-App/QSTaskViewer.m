
#import "QSPreferenceKeys.h"
#import "QSTaskViewer.h"
#import "QSDockingWindow.h"
#import "QSTaskView.h"
#import "QSTaskController.h"
#import "QSTaskController_Private.h"

#import "NSObject+ReaperExtensions.h"
#import <QSFoundation/QSFoundation.h>

#define HIDE_TIME 0.2

@interface QSTaskViewer () {
	IBOutlet NSView *tasksView;
	IBOutlet NSArrayController *controller;
}

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
	if ((self = [self initWithWindowNibName:@"QSTaskViewer"])) {

		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

		[nc addObserver:self selector:@selector(taskAdded:) name:QSTaskAddedNotification object:nil];
		[nc addObserver:self selector:@selector(tasksEnded:) name:QSTasksEndedNotification object:nil];
		[nc addObserver:self selector:@selector(refreshAllTasks:) name:QSTaskAddedNotification object:nil];
		[nc addObserver:self selector:@selector(refreshAllTasks:) name:QSTaskChangedNotification object:nil];
		[nc addObserver:self selector:@selector(refreshAllTasks:) name:QSTaskRemovedNotification object:nil];
	}
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

- (QSTaskView *)taskViewForTask:(QSTask *)task {
    static NSNib *taskNib = nil;
    if (!taskNib) {
        taskNib = [[NSNib alloc] initWithNibNamed:@"QSTaskEntry" bundle:[NSBundle bundleForClass:[self class]]];
    }

    NSArray *topObjects = nil;
    BOOL success = [taskNib instantiateWithOwner:task topLevelObjects:&topObjects];
    NSAssert(success, @"Failed to load NIB file \"QSTaskEntry\"");

    for (id obj in topObjects) {
        if ([obj isKindOfClass:[QSTaskView class]])
            return obj;
    }
    return nil;
}

- (void)refreshAllTasks:(NSNotification *)notif {
	[controller rearrangeObjects];

	NSMutableArray *oldTaskViews = [[tasksView subviews] mutableCopy];
	NSArray *oldTasks = [oldTaskViews valueForKey:@"task"];
	NSMutableArray *newTaskViews = [NSMutableArray array];
    dispatch_barrier_async(self.taskController.taskQueue, ^{
        NSUInteger i = 0;
        for (QSTask *task in self.tasks) {
            NSInteger index = [oldTasks indexOfObject:task];
            NSView *view = nil;
            if (index != NSNotFound) {
                view = [oldTaskViews objectAtIndex:index];
            }
            if (!view) view = [self taskViewForTask:task];
            if (view) {
                NSRect frame = [view frame];
                frame.origin = NSMakePoint(0, NSHeight([tasksView frame]) -NSHeight([view frame]) * (i + 1));
                frame.size.width = NSWidth([[tasksView enclosingScrollView] frame]);
                [view setFrame:frame];
                [view setNeedsDisplay:YES];
                [tasksView addSubview:view];
                [newTaskViews addObject:view];
            }
            i++;
        }
    });

	[oldTaskViews removeObjectsInArray:newTaskViews];

	[oldTaskViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[oldTaskViews makeObjectsPerformSelector:@selector(setTask:) withObject:nil];
	[tasksView setNeedsDisplay:YES];

	if ([[self window] isVisible] && [[NSUserDefaults standardUserDefaults] boolForKey:@"QSResizeTaskViewerAutomatically"]) {
		[self resizeTableToFit];
	}
}

- (void)autoHide {
	[(QSDockingWindow *)[self window] hideOrOrderOut:self];
	self.autoShow = NO;
}

- (void)resizeTableToFit {
	NSRect tableRect = [[tasksView enclosingScrollView] frame];
	NSRect windowRect = [[tasksView window] frame];
//	BOOL atBottom = NSMinY(windowRect) <= NSMinY([[[self window] screen] frame]);
	CGFloat newHeight = -1+MAX([(NSArray *)[controller arrangedObjects] count] , 1) *55;
	CGFloat heightChange = newHeight-NSHeight(tableRect);
	windowRect.size.height += heightChange;
//	if (!atBottom)
		windowRect.origin.y -= heightChange;
	[[tasksView window] setFrame:constrainRectToRect(windowRect, [[[self window] screen] frame]) display:YES animate:YES];
}

- (NSArray *)tasks {
    return [[[QSTaskController sharedInstance] tasks] copy];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex { return NO; }


@end
