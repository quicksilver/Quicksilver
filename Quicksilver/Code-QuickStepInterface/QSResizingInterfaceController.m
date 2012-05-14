

#import "QSResizingInterfaceController.h"

#import "QSSearchObjectView.h"
#import "QSAction.h"
#import "QSTextProxy.h"
@implementation QSResizingInterfaceController

- (id)initWithWindowNibName:(NSString *)nib {
	self = [super initWithWindowNibName:nib];
	if (self) {
		expandTimer = nil;
		expanded = YES;
	}
	return self;
}

- (void)showIndirectSelector:(id)sender {
	[super showIndirectSelector:sender];
	[self resetAdjustTimer];
}
- (void)hideIndirectSelector:(id)sender {
	[super hideIndirectSelector:sender];
	[self resetAdjustTimer];
}

- (void)resetAdjustTimer {

	if ([[self window] isVisible]) {
		if (![expandTimer isValid]) {
			[expandTimer release];
			expandTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(adjustWindow:) userInfo:nil repeats:NO] retain];
		} else {
			[expandTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		}
	} else {
		[self adjustWindow:self];
	}
}

- (void)adjustWindow:(id)sender {
	QSAction *action = (QSAction *)[aSelector objectValue];
	int argumentCount = [action argumentCount];

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
				 || firstResponder == [iSelector currentEditor]
				 || ([iSelector objectValue] != nil && ![[iSelector objectValue] objectForType:QSTextProxyType]) ) {
				[self expandWindow:sender];
				return;
			}
		}
	}
		[self contractWindow:sender];

}

- (void)firstResponderChanged:(NSResponder *)aResponder {
	if (aResponder == iSelector || aResponder == [iSelector currentEditor]) {
		QSAction *action = (QSAction *)[aSelector objectValue];
		int argumentCount = [action argumentCount];
		BOOL indirectOptional = [action indirectOptional];
		
		if (argumentCount == 2 && indirectOptional)
			[self adjustWindow:self];
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
