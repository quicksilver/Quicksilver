#import <QSCrucible/QSDockingWindow.h>

#import "QSTaskViewer.h"
#import "QSTaskView.h"


#define HIDE_TIME 0.2
@implementation QSTaskViewer
+ (QSTaskViewer *)sharedInstance {
    static QSTaskViewer * _sharedInstance;
    if (!_sharedInstance) _sharedInstance = [[[self class] allocWithZone:[self zone]] init];
    return _sharedInstance;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[tasksView release];
    [hideTimer release];
    [updateTimer release];
    [tasks release];
    [controller release];
	
    tasksView = nil;
    hideTimer = nil;
    updateTimer = nil;
    tasks = nil;
    controller = nil;
	
	[super dealloc];
}

- (id)init {
    self = [self initWithWindowNibName:@"QSTaskViewer"];
    if (self) {     
		//	if (VERBOSE)
		//		QSLog(@"creating task viewer");
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskAdded:) name:QSTaskAddedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tasksEnded:) name:QSTasksEndedNotification object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAllTasks:) name:QSTaskAddedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAllTasks:) name:QSTaskChangedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAllTasks:) name:QSTaskRemovedNotification object:nil];
		hideTimer = nil;
	}
    return self;
}


- (void)windowDidLoad {
	[[self window] addInternalWidgetsForStyleMask:NSUtilityWindowMask];
    [[self window] setHidesOnDeactivate:NO];
    [[self window] setLevel:NSFloatingWindowLevel];
	[[self window] setBackgroundColor:[NSColor whiteColor]];
	[[self window] setOpaque:YES];
	// [[self window] addInternalWidgets];
	[(QSDockingWindow *)[self window] setAutosaveName:@"QSTaskViewerWindow"]; // should use the real methods to do this
	
	[[self window] display];
	[self refreshAllTasks:nil];
	[self resizeTableToFit];
}

- (void)showWindow:(id)sender {
	[self window];
	[(QSDockingWindow *)[self window] show:sender];
	//[tableView reloadData];
	//[self resizeTableToFit];
	[super showWindow:sender];
}

- (void)hideWindow:(id)sender {
	[[self window] close];
}

- (void)setHideTimer {
	[self performSelector:@selector(autoHide) withObject:nil afterDelay:HIDE_TIME extend:YES];
	//	if ([hideTimer isValid]) {
	//		[hideTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:HIDE_TIME]];
	//	} else {
	//		[hideTimer release];
	//		hideTimer = [[NSTimer scheduledTimerWithTimeInterval:HIDE_TIME target:self selector:@selector(autoHide) userInfo:nil repeats:NO] retain];
	//		
	//	}
	//		QSLog(@"set, %@", [hideTimer fireDate]);
}
- (id)taskController {return QSTasks;}

- (void)taskAdded:(NSNotification *)notif {
	//QSLog(@"taskadded"); 	
	[self performSelector:@selector(showIfNeeded:) withObject:self afterDelay:0.5 extend:NO];
}
- (void)tasksEnded:(NSNotification *)notif {
	//QSLog(@"ended! %d", autoShow);
	[NSObject cancelPreviousPerformRequestsWithTarget:self]; // selector:@selector(showIfNeeded:) object:self];
	
	
	
	if (autoShow) {
		[self performSelectorOnMainThread:@selector(setHideTimer) withObject:nil waitUntilDone:YES];
	}
}


- (void)showIfNeeded:(NSNotification *)notif {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"QSShowTaskViewerAutomatically"]) {
		//	[hideTimer invalidate];
		
		[NSObject cancelPreviousPerformRequestsWithTarget:self]; // selector:@selector(autoHide) object:nil];
																//QSLog(@"show if needed %d %d", [[self window] isVisible] , [[self window] hidden]);
		
		if (![[self window] isVisible] || [(QSDockingWindow *)[self window] hidden]) {
			//QSLog(@"show if needed %d", autoShow);
			
			autoShow = YES;
			[(QSDockingWindow *)[self window] showKeyless:self];
		}  
	}
}
NSNib *taskEntryNib = nil;

- (QSTaskView *)taskViewForTask:(QSTask *)task {
	//QSLog(@"making new view for %@", [task identifier]);
	NSArray *objects = nil;
	if (!taskEntryNib) taskEntryNib = [[NSNib alloc] initWithNibNamed:@"QSTaskEntry" bundle:[NSBundle mainBundle]];
	[taskEntryNib instantiateNibWithOwner:task topLevelObjects:&objects];
	QSTaskView *view = [objects lastObject];
	[view autorelease]; // I think that the owner normally retains the object
	return view;
}

