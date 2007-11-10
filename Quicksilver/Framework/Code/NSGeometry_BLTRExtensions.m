//
//  NSGeometry_Extensions.m
//  1.0
//
//  Created by Alcor on Thu Nov 28 2002.

//

#import "NSGeometry_BLTRExtensions.h"
#import "math.h"

BTFloatRange BTMakeFloatRange(float value,float location,float length){
    BTFloatRange fRange;
    fRange.value=value;
    fRange.location=location;
    fRange.length=length;
    return fRange;
}
float BTFloatRangeMod(BTFloatRange range){
    return fmod(range.value-range.location,range.length)+range.location;
}

float BTFloatRangeUnit(BTFloatRange range){
    return (range.value-range.location)/range.length;
}

NSPoint offsetPoint(NSPoint fromPoint, NSPoint toPoint){
    return NSMakePoint(toPoint.x-fromPoint.x,toPoint.y-fromPoint.y);
}

int oppositeQuadrant(int quadrant){
    quadrant=quadrant+2;
    quadrant%=4;
    if (!quadrant)quadrant=4;
    return quadrant;
}

NSPoint rectOffset(NSRect innerRect,NSRect outerRect,int quadrant){
    if (quadrant)
        return NSMakePoint((quadrant == 3 || quadrant == 2) ? NSMaxX(outerRect)-NSMaxX(innerRect) : NSMinX(outerRect)-NSMinX(innerRect),
                           (quadrant == 4 || quadrant == 3) ? NSMaxY(outerRect)-NSMaxY(innerRect) : NSMinY(outerRect)-NSMinY(innerRect));
    return NSMakePoint(NSMidX(outerRect)-NSMidX(innerRect),NSMidY(outerRect)-NSMidY(innerRect)); //Center Rects
}

NSRect alignRectInRect(NSRect innerRect,NSRect outerRect,int quadrant){
    NSPoint offset=rectOffset(innerRect,outerRect,quadrant);
    return NSOffsetRect(innerRect,offset.x,offset.y);
}




NSRect rectZoom(NSRect rect,float zoom,int quadrant){
    NSSize newSize=NSMakeSize(NSWidth(rect)*zoom,NSHeight(rect)*zoom);
    NSRect newRect=rect;
    newRect.size=newSize;
    return newRect;
}


NSRect sizeRectInRect(NSRect innerRect,NSRect outerRect,bool expand){
    float proportion=NSWidth(innerRect)/NSHeight(innerRect);
    NSRect xRect=NSMakeRect(0,0,outerRect.size.width,outerRect.size.width/proportion);
    NSRect yRect=NSMakeRect(0,0,outerRect.size.height*proportion,outerRect.size.height);
    NSRect newRect;
    if (expand) newRect = NSUnionRect(xRect,yRect);
    else newRect = NSIntersectionRect(xRect,yRect);
    return newRect;
}

NSRect fitRectInRect(NSRect innerRect,NSRect outerRect,bool expand){
    return centerRectInRect(sizeRectInRect(innerRect,outerRect,expand),outerRect);
}

NSRect rectWithProportion(NSRect innerRect,float proportion,bool expand){
    NSRect xRect=NSMakeRect(0,0,innerRect.size.width,innerRect.size.width/proportion);
    NSRect yRect=NSMakeRect(0,0,innerRect.size.height*proportion,innerRect.size.height);
    NSRect newRect;
    if (expand) newRect = NSUnionRect(xRect,yRect);
    else newRect = NSIntersectionRect(xRect,yRect);
    return newRect;
}

NSRect centerRectInRect(NSRect rect, NSRect mainRect){
    return NSOffsetRect(rect,NSMidX(mainRect)-NSMidX(rect),NSMidY(mainRect)-NSMidY(rect));
}

