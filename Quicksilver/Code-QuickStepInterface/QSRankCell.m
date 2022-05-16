

#import "QSRankCell.h"
#import "QSObject.h"
#import <math.h>

#import <QSFoundation/QSFoundation.h>
@implementation QSRankCell
- (id)initImageCell:(NSImage *)anImage {
	if (self = [super initImageCell:anImage]) {

	}
	return self;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	// float score = 1.0; //[[self objectValue] score];
	//int order = 1; //[[self objectValue] order];
	//NSLog(@"score %f %d", score, order);

	NSBezierPath *roundRect = [NSBezierPath bezierPath];
	[roundRect appendBezierPathWithRoundedRectangle:cellFrame withRadius:MIN(NSHeight(cellFrame), NSWidth(cellFrame))/2];

	CGFloat size = MIN(NSHeight(cellFrame), NSWidth(cellFrame) );
	NSRect drawRect = centerRectInRect(NSMakeRect(0, 0, size/2, size/2), cellFrame);
	NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:drawRect];
	[[NSColor whiteColor] set];

	[[NSBezierPath bezierPathWithOvalInRect:NSInsetRect(drawRect, -1, -1)] fill];

	if (self.order != NSNotFound) { // defined mnemonic
		[path setLineWidth:2];
		if (self.order == 0) {
			[[[NSColor blackColor] colorWithAlphaComponent:0.8] set];

			NSRect dotRect = centerRectInRect(NSMakeRect(0, 0, size/4, size/4), cellFrame);

			[[NSBezierPath bezierPathWithOvalInRect:dotRect] fill];
		}
		[[[NSColor alternateSelectedControlColor] colorWithAlphaComponent:MIN(self.score/4, 1)] set];
	} else {
		[[[NSColor blackColor] colorWithAlphaComponent:MAX(MIN(self.score/4, 1), 0.08)] set];

	}

	[path fill];
	[path stroke];


	//  NSLog(@"val %@", [self objectValue]);
}

@end
