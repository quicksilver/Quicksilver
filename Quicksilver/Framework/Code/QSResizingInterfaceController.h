

#import <Foundation/Foundation.h>

#import "QSInterfaceController.h"

@interface QSResizingInterfaceController : QSInterfaceController {
    BOOL expanded;
    NSTimer *expandTimer;
}
- (void)resetAdjustTimer;
- (void)expandWindow:(id)sender;
- (void)contractWindow:(id)sender;

- (BOOL)expanded;
- (void)adjustWindow:(id)sender;
@end
