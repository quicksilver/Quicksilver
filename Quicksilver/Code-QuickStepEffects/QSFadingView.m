//
// QSFadingBox.m
// QSPrimerInterfacePlugIn
//
// Created by Alcor on 12/25/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "QSFadingView.h"


@interface NSView (NSDecendantsPrivate)
- (void)_setDrawsOwnDescendants:(BOOL)flag;
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
- (float)opacity { return opacity;  }
- (void)setOpacity:(float)newOpacity {
	if (opacity != newOpacity)
		[self setNeedsDisplay:YES];
	opacity = newOpacity;
}

- (void)_recursiveDisplayAllDirtyWithLockFocus:(BOOL)lock visRect:(NSRect)rect {
	if (opacity >= 1.0) {
		[(id)super _recursiveDisplayAllDirtyWithLockFocus:(BOOL)lock visRect:(NSRect)rect];
	} else if(opacity) {
		CGContextRef context = (CGContextRef) ([[NSGraphicsContext currentContext] graphicsPort]);
		CGContextSaveGState(context);
		CGContextSetAlpha(context, opacity);
		CGContextBeginTransparencyLayer(context, 0);
		[(id)super _recursiveDisplayAllDirtyWithLockFocus:(BOOL)lock visRect:(NSRect)rect];
		CGContextEndTransparencyLayer(context);
		CGContextRestoreGState(context);
	}
}

- (void)drawRect:(NSRect)rect {}

@end
