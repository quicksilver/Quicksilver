
#import <Foundation/Foundation.h>

#import "QSInterfaceController.h"

@interface QSResizingInterfaceController : QSInterfaceController {
	BOOL expanded;
}
- (void)firstResponderChanged:(NSResponder *)aResponder;
- (void)resetAdjustTimer DEPRECATED_ATTRIBUTE;
- (void)expandWindow:(id)sender;
- (void)contractWindow:(id)sender;

- (BOOL)expanded;
- (void)adjustWindow:(id)sender;
@end