- (void)refreshAllTasks:(NSNotification *)notif {
	[controller rearrangeObjects];
	
	NSMutableArray *oldTaskViews = [[[tasksView subviews] mutableCopy] autorelease];
	NSArray *oldTasks = [oldTaskViews valueForKey:@"task"];
	NSMutableArray *newTaskViews = [NSMutableArray array];
	
//	NSMutableArray *animations = [NSMutableArray array];
	int i;
	for (i = 0; i<[[self tasks] count]; i++) {
		QSTask *task = [[self tasks] objectAtIndex:i];
		int index = [oldTasks indexOfObject:task];
		NSView *view = nil;
		BOOL exists = index != NSNotFound;
		if (exists) {
			view = [oldTaskViews objectAtIndex:index];  
		}
		
		if (!view) view = [self taskViewForTask:task];
		
		NSRect frame = [view frame];
		frame.origin = NSMakePoint(0, NSHeight([tasksView frame]) -NSHeight([view frame])*(i+1));
		frame.size.width = NSWidth([[tasksView enclosingScrollView] frame]);
		
//		if (!exists)
			[view setFrame:frame];
//		[animations addObject:[NSDictionary dictionaryWithObjectsAndKeys:
//			view, NSViewAnimationTargetKey,
//			[NSValue valueWithRect:frame] , NSViewAnimationEndFrameKey,
//															  exists?nil:NSViewAnimationFadeInEffect, NSViewAnimationEffectKey,
//			nil]];
		[tasksView addSubview:view];
		[newTaskViews addObject:view];
	}
	
	[oldTaskViews removeObjectsInArray:newTaskViews];
	oldTasks = [oldTaskViews valueForKey:@"task"];

//	foreach(oldView, oldTaskViews) {
//		[animations addObject:[NSDictionary dictionaryWithObjectsAndKeys:
//			oldView, NSViewAnimationTargetKey,
//			NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey,
//			nil]];
//	}
	
//	NSViewAnimation *animation = [[NSViewAnimation alloc] initWithViewAnimations:animations];
//	[animation setDuration:0.2];
//	//[animation setAnimationCurve:NSAnimationLinear];
//	[animation setAnimationBlockingMode:NSAnimationNonblocking];
//	
//	[animation setFrameRate:60.0];
//	[animation setDelegate:self]; 	
//	[animation startAnimation];
//	[animation release];

	[oldTaskViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[tasksView setNeedsDisplay:YES];
	//[tasksView setFrame:NSMakeRect(0, 0, NSWidth([[tasksView enclosingScrollView] frame]), (55*i) )];
	
	if ([[self window] isVisible] && [[NSUserDefaults standardUserDefaults] boolForKey:@"QSResizeTaskViewerAutomatically"]) {
	//	[tableView reloadData];
	//	[[self window] showKeyless:nil];
	[self resizeTableToFit];
	}
	//[[self window] display];
	//QSLog(@"refresh");
	}

- (void)autoHide {
	
	//QSLog(@"hide!");
	[(QSDockingWindow *)[self window] hideOrOrderOut:self];
	autoShow = NO;
}

- (void)resizeTableToFit {
	//QSLog(@"resize");
    NSRect tableRect = [[tasksView enclosingScrollView] frame];
    NSRect windowRect = [[tasksView window] frame];
//	BOOL atBottom = NSMinY(windowRect) <= NSMinY([[[self window] screen] frame]);
    float newHeight = -1+MAX([[controller arrangedObjects] count] , 1) *55;

    float heightChange = newHeight-NSHeight(tableRect);
    windowRect.size.height += heightChange;
//	if (!atBottom)
		windowRect.origin.y -= heightChange;
	//		QSLog(@"newheight %f", heightChange);
    [[tasksView window] setFrame:constrainRectToRect(windowRect, [[[self window] screen] frame]) display:YES animate:YES];
}

- (NSMutableArray *)tasks {
    if (!tasks) {
        tasks = [[QSTaskController sharedInstance] tasks];
    }
	//QSLog(@"ttasks %@ %x", tasks, tasks);
    return [[tasks retain] autorelease];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex {
    return NO;
}

@end
