//
// QSFadingBox.m
// QSPrimerInterfacePlugIn
//
// Created by Alcor on 12/25/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "QSFadingView.h"

@interface NSView (QSAppKitPrivate)
- (void)_setDrawsOwnDescendants:(BOOL)flag;
- (void)_recursiveDisplayAllDirtyWithLockFocus:(BOOL)lock visRect:(NSRect)rect;
@end

@implementation QSFadingView

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		opacity = 1.0;
		[self _setDrawsOwnDescendants:YES];
	}
	return self;
}
- (CGFloat)opacity { return opacity;  }
- (void)setOpacity:(CGFloat)newOpacity {
	if (opacity != newOpacity)
		[self setNeedsDisplay:YES];
	opacity = newOpacity;
}

- (void)_recursiveDisplayAllDirtyWithLockFocus:(BOOL)lock visRect:(NSRect)rect {
	if (opacity >= 1.0) {
		[super _recursiveDisplayAllDirtyWithLockFocus:lock visRect:rect];
	} else if(opacity) {
		CGContextRef context = (CGContextRef) ([[NSGraphicsContext currentContext] graphicsPort]);
		CGContextSaveGState(context);
		CGContextSetAlpha(context, opacity);
		CGContextBeginTransparencyLayer(context, 0);
		[super _recursiveDisplayAllDirtyWithLockFocus:lock visRect:rect];
		CGContextEndTransparencyLayer(context);
		CGContextRestoreGState(context);
	}
}

- (void)drawRect:(NSRect)rect {}

@end
