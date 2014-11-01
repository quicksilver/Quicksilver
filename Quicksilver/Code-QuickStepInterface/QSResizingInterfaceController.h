
#import <Foundation/Foundation.h>

#import "QSInterfaceController.h"

@interface QSResizingInterfaceController : QSInterfaceController {
	BOOL expanded;
}
- (void)firstResponderChanged:(NSResponder *)aResponder;
- (void)resetAdjustTimer QS_DEPRECATED_MSG("Use -adjustWindow:");
- (void)expandWindow:(id)sender;
- (void)contractWindow:(id)sender;

- (BOOL)expanded;
- (void)adjustWindow:(id)sender;
@end
