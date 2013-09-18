
#import "QSPreferenceKeys.h"
#import "QSTaskViewer.h"
#import "QSDockingWindow.h"
#import "QSTaskView.h"

#import "NSObject+ReaperExtensions.h"
#import <QSFoundation/QSFoundation.h>

#define HIDE_TIME 0.2

@implementation QSTaskViewer

static QSTaskViewer * _sharedInstance;

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
		hideTimer = nil;
	}
	return self;
}

- (void)windowDidLoad {
	id win = [self window];
	[win addInternalWidgetsForStyleMask:NSUtilityWindowMask];
	[win setHidesOnDeactivate:NO];
	[win setLevel:NSFloatingWindowLevel];
	[win setBackgroundColor:[NSColor whiteColor]];
	[win setOpaque:YES];
	[(QSDockingWindow *)win setAutosaveName:@"QSTaskViewerWindow"]; // should use the real methods to do this
	[win display];
	//[self refreshAllTasks:nil];
	[self resizeTableToFit];
}

- (void)showWindow:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        [(QSDockingWindow *)[self window] show:sender];
        [super showWindow:sender];
    });
}

- (void)hideWindow:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self window] close];
    });
}

- (void)setHideTimer {
	[self performSelector:@selector(autoHide) withObject:nil afterDelay:HIDE_TIME extend:YES];
}

- (QSTaskController *)taskController {return QSTasks;}

- (void)taskAdded:(NSNotification *)notif {
	[self showIfNeeded:notif];
}

- (void)tasksEnded:(NSNotification *)notif {
    [self setHideTimer];
}

- (void)showIfNeeded:(NSNotification *)notif {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"QSShowTaskViewerAutomatically"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![[self window] isVisible] || [(QSDockingWindow *)[self window] hidden]) {
                autoShow = YES;
                [(QSDockingWindow *)[self window] showKeyless:self];
            }
        });
	}
}

- (QSTaskView *)taskViewForTask:(QSTask *)task {
	return (QSTaskView*)[task view];
}

- (void)refreshAllTasks:(NSNotification *)notif {
	[controller rearrangeObjects];
	
	NSMutableArray *oldTaskViews = [[tasksView subviews] mutableCopy];
	NSArray *oldTasks = [oldTaskViews valueForKey:@"task"];
	NSMutableArray *newTaskViews = [NSMutableArray array];
    dispatch_barrier_async(self.taskController.taskQueue, ^{
        NSUInteger i = 0;
        for (QSTask *task in [self tasks]) {
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
	autoShow = NO;
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

- (NSMutableArray *)tasks {
    return [[QSTaskController sharedInstance] tasks];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex { return NO; }

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
