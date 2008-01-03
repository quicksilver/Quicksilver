//
//  QSGlossyBarView.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 4/25/06.

//

@implementation NSButtonCell (TakeAttributes)
- (void) takeAttributesOfCell:(NSButtonCell *)cell {
//  [self setBezeled:[cell isBezeled]];
	[self setImage:[cell image]];
	[self setTitle:[cell title]];
	[self setImagePosition:[cell imagePosition]];
//	[self setBordered:[cell isBordered]];
//	[self setHighlightsBy:[cell highlightsBy]];
}
@end

void QSDrawGlossyRect( NSRect rect, BOOL topOnly, BOOL lightSides, BOOL flipped ) {
	[[NSColor colorWithCalibratedWhite:0.9 alpha:1.0] set];
//	[[NSColor blueColor]set];
	NSRectFill( rect );
	NSRect gradientRect, borderRect, highlightRect, rest;

	NSDivideRect( rect, &gradientRect, &rest, NSHeight(rect) / 2, (flipped ? NSMinYEdge : NSMaxYEdge ));
	
	QSFillRectWithGradientFromEdge( rest, [NSColor colorWithCalibratedWhite:0.89 alpha:1.0],
                                    [NSColor colorWithCalibratedWhite:0.95 alpha:1.0], (flipped ? NSMinYEdge : NSMaxYEdge));
	
	QSFillRectWithGradientFromEdge( gradientRect, [NSColor colorWithCalibratedWhite:1.0 alpha:1.0],
								   [NSColor colorWithCalibratedWhite:0.94 alpha:1.0], (flipped ? NSMinYEdge : NSMaxYEdge));
	
	
	if (lightSides) {
		NSRect innerRect = ( topOnly ? rect : NSInsetRect( rect, 1, 0 ) );
		[[NSColor colorWithCalibratedWhite:1.0 alpha:0.5] set];
		NSDivideRect( innerRect, &highlightRect, &rest, 1, NSMinXEdge );
		NSRectFillUsingOperation( highlightRect, NSCompositeSourceOver );
		NSDivideRect( innerRect, &highlightRect, &rest, 1, NSMaxXEdge );
		NSRectFillUsingOperation( highlightRect, NSCompositeSourceOver );
		
	}
	
	if (topOnly) {
		NSDivideRect( rect, &borderRect, &rest, 1, ( flipped ? NSMinYEdge : NSMaxYEdge ) );
	} else {
		borderRect = rect;
		borderRect.size.height++;
		if (!flipped)
			borderRect.origin.y--;
	}
	
	[[NSColor colorWithCalibratedWhite:0.0 alpha:0.2] set];

	NSFrameRectWithWidthUsingOperation( borderRect, 1.0, NSCompositeSourceOver );
	
    // Drawing code here.
}

#import "QSGlossyBarView.h"

@implementation QSGlossyBarButtonCell
- (id) initTextCell:(NSString *)aString {
	self = [super initTextCell:(NSString *)aString];
	if (self != nil) {
		//[self setBezelStyle:NSSmallSquareBezelStyle];
		[self setBordered:NO];
		[self setBezeled:NO];
		[self setHighlightsBy:NSNoCellMask];
	}
	return self;
}

- (void) drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	QSDrawGlossyRect( cellFrame, NO, YES, [controlView isFlipped]);
	//QSLog(@"fillframe %d",[controlView isFlipped]);
	if ([self isHighlighted]) {
		[[NSColor colorWithCalibratedWhite:0.0 alpha:0.333] set];
		NSRectFillUsingOperation( cellFrame, NSCompositeSourceOver );
	}
	cellFrame.size.height-=1;
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}
@end

@implementation QSGlossyBarButton
+ (Class) cellClass {
	return [QSGlossyBarButtonCell class];
}

- (void) mouseDown:(NSEvent *)event {
	[[self superview] addSubview:self
					  positioned:NSWindowAbove
                      relativeTo:nil];
    [super mouseDown:event];
}

- (BOOL) isFlipped { return NO; }
- (id) initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
	if (self) {
		NSButtonCell *oldCell = [self cell];
		QSGlossyBarButtonCell *newCell = [[[QSGlossyBarButtonCell alloc] initTextCell:[self title]] autorelease];
		[newCell takeAttributesOfCell:oldCell];
		
		[self setCell:newCell];
		
		
	}
	return self;
}
@end

@implementation QSGlossyBarMenuButton
- (void) mouseDown:(NSEvent *)event {
	[[self superview] addSubview:self
					  positioned:NSWindowAbove
                      relativeTo:nil];
    [super mouseDown:event];
}

+ (Class) cellClass{
	return [QSGlossyBarButtonCell class];
}


- (id) initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
	if (self) {
		NSButtonCell *oldCell = [self cell];
		QSGlossyBarButtonCell *newCell = [[[QSGlossyBarButtonCell alloc] initTextCell:[self title]] autorelease];
		[newCell takeAttributesOfCell:oldCell];
		[self setCell:newCell];
	}
	return self;
}
@end

@implementation QSGlossyBarView
- (id) initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void) drawRect:(NSRect)rect {
	NSRect frame = [self frame];
	frame.origin = NSZeroPoint;
	QSDrawGlossyRect( frame, YES, YES, [self isFlipped]);
}

@end
