//
//  QSTitleToolbarView.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 5/8/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "QSTitleToolbarView.h"


@implementation QSTitleToolbarView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
	rect=[self frame];
	rect.origin=NSZeroPoint;
	rect=NSInsetRect(rect,0.5,0.5);
    // Drawing code here.
	[[NSColor colorWithDeviceWhite:1.0 alpha:0.2]setFill];
	[[NSColor colorWithDeviceWhite:0.0 alpha:0.1]setStroke];
	NSBezierPath *path=[NSBezierPath bezierPath];
	[path appendBezierPathWithRoundedRectangle:rect withRadius:4.0];
	[path fill];
	[path stroke];
	[path setClip];
	//QSFillRectWithGradientFromEdge(rect,[NSColor colorWithDeviceWhite:1.0 alpha:1.0],
//								  [NSColor colorWithDeviceWhite:0.95 alpha:1.0],
//								   NSMaxYEdge);
//	[self _drawRect:(NSRect)rect withGradientFrom:[NSColor colorWithDeviceWhite:1.0 alpha:0.8] to:[NSColor colorWithDeviceWhite:1.0 alpha:0.0] start:NSMinXEdge];    

	
	//	NSRectFill(rect);
}




@end
