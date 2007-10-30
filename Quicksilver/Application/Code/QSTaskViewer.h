

#import <AppKit/AppKit.h>


@interface QSTaskViewer : NSWindowController {
    IBOutlet NSView *tasksView;
    NSTimer *hideTimer;
    NSTimer *updateTimer;
	BOOL autoShow;
	NSMutableArray *tasks;
	IBOutlet NSArrayController *controller;
}
+ (QSTaskViewer *)sharedInstance;
- (void)resizeTableToFit;
- (NSMutableArray *)tasks;
-(void)hideWindow:(id)sender;
-(void)showWindow:(id)sender;
-(void) refreshAllTasks:(NSNotification *)notif;
@end