NSRect constrainRectToRect(NSRect innerRect, NSRect outerRect){
    NSPoint offset=NSZeroPoint;
    if (NSMaxX(innerRect) > NSMaxX(outerRect))
        offset.x+= NSMaxX(outerRect) - NSMaxX(innerRect);
    if (NSMaxY(innerRect) > NSMaxY(outerRect))
        offset.y+= NSMaxY(outerRect) - NSMaxY(innerRect);
    if (NSMinX(innerRect) < NSMinX(outerRect))
        offset.x+= NSMinX(outerRect) - NSMinX(innerRect);
    if (NSMinY(innerRect) < NSMinY(outerRect))
        offset.y+= NSMinY(outerRect) - NSMinY(innerRect);
    return NSOffsetRect(innerRect,offset.x,offset.y);
}

NSRect expelRectFromRect(NSRect innerRect, NSRect outerRect,float peek){
    NSPoint offset=NSZeroPoint;
    
    float leftDistance=NSMaxX(innerRect) - NSMinX(outerRect);
    float rightDistance=NSMaxX(outerRect)-NSMinX(innerRect);
    float topDistance=NSMaxY(outerRect)-NSMinY(innerRect);
    float bottomDistance=NSMaxY(innerRect) - NSMinY(outerRect);
    float minDistance=MIN(MIN(MIN(leftDistance,rightDistance),topDistance),bottomDistance);
    
    if (minDistance==leftDistance)
        offset.x-=leftDistance-peek;
    else if (minDistance==rightDistance)
        offset.x+=rightDistance-peek;
    else if (minDistance==topDistance)
        offset.y+=topDistance-peek;
    else if (minDistance==bottomDistance)
        offset.y-=bottomDistance-peek;
    
    return NSOffsetRect(innerRect,offset.x,offset.y);
}

NSRect expelRectFromRectOnEdge(NSRect innerRect, NSRect outerRect,NSRectEdge edge,float peek){
    NSPoint offset=NSZeroPoint;
    
    switch(edge){
        case NSMaxXEdge:
            
            offset.x+=NSMaxX(outerRect)-NSMinX(innerRect)-peek;
            break;
        case NSMinXEdge:
            offset.x-=NSMaxX(innerRect) - NSMinX(outerRect) - peek;
            break;
        case NSMaxYEdge:
            offset.y+=NSMaxY(outerRect)-NSMinY(innerRect)-peek;
            break;
        case NSMinYEdge:
            offset.y-=NSMaxY(innerRect) - NSMinY(outerRect)-peek;
            break;
    }

    return NSOffsetRect(innerRect,offset.x,offset.y);
}
NSRectEdge touchingEdgeForRectInRect(NSRect innerRect, NSRect outerRect){
    
    if (NSMaxX(innerRect)>=NSMaxX(outerRect)) return NSMaxXEdge;
    else if (NSMinX(innerRect)<=NSMinX(outerRect)) return NSMinXEdge;
    else if (NSMaxY(innerRect)>=NSMaxY(outerRect)) return NSMaxYEdge;
    else if (NSMinY(innerRect)<=NSMinY(outerRect)) return NSMinYEdge;
    return -1;
}



NSRect rectFromSize(NSSize size){
    return NSMakeRect(0,0,size.width,size.height);
}

float distanceFromOrigin(NSPoint point){
    return hypot(point.x, point.y);
}
int closestCorner(NSRect innerRect,NSRect outerRect){
    float bestDistance=-1;
    int closestCorner=0;
    int i;
    for(i=0;i<5;i++){
        float distance = distanceFromOrigin(rectOffset(innerRect,outerRect,i));
        if (distance < bestDistance || bestDistance<0){
            bestDistance=distance;
            closestCorner=i;
        }
    }
    return closestCorner;
}





NSRect blendRects(NSRect start, NSRect end,float b){
    
    return NSMakeRect(  round(NSMinX(start)*(1-b) + NSMinX(end)*b),
                        round(NSMinY(start)*(1-b) + NSMinY(end)*b),
                        round(NSWidth(start)*(1-b) + NSWidth(end)*b),
                        round(NSHeight(start)*(1-b) + NSHeight(end)*b));
}

void logRect(NSRect rect){
//QSLog(@"(%f,%f) (%fx%f)",rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
}
