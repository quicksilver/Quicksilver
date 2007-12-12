//
// QSHandledSplitView.m
// Quicksilver
//
// Created by Nicholas Jitkoff on 4/20/06.
// Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "QSHandledSplitView.h"

@implementation QSHandledSplitView

- (id)initWithCoder:(id)coder {
	self = [super initWithCoder:(id)coder];
	if (self) {
 dividerThickness = 1.0;
		drawsDivider = YES;
	}
	return self;
}

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
dividerThickness = 1.0;
		drawsDivider = YES;
	}
	return self;
}

- (void)placeDragHandleInSubview:(id)fp8 {}

- (void)drawDividerInRect:(NSRect)rect {
	if (drawsDivider) {
	[[NSColor lightGrayColor] set];
	NSRectFill(rect);
	}
}

- (BOOL)drawsDivider { return drawsDivider; }
- (void)setDrawsDivider:(BOOL)flag { drawsDivider = flag; }

- (float)dividerThickness { return dividerThickness; }
- (void)setDividerThickness:(float)newDividerThickness { dividerThickness = newDividerThickness; }

@end
