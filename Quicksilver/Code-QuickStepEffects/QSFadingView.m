//
// QSFadingBox.m
// QSPrimerInterfacePlugIn
//
// Created by Alcor on 12/25/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "QSFadingView.h"

@interface NSView (QSAppKitPrivate)
- (void)_recursiveDisplayAllDirtyWithLockFocus:(BOOL)lock visRect:(NSRect)rect;
@end

@implementation QSFadingView

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		opacity = 1.0;
	}
	return self;
}
- (CGFloat)opacity { return opacity;  }
- (void)setOpacity:(CGFloat)newOpacity {
	if (opacity != newOpacity)
		[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
			context.duration = 0.1;
			self.animator.alphaValue = newOpacity;
		}
		completionHandler:^{
			
		}];
	opacity = newOpacity;
}

@end
