#import <AppKit/AppKit.h>

@interface QSTaskViewer : NSWindowController

+ (instancetype)sharedInstance;
- (void)hideWindow:(id)sender;
- (void)showWindow:(id)sender;
- (void)toggleWindow:(id)sender;
@end
