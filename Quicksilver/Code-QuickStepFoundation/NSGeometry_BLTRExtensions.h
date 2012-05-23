//
//  NSGeometry_Extensions.h
//
//
//  Created by Alcor on Thu Nov 28 2002.
//  Copyright (c) 2002 Blacktree, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef struct _BTFloatRange {
	CGFloat value;
	CGFloat location;
	CGFloat length;
} BTFloatRange;


BTFloatRange BTMakeFloatRange(CGFloat value, CGFloat location, CGFloat length);
CGFloat BTFloatRangeMod(BTFloatRange range);
CGFloat BTFloatRangeUnit(BTFloatRange range);
NSPoint rectOffset(NSRect innerRect, NSRect outerRect, NSInteger quadrant);


NSRect rectZoom(NSRect rect, CGFloat zoom, NSInteger quadrant);

NSRect sizeRectInRect(NSRect innerRect, NSRect outerRect, bool expand);
NSPoint offsetPoint(NSPoint fromPoint, NSPoint toPoint);
NSRect fitRectInRect(NSRect innerRect, NSRect outerRect, bool expand);
NSRect centerRectInRect(NSRect rect, NSRect mainRect);
NSRect rectFromSize(NSSize size);
NSRect rectWithProportion(NSRect innerRect, CGFloat proportion, bool expand);

NSRect constrainRectToRect(NSRect innerRect, NSRect outerRect);
NSRect alignRectInRect(NSRect innerRect, NSRect outerRect, NSInteger quadrant);
NSRect expelRectFromRect(NSRect innerRect, NSRect outerRect, CGFloat peek);
NSRect expelRectFromRectOnEdge(NSRect innerRect, NSRect outerRect, NSRectEdge edge, CGFloat peek);

	NSRectEdge touchingEdgeForRectInRect(NSRect innerRect, NSRect outerRect);
NSInteger closestCorner(NSRect innerRect, NSRect outerRect);
NSInteger oppositeQuadrant(NSInteger quadrant);

NSRect blendRects(NSRect start, NSRect end, CGFloat b);
void logRect(NSRect rect);
