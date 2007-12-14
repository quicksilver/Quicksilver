//
//  QSCubeInterfaceBackgroundView.m
//  QSCubeInterfacePlugIn
//
//  Created by Nicholas Jitkoff on 6/16/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "QSCubeInterfaceBackgroundView.h"

@implementation QSCubeInterfaceBackgroundView

- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    // Initialization code here.
  }
  return self;
}

- (void)drawRect:(NSRect)rect {
	//[super drawRect:rect];
  
	NSBezierPath *cornerEraser = nil;
	NSRect fullRect = [self convertRect:[self frame] fromView:[self superview]];
	
	if (![[self window] isOpaque] && [[self window] contentView] == self && [[self window] backgroundColor] == [NSColor clearColor]) {
		cornerEraser = [NSBezierPath bezierPath];
		//logRect([self frame]);
		[cornerEraser appendBezierPathWithRoundedRectangle:fullRect withRadius:8];
		[cornerEraser addClip];
	}
	NSRect topRect, bottomRect;
	NSDivideRect(fullRect, &topRect, &bottomRect, NSHeight(fullRect) /2, NSMaxYEdge);
	
  
  NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:startColor
                                                        endingColor:endColor] autorelease];
	[gradient drawInRect:fullRect angle: 270];
  
//	QSFillRectWithGradientFromEdge(fullRect, startColor, endColor, NSMaxYEdge);
	
  
	if 	(glassType >= 0) {
    [[NSGraphicsContext currentContext] saveGraphicsState];
		[QSGlossClipPathForRectAndStyle(fullRect, glassType) addClip];
		[highlightColor set];
		NSRectFillUsingOperation(fullRect, NSCompositeSourceOver);
    
    //NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:highlightColor
//                                                          endingColor:[highlightColor colorWithAlphaComponent:0.8]] autorelease];
//    [gradient drawInRect:fullRect angle: 90];
//    
    [[NSGraphicsContext currentContext] restoreGraphicsState];
	}
	
  
	[borderColor set];
	[cornerEraser setLineWidth:borderWidth];
	[cornerEraser stroke];
	//NSFrameRectWithWidthUsingOperation(fullRect, 1.0, NSCompositeSourceOver);
}


- (NSColor *)startColor { return [[startColor retain] autorelease];  }
- (void)setStartColor: (NSColor *)newStartColor
{
  if (startColor != newStartColor) {
    [startColor release];
    startColor = [newStartColor copy];
  }
	[self setNeedsDisplay:YES];
}


- (NSColor *)endColor { return [[endColor retain] autorelease];  }
- (void)setEndColor: (NSColor *)newEndColor
{
  if (endColor != newEndColor) {
    [endColor release];
    endColor = [newEndColor copy];
  }
	[self setNeedsDisplay:YES];
}


- (NSColor *)highlightColor { return [[highlightColor retain] autorelease];  }
- (void)setHighlightColor: (NSColor *)newHighlightColor
{
  if (highlightColor != newHighlightColor) {
    [highlightColor release];
    highlightColor = [newHighlightColor copy];
  }
	[self setNeedsDisplay:YES];
}


- (NSColor *)borderColor { return [[borderColor retain] autorelease];  }
- (void)setBorderColor: (NSColor *)newBorderColor
{
  if (borderColor != newBorderColor) {
    [borderColor release];
    borderColor = [newBorderColor copy];
  }
	[self setNeedsDisplay:YES];
  
}


- (int) glassType { return glassType;  }
- (void)setGlassType: (int) newGlassType
{
  glassType = newGlassType;
	[self setNeedsDisplay:YES];
  
}



- (void)dealloc
{
  [self setStartColor: nil];
  [self setEndColor: nil];
  [self setHighlightColor: nil];
  [self setBorderColor: nil];
  [super dealloc];
}


@end
