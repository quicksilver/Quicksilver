//
//  QSFancyObjectCell.m
//  Quicksilver
//
//  Created by Alcor on 10/16/04.

//

#import "QSFancyObjectCell.h"
#import "QSObject.h"




@implementation QSFancyObjectCell
- (void)drawIconForObject:(QSObject *)object withFrame:(NSRect)cellFrame inView:(NSView *)controlView{
	NSRect drawingRect=NSIntegralRect(fitRectInRect(NSMakeRect(0,0,1,1),[self imageRectForBounds:cellFrame],NO));	
	[self drawObjectImage:object inRect:NSOffsetRect(drawingRect,0,-NSHeight(drawingRect)*1.1) cellFrame:cellFrame controlView:controlView flipped:![controlView isFlipped] opacity:0.2];	
    [self drawObjectImage:object inRect:drawingRect cellFrame:cellFrame controlView:controlView flipped:[controlView isFlipped] opacity:1.0];

}

- (void)drawObjectImage:(QSObject *)drawObject inRect:(NSRect)drawingRect cellFrame:(NSRect)cellFrame controlView:(NSView *)controlView flipped:(BOOL)flipped opacity:(float)opacity{
	
    [NSGraphicsContext saveGraphicsState];
	CGContextRef context = (CGContextRef)([[NSGraphicsContext currentContext] graphicsPort]);
	
	
	if ([[controlView window]firstResponder]==controlView && opacity==1.0){
		const float components[] = { 0.0,1.0,0.0,1.0 };
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		CGColorRef color = CGColorCreate(colorSpace, components);
		CGColorSpaceRelease(colorSpace);
		CGContextSetShadowWithColor(context, CGSizeZero, 20, color);
		CGColorRelease(color);
	}
	
	CGContextSetAlpha(context, opacity);
    CGContextBeginTransparencyLayer(context, 0);
	
	[super drawObjectImage:drawObject inRect:drawingRect cellFrame:cellFrame controlView:controlView flipped:flipped opacity:opacity];
	
	if (opacity<1.0){
		[[NSColor colorWithDeviceWhite:0.0 alpha:0.5]set];
		drawingRect.size.height/=2;
		NSRectFillUsingOperation(drawingRect,NSCompositeDestinationIn);
	}
	CGContextEndTransparencyLayer(context);
	
    [NSGraphicsContext restoreGraphicsState];
}

@end
