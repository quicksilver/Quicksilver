#import <AppKit/AppKit.h>

@interface QSTaskViewer : NSWindowController

+ (instancetype)sharedInstance;
- (void)resizeTableToFit;
- (void)hideWindow:(id)sender;
- (void)showWindow:(id)sender;
- (void)refreshAllTasks:(NSNotification *)notif;
@end
