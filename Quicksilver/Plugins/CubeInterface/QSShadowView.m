//
//  QSShadowView.m
//  QSCubeInterfacePlugIn
//
//  Created by Nicholas Jitkoff on 6/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "QSShadowView.h"


@implementation QSShadowView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self setColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.3333]];
		[self setBlur:8.0];
		blur=8.0;
		distance=10.0;
		angle=180.0;
    }
    return self;
}

- (void)updatePosition{
	NSRect newFrame=[[targetView window]frame];
	newFrame=[self paddedFrameForFrame:newFrame];
	[[self window]setFrame:newFrame display:YES];
}

- (NSRect)paddedFrameForFrame:(NSRect)frame{
	NSRect rect=NSInsetRect(frame,-expand-blur,-expand-blur);	
	rect=NSOffsetRect(rect,distance*sin(M_PI*angle/180),distance*cos(M_PI*angle/180));
	return rect;
}
#define HUGEOFFSET 10000
- (void)drawRect:(NSRect)rect {
	rect=[self frame];
	
//	[[NSColor blueColor] set];
//	NSFrameRect(rect);
	[NSGraphicsContext saveGraphicsState]; 
	NSShadow* theShadow = [[NSShadow alloc] init]; 
	[theShadow setShadowOffset:NSMakeSize(0.0,-NSHeight(rect))]; // Offset the shadow by the height of the window
	[theShadow setShadowBlurRadius:blur]; 
	[theShadow setShadowColor:color]; 
	[theShadow set];
	[[NSColor blackColor] set];
	NSRect drawRect=NSInsetRect([self frame],blur,blur);
	NSBezierPath *path=[NSBezierPath bezierPath];
	rect=NSOffsetRect(drawRect,0,NSHeight(rect)); // Draw above the window, placing only the shadow in view
	[path appendBezierPathWithRoundedRectangle:rect withRadius:expand];
	[path fill];
	[NSGraphicsContext restoreGraphicsState];
	[theShadow release]; 
}


- (NSView *) targetView { return [[targetView retain] autorelease]; }
- (void) setTargetView: (NSView *) newTargetView
{
    if (targetView != newTargetView) {
        [targetView release];
        targetView = [newTargetView retain];
    }
	[self updatePosition];
}


- (NSColor *) color { return [[color retain] autorelease]; }
- (void) setColor: (NSColor *) newColor
{
    if (color != newColor) {
        [color release];
        color = [newColor copy];
    }

	[self setNeedsDisplay:YES];
	[self updatePosition];

}



- (float) blur { return blur; }
- (void) setBlur: (float) newBlur
{
    blur = newBlur;
	[self setNeedsDisplay:YES];
	[self updatePosition];

}


- (float) distance { return distance; }
- (void) setDistance: (float) newDistance
{
    distance = newDistance;
	[self setNeedsDisplay:YES];
	[self updatePosition];

}


- (float) angle { return angle; }
- (void) setAngle: (float) newAngle
{
    angle = newAngle;
	[self setNeedsDisplay:YES];
	[self updatePosition];

}


- (float) expand { return expand; }
- (void) setExpand: (float) newExpand
{
    expand = newExpand;
	[self setNeedsDisplay:YES];
	[self updatePosition];

}



- (void) dealloc
{
    [self setTargetView: nil];
    [self setColor: nil];
    [super dealloc];
}


@end
