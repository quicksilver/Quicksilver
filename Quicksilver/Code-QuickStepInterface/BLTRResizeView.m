//
//  BLTRResizeView.m
//  Quicksilver
//
//  Created by Alcor on Sat Aug 30 2003.
//  Copyright (c) 2003 Blacktree. All rights reserved.
//

#import "BLTRResizeView.h"

@implementation BLTRResizeView

- (id)initWithFrame:(NSRect)frame {
	if (self = [super initWithFrame:frame]) {
		[self setAutoresizingMask:NSViewMinXMargin];
	}
	return self;
}

- (void)awakeFromNib { [self setAutoresizingMask:NSViewMinXMargin]; }

- (void)drawRect:(NSRect)rect {
	NSAffineTransform* transform = [NSAffineTransform transform];
	if (oppositeQuadrant(closestCorner([self frame], [[self superview] frame])) == 3) {
		[transform scaleXBy:-1 yBy:1];
		[transform translateXBy:-16 yBy:0];
	}
	[transform concat];
	[[QSResourceManager imageNamed:@"ResizeWidget"] drawInRect:rect fromRect:rect operation:NSCompositingOperationSourceOver fraction:1.0];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent { return YES; }
- (BOOL)mouseDownCanMoveWindow { return NO; }

- (void)mouseDown:(NSEvent *)theEvent {
	mouseDownPoint = [[self window] convertBaseToScreen:[theEvent locationInWindow]];
	oldFrame = [[self window] frame];

	quadrant = oppositeQuadrant(closestCorner([self frame], [[self superview] frame]));
}

- (void)mouseDragged:(NSEvent *)event {
	NSPoint eventLocation = [[self window] convertBaseToScreen:[event locationInWindow]];
	NSPoint eventOffset = NSMakePoint(eventLocation.x-mouseDownPoint.x, eventLocation.y-mouseDownPoint.y);

	NSRect newFrame = oldFrame;
	NSPoint frameOffset = NSZeroPoint;

	NSInteger xMod = (quadrant == 3 || quadrant == 2) ? -1 : 1;
	NSInteger yMod = (quadrant == 4 || quadrant == 3) ? -1 : 1;
	NSPoint sizeOffset = NSMakePoint(xMod*eventOffset.x, yMod*eventOffset.y);
	newFrame.size.width = MAX([[self window] minSize] .width, NSWidth(oldFrame) +sizeOffset.x);
	newFrame.size.height = MAX([[self window] minSize] .height, NSHeight(oldFrame) +sizeOffset.y);
	frameOffset = rectOffset(newFrame, oldFrame, quadrant);

	newFrame = NSOffsetRect(newFrame, frameOffset.x, frameOffset.y);
	[[self window] setFrame:newFrame  display:YES animate:NO];
}

@end
