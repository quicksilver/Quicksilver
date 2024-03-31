
#import <Foundation/Foundation.h>

#import "QSInterfaceController.h"

@interface QSResizingInterfaceController : QSInterfaceController {
	BOOL expanded;
}
- (void)firstResponderChanged:(NSResponder *)aResponder;
- (void)resetAdjustTimer __attribute__((deprecated("Use -adjustWindow:")));
- (void)expandWindow:(id)sender;
- (void)contractWindow:(id)sender;

- (BOOL)expanded;
- (void)adjustWindow:(id)sender;
@end
