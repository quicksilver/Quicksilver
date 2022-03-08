

#import "QSResizingInterfaceController.h"

#import "QSSearchObjectView.h"
#import "QSAction.h"
#import "QSTextProxy.h"

@implementation QSResizingInterfaceController

- (id)initWithWindowNibName:(NSString *)nib {
	self = [super initWithWindowNibName:nib];
	if (self) {
		expanded = YES;
	}
	return self;
}

- (void)showIndirectSelector:(id)sender {
	QSGCDMainSync(^{
		[super showIndirectSelector:sender];
		[self adjustWindow:nil];
	});
}
- (void)hideIndirectSelector:(id)sender {
	QSGCDMainSync(^{
		[super hideIndirectSelector:sender];
		[self adjustWindow:nil];
	});
}

- (void)resetAdjustTimer {
    NSLog(@"This method is deprecated, call [self adjustWindow:nil] instead\nUsing interface: %@",[[NSUserDefaults standardUserDefaults] stringForKey:@"QSCommandInterfaceControllers"]);
    [self adjustWindow:nil];
}

- (void)adjustWindow:(id)sender {
	QSAction *action = (QSAction *)[aSelector objectValue];
	if (action && ![action isKindOfClass:[QSAction class]]) {
		NSLog(@"Non-action in aSelector, resetting: %@", action);
		[self clearObjectView:aSelector];
		return;
	}
	NSInteger argumentCount = [action argumentCount];

//	NSLog(@"adjust x%d", argumentCount);
	if (argumentCount == 2) {
		BOOL indirectOptional = [action indirectOptional];

//		  NSLog(@"adjust %d", indirectOptional);
		// When the 3rd pane is not optional, show it (most likely case, so first)

		if (!indirectOptional) {
			// must show 3rd field, indirect is optional
			[self expandWindow:sender];
			return;
		} else {
			// indirect is optional
			NSResponder *firstResponder = [[self window] firstResponder];
			BOOL focusingiSelector = (firstResponder == iSelector
			|| firstResponder == [iSelector currentEditor]);
			if (focusingiSelector) {
				// show 3rd pane if explicitly tabbing to it (becoming first responder)
				[self expandWindow:sender];
				return;
			}
			
		}
	}
	if (expanded) {
		[self contractWindow:sender];
	}

}

- (void)firstResponderChanged:(NSResponder *)aResponder {
	if (!aResponder || [aResponder isKindOfClass:[QSObjectView class]]) {
		// only adjust the window if the search object view has changed (not if another item has taken first responder
		[self adjustWindow:nil];
	}
}

- (void)expandWindow:(id)sender {
	expanded = YES;
}

- (void)contractWindow:(id)sender {
	expanded = NO;
}

- (BOOL)expanded {return expanded;  }
@end
