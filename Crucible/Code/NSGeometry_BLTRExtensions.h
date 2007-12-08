//
//  NSGeometry_Extensions.h
//  
//
//  Created by Alcor on Thu Nov 28 2002.

//

#import <Foundation/Foundation.h>


typedef struct _BTFloatRange {
    float value;
    float location;
    float length;
} BTFloatRange;


BTFloatRange BTMakeFloatRange(float value,float location,float length);
float BTFloatRangeMod(BTFloatRange range);
float BTFloatRangeUnit(BTFloatRange range);
NSPoint rectOffset(NSRect innerRect,NSRect outerRect,int quadrant);


NSRect rectZoom(NSRect rect,float zoom,int quadrant);

NSRect sizeRectInRect(NSRect innerRect,NSRect outerRect,bool expand);
NSPoint offsetPoint(NSPoint fromPoint, NSPoint toPoint);
NSRect fitRectInRect(NSRect innerRect,NSRect outerRect,bool expand);
NSRect centerRectInRect(NSRect rect, NSRect mainRect);
NSRect rectFromSize(NSSize size);
NSRect rectWithProportion(NSRect innerRect,float proportion,bool expand);

NSRect constrainRectToRect(NSRect innerRect, NSRect outerRect);
NSRect alignRectInRect(NSRect innerRect,NSRect outerRect,int quadrant);
NSRect expelRectFromRect(NSRect innerRect, NSRect outerRect,float peek);
NSRect expelRectFromRectOnEdge(NSRect innerRect, NSRect outerRect,NSRectEdge edge,float peek);
    
    NSRectEdge touchingEdgeForRectInRect(NSRect innerRect, NSRect outerRect);
int closestCorner(NSRect innerRect,NSRect outerRect);
int oppositeQuadrant(int quadrant);

NSRect blendRects(NSRect start, NSRect end,float b);
void logRect(NSRect rect);