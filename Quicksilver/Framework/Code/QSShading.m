/*
 *  QSShading.c
 *  Quicksilver
 *
 *  Created by Alcor on 10/17/04.
 *  Copyright 2004 Blacktree. All rights reserved.
 *
 */

#import "QSShading.h"
/*
struct QSGradient{
	int countil	
	
}

struct QSGradientPoint{
	float position;
	float r;
	float g;
	float b;
	float a;
}
*/


void QSColorFade(void *info, const float *in, float *out){
	float v=*in;
	float *colors=info;
	int i;
	for (i=0;i<4;i++)
		*out++ = colors[i]*(1-v)+colors[i+4]*(v);
	
}
void QSFillRectWithGradientFromEdge(NSRect rect,NSColor *start,NSColor *end,NSRectEdge startEdge){
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	start=[start colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	end=[end colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	size_t components;
	static const float domain[2] = { 0, 1 };
	static const float range[10] = { 0, 1, 0, 1, 0, 1, 0, 1, 0, 1 };
	static const CGFunctionCallbacks callbacks = { 0, &QSColorFade, NULL };
	
	
	float colors[8]={
		[start redComponent],[start greenComponent],[start blueComponent],[start alphaComponent],
		[end redComponent],[end greenComponent],[end blueComponent],[end alphaComponent]};
	
	
	components = 1 + CGColorSpaceGetNumberOfComponents(colorspace);
	CGFunctionRef function=CGFunctionCreate(colors, 1, domain, components,range, &callbacks);
	
	CGPoint startPoint,endPoint;
	
	switch (startEdge){
		case NSMaxYEdge: startPoint=CGPointMake(0,NSMaxY(rect));endPoint=CGPointMake(0,NSMinY(rect));break;		
		case NSMinYEdge: startPoint=CGPointMake(0,NSMinY(rect));endPoint=CGPointMake(0,NSMaxY(rect));break;		
		case NSMaxXEdge: startPoint=CGPointMake(NSMaxX(rect),0);endPoint=CGPointMake(NSMinX(rect),0);break;		
		case NSMinXEdge: startPoint=CGPointMake(NSMinX(rect),0);endPoint=CGPointMake(NSMaxX(rect),0);break;
	}
	
	
	CGShadingRef shading=CGShadingCreateAxial(colorspace, startPoint,endPoint,function, NO, NO);
	
	CGContextRef currentContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextDrawShading(currentContext, shading);
	CGFunctionRelease(function);
	CGShadingRelease(shading);
	CGColorSpaceRelease(colorspace);
}






NSBezierPath *QSGlossClipPathForRectAndStyle(NSRect rect,QSGlossStyle style){
	
	NSBezierPath *gloss=[NSBezierPath bezierPath];
	
	switch (style){
		case QSGlossUpArc:
			[gloss appendBezierPathWithRect:rect];
			[gloss setWindingRule:NSEvenOddWindingRule];
			[gloss appendBezierPathWithOvalInRect:NSInsetRect(NSOffsetRect(rect,0,-NSHeight(rect)/2),-NSWidth(rect)/3,-NSHeight(rect)/6)];
			break;
		case QSGlossRisingArc:
			[gloss appendBezierPathWithRect:rect];
			[gloss setWindingRule:NSEvenOddWindingRule];
			[gloss appendBezierPathWithOvalInRect:NSInsetRect(NSOffsetRect(rect,NSWidth(rect)/3,-NSHeight(rect)/2),-NSWidth(rect)/2,-NSHeight(rect)/4)];
			break;
		case QSGlossDownArc:
			[gloss appendBezierPathWithOvalInRect:NSInsetRect(NSOffsetRect(rect,0,NSHeight(rect)*2/3),-NSWidth(rect)/3,-NSHeight(rect)/6)];
			break;
		case QSGlossControl:
			[gloss setWindingRule:NSNonZeroWindingRule];
			
			float radius=NSHeight(rect)/2;
			[gloss appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect)+radius,NSMinY(rect))
											  radius:radius
										  startAngle:180.0
											endAngle:90.0
										   clockwise:YES];
			
			[gloss appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect)-radius,NSMaxY(rect))
											  radius:radius
										  startAngle:270.0
											endAngle:0.0
										   clockwise:NO];
			
			[gloss lineToPoint:NSMakePoint(NSMaxX(rect),NSMaxY(rect))];
			[gloss lineToPoint:NSMakePoint(NSMinX(rect),NSMaxY(rect))];
			[gloss lineToPoint:NSMakePoint(NSMinX(rect),NSMinY(rect))];
			
			[gloss closePath];
			
			break;
		case QSGlossFlat:
			rect.origin.y+=(int)(NSHeight(rect)/2);
			//rect.size.height/=2;
			[gloss appendBezierPathWithRect:rect];
			break;
		default:
			return nil;
	}
	return gloss;
}

