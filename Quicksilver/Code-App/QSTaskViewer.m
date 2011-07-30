
#import "QSPreferenceKeys.h"
#import "QSTaskViewer.h"
#import "QSDockingWindow.h"
#import "QSTaskView.h"

#import "NSObject+ReaperExtensions.h"
#import <QSFoundation/QSFoundation.h>

#define HIDE_TIME 0.2

@implementation QSTaskViewer

+ (QSTaskViewer *)sharedInstance {
	static QSTaskViewer * _sharedInstance;
	if (!_sharedInstance) _sharedInstance = [[[self class] allocWithZone:[self zone]] init];
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
	[self window];
	[(QSDockingWindow *)[self window] show:sender];
	[super showWindow:sender];
}

- (void)hideWindow:(id)sender {
	[[self window] close];
}

- (void)setHideTimer {
	[self performSelector:@selector(autoHide) withObject:nil afterDelay:HIDE_TIME extend:YES];
}

- (id)taskController {return QSTasks;}

- (void)taskAdded:(NSNotification *)notif {
	[self performSelector:@selector(showIfNeeded:) withObject:self afterDelay:0.5 extend:NO];
}

- (void)tasksEnded:(NSNotification *)notif {
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	if (autoShow) {
		[self performSelectorOnMainThread:@selector(setHideTimer) withObject:nil waitUntilDone:YES];
	}
}

- (void)showIfNeeded:(NSNotification *)notif {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"QSShowTaskViewerAutomatically"]) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self]; // selector:@selector(autoHide) object:nil];
		if (![[self window] isVisible] || [(QSDockingWindow *)[self window] hidden]) {
			autoShow = YES;
			[(QSDockingWindow *)[self window] showKeyless:self];
		}
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
	
	int i, count;
	for (i = 0, count = [[self tasks] count]; i<count; i++) {
		QSTask *task = [[self tasks] objectAtIndex:i];
		int index = [oldTasks indexOfObject:task];
		NSView *view = nil;
		if (index != NSNotFound) {
			view = [oldTaskViews objectAtIndex:index];
		}
		if (!view) view = [self taskViewForTask:task];
		if (view) {
			NSRect frame = [view frame];
			frame.origin = NSMakePoint(0, NSHeight([tasksView frame]) -NSHeight([view frame])*(i+1));
			frame.size.width = NSWidth([[tasksView enclosingScrollView] frame]);
			[view setFrame:frame];
			[tasksView addSubview:view];
			[newTaskViews addObject:view];
		}
	}
	
	[oldTaskViews removeObjectsInArray:newTaskViews];
	
	[oldTaskViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[oldTaskViews makeObjectsPerformSelector:@selector(setTask:) withObject:nil];
	[tasksView setNeedsDisplay:YES];
	
	[oldTaskViews release];
	
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
	float newHeight = -1+MAX([(NSArray *)[controller arrangedObjects] count] , 1) *55;
	float heightChange = newHeight-NSHeight(tableRect);
	windowRect.size.height += heightChange;
//	if (!atBottom)
		windowRect.origin.y -= heightChange;
	[[tasksView window] setFrame:constrainRectToRect(windowRect, [[[self window] screen] frame]) display:YES animate:YES];
}

- (NSMutableArray *)tasks {
	if (!tasks)
		tasks = [[QSTaskController sharedInstance] tasks];
	return tasks;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex { return NO; }

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[hideTimer release];
	[updateTimer release];
	[tasks release];
	
	[super dealloc];
}

@end
