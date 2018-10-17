//
// QSGlossyBarView.m
// Quicksilver
//
// Created by Nicholas Jitkoff on 4/25/06.
// Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <QSEffects/QSShading.h>

@interface NSButtonCell (TakeAttributes)
- (void)takeAttributesOfCell:(NSButtonCell *)cell;
@end

@implementation NSButtonCell (TakeAttributes)
- (void)takeAttributesOfCell:(NSButtonCell *)cell {
	[self setImage:[cell image]];
	[self setTitle:[cell title]];
	[self setImagePosition:[cell imagePosition]];
}
@end

void QSDrawGlossyRect(NSRect rect, BOOL topOnly, BOOL lightSides, BOOL flipped) {
	[[NSColor colorWithCalibratedWhite:0.9 alpha:1.0] set];
	NSRectFill(rect);
	NSRect gradientRect, borderRect, highlightRect, rest;
	NSDivideRect(rect, &gradientRect, &rest, NSHeight(rect)/2, flipped?NSMinYEdge:NSMaxYEdge);
	QSFillRectWithGradientFromEdge(rest, [NSColor colorWithCalibratedWhite:0.89 alpha:1.0], [NSColor colorWithCalibratedWhite:0.95 alpha:1.0], flipped?NSMinYEdge:NSMaxYEdge);
	QSFillRectWithGradientFromEdge(gradientRect, [NSColor colorWithCalibratedWhite:1.0 alpha:1.0], [NSColor colorWithCalibratedWhite:0.94 alpha:1.0], flipped?NSMinYEdge:NSMaxYEdge);

	if (lightSides) {
		NSRect innerRect = topOnly?rect:NSInsetRect(rect, 1, 0);
		[[NSColor colorWithCalibratedWhite:1.0 alpha:0.5] set];
		NSDivideRect(innerRect, &highlightRect, &rest, 1, NSMinXEdge);
		NSRectFillUsingOperation(highlightRect, NSCompositingOperationSourceOver);
		NSDivideRect(innerRect, &highlightRect, &rest, 1, NSMaxXEdge);
		NSRectFillUsingOperation(highlightRect, NSCompositingOperationSourceOver);

	}
	if (topOnly) {
		NSDivideRect(rect, &borderRect, &rest, 1, flipped?NSMinYEdge:NSMaxYEdge);
	} else {
		borderRect = rect;
		borderRect.size.height++;
		if (!flipped)
			borderRect.origin.y--;
	}
	[[NSColor colorWithCalibratedWhite:0.0 alpha:0.2] set];
	NSFrameRectWithWidthUsingOperation(borderRect, 1.0, NSCompositingOperationSourceOver);
}

#import "QSGlossyBarView.h"

@implementation QSGlossyBarButtonCell
- (id)initTextCell:(NSString *)aString {
	if ((self = [super initTextCell:(NSString *)aString])) {
		[self setBordered:NO];
		[self setBezeled:NO];
		[self setHighlightsBy:NSNoCellMask];
	}
	return self;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
//- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
//- (void)drawBezelWithFrame:(NSRect)cellFrame inView:(NSView*)controlView {
	QSDrawGlossyRect(cellFrame, FALSE, TRUE, [controlView isFlipped]);
	if ([self isHighlighted]) {
		[[NSColor colorWithCalibratedWhite:0.0 alpha:0.333] set];
		NSRectFillUsingOperation(cellFrame, NSCompositingOperationSourceOver);
	}
	cellFrame.size.height -= 1;
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}
@end

@implementation QSGlossyBarButton
+ (Class) cellClass {
	return [QSGlossyBarButtonCell class];
}
- (void)mouseDown:(NSEvent *)event {
	[[self superview] addSubview:self positioned:NSWindowAbove relativeTo:nil];
	[super mouseDown:event];
}
- (BOOL)isFlipped {return NO;}
- (id)initWithCoder:(NSCoder *)decoder {
	if ( self = [super initWithCoder:decoder] ) {
		NSCell *oldCell = [self cell];
		NSCell *newCell = [[QSGlossyBarButtonCell alloc] initTextCell:[self title]];
		[(NSButtonCell*)newCell takeAttributesOfCell:(NSButtonCell*)oldCell];
		[self setCell:newCell];
	}
	return self;
}
@end

@implementation QSGlossyBarMenuButton
- (void)mouseDown:(NSEvent *)event {
	[[self superview] addSubview:self positioned:NSWindowAbove relativeTo:nil];
	[super mouseDown:event];
}
+ (Class) cellClass {
	return [QSGlossyBarButtonCell class];
}
- (id)initWithCoder:(NSCoder *)decoder {
	if ( self = [super initWithCoder:decoder] ) {
		NSCell *oldCell = [self cell];
		NSCell *newCell = [[QSGlossyBarButtonCell alloc] initTextCell:[self title]];
		[(NSButtonCell*)newCell takeAttributesOfCell:(NSButtonCell*)oldCell];
		[self setCell:newCell];
	}
	return self;
}

-(BOOL)performKeyEquivalent:(NSEvent *)theEvent {
    BOOL keyIsGood = [super performKeyEquivalent:theEvent];
    if (keyIsGood) {
        [[self menu] popUpMenuPositioningItem:nil atLocation:NSMakePoint(0,-4) inView:[self superview]];
    }
    return keyIsGood;
}

@end

@implementation QSGlossyBarView
- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
#if 0
	if (self) {
		// Initialization code here.
	}
#endif
	return self;
}
- (void)drawRect:(NSRect)rect {
	NSRect frame = [self frame];
	frame.origin = NSZeroPoint;
	QSDrawGlossyRect(frame, TRUE, TRUE, [self isFlipped]);
}
@end
