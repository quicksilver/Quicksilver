//
//  NSBezierPathCappedBoxes.m
//  Filie
//
//  Created by Uli Kusterer on Fri Dec 19 2003.
//  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
//

// -----------------------------------------------------------------------------
//	Headers:
// -----------------------------------------------------------------------------

#import "NSBezierPathCappedBoxes.h"


@implementation NSBezierPath (CappedBoxes)

// -----------------------------------------------------------------------------
//	bezierPathWithCappedBoxInRect:
//		This creates a bezier path for the specified rectangle where the left
//		and right sides of the box are halves of a circle.
//	
//	REVISIONS:
//		2004-01-17  UK  Documented.
// -----------------------------------------------------------------------------

+(NSBezierPath*)	bezierPathWithCappedBoxInRect: (NSRect)rect
{
	NSBezierPath*		bp = [NSBezierPath bezierPath];
	NSPoint				lt, lb, rt, rb,		// The corners of the rect.
						ltc, lbc, rtc, rbc; // The control points of the corners.
	float				cornerSize = truncf( (rect.size.height /3) *2 );
	
	
	// Corners:
	lt = NSMakePoint(NSMinX(rect) +cornerSize, NSMaxY(rect));
	rt = NSMakePoint(NSMaxX(rect) -cornerSize, NSMaxY(rect));
	rb = NSMakePoint(NSMaxX(rect) -cornerSize, NSMinY(rect));
	lb = NSMakePoint(NSMinX(rect) +cornerSize, NSMinY(rect));
	
	// Left control points:
	ltc.y = NSMidY(rect) +truncf(rect.size.height /4); ltc.x = lt.x -cornerSize;
	lbc.y = NSMidY(rect) -truncf(rect.size.height /4); lbc.x = lb.x -cornerSize;
	
	// Right control points:
	rtc.y = NSMidY(rect) +truncf(rect.size.height /4); rtc.x = rt.x +cornerSize;
	rbc.y = NSMidY(rect) -truncf(rect.size.height /4); rbc.x = rb.x +cornerSize;
	
	// Create our capped box:
		// Top edge:
	[bp moveToPoint: lt]; 
	[bp lineToPoint: rt];
		// Right cap:
	[bp curveToPoint:rb controlPoint1:rtc controlPoint2: rbc];
		// Bottom edge:
	[bp lineToPoint: rb];
	[bp lineToPoint: lb];
		// Left cap:
	[bp curveToPoint:lt controlPoint1:lbc controlPoint2: ltc];
	
	[bp closePath]; // Just to be safe.
	
	return bp;
}

@end
