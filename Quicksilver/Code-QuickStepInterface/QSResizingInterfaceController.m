

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
	[super showIndirectSelector:sender];
	[self adjustWindow:nil];
}
- (void)hideIndirectSelector:(id)sender {
	[super hideIndirectSelector:sender];
	[self adjustWindow:nil];
}

- (void)resetAdjustTimer {
    NSLog(@"This method is deprecated, call [self adjustWindow:nil] instead\nUsing interface: %@",[[NSUserDefaults standardUserDefaults] stringForKey:@"QSCommandInterfaceControllers"]);
    [self adjustWindow:nil];
}

- (void)adjustWindow:(id)sender {
	QSAction *action = (QSAction *)[aSelector objectValue];
	NSInteger argumentCount = [action argumentCount];

//	NSLog(@"adjust x%d", argumentCount);
	if (argumentCount == 2) {
		BOOL indirectOptional = [[aSelector objectValue] indirectOptional];

//		  NSLog(@"adjust %d", indirectOptional);
		// When the 3rd pane is not optional, show it (most likely case, so first)
		if (!indirectOptional) {
			[self expandWindow:sender];
			return;
		} else {
			NSResponder *firstResponder = [[self window] firstResponder];
			if (firstResponder == iSelector
				 || firstResponder == [iSelector currentEditor]) {
				[self expandWindow:sender];
				return;
			}
		}
	}
		[self contractWindow:sender];

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
