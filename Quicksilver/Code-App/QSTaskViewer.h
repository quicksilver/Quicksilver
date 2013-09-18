#import <AppKit/AppKit.h>

#import "QSTaskController.h"

@interface QSTaskViewer : NSWindowController {
	IBOutlet NSView *tasksView;
	NSTimer *hideTimer;
	NSTimer *updateTimer;
	BOOL autoShow;
	IBOutlet NSArrayController *controller;
}
+ (QSTaskViewer *)sharedInstance;
- (void)resizeTableToFit;
- (void)hideWindow:(id)sender;
- (void)showWindow:(id)sender;
- (void)refreshAllTasks:(NSNotification *)notif;
@end
