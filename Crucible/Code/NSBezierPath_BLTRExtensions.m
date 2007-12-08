//
//  NSString_CompletionExtensions.m
//  Quicksilver
//
//  Created by Alcor on Mon Mar 03 2003.

//

#import "NSBezierPath_BLTRExtensions.h"
#import <math.h>

@implementation NSBezierPath(RoundRect)
- (void) appendBezierPathWithRoundedRectangle:(NSRect)aRect
                                   withRadius:(float) radius
{
    NSPoint topMid = NSMakePoint(NSMidX(aRect), NSMaxY(aRect));
    NSPoint topLeft = NSMakePoint(NSMinX(aRect), NSMaxY(aRect));
    NSPoint topRight = NSMakePoint(NSMaxX(aRect), NSMaxY(aRect));
    NSPoint bottomRight = NSMakePoint(NSMaxX(aRect), NSMinY(aRect));

    [self moveToPoint:topMid];
    [self appendBezierPathWithArcFromPoint:topLeft toPoint:aRect.origin
                                    radius:radius];
    [self appendBezierPathWithArcFromPoint:aRect.origin
                                   toPoint:bottomRight radius:radius];
    [self appendBezierPathWithArcFromPoint:bottomRight toPoint:topRight
                                    radius:radius];
    [self appendBezierPathWithArcFromPoint:topRight toPoint:topLeft
                                    radius:radius];
    [self closePath];
}





- (void) appendBezierPathWithRoundedRectangle:(NSRect)aRect
                                   withRadius:(float) radius
                                   indent:(int)indent
{
    
    NSPoint topMid = NSMakePoint(NSMidX(aRect), NSMaxY(aRect));
    NSPoint topLeft = NSMakePoint(NSMinX(aRect), NSMaxY(aRect));
    NSPoint topRight = NSMakePoint(NSMaxX(aRect), NSMaxY(aRect));
    NSPoint bottomRight = NSMakePoint(NSMaxX(aRect), NSMinY(aRect));
    
    [self moveToPoint:topMid];
 //   QSLog(@"%d",indent);

    if(indent>0){
        [self appendBezierPathWithArcWithCenter: NSMakePoint(topLeft.x-radius/sqrt(3.0),topLeft.y-radius) radius:2*radius/sqrt(3.0) startAngle:60 endAngle:0 clockwise: YES];
        [self appendBezierPathWithArcWithCenter: NSMakePoint(aRect.origin.x-radius/sqrt(3.0),aRect.origin.y+radius) radius:2*radius/sqrt(3.0) startAngle:0 endAngle: -60 clockwise: YES];
    }else{
        [self appendBezierPathWithArcFromPoint:topLeft toPoint:aRect.origin  radius:radius];
        [self appendBezierPathWithArcFromPoint:aRect.origin toPoint:bottomRight radius:radius];
    }
    
    if(indent>1){
        [self appendBezierPathWithArcWithCenter: NSMakePoint(bottomRight.x+radius/sqrt(3.0),bottomRight.y+radius) radius:2*radius/sqrt(3.0) startAngle:-90-30 endAngle: -180 clockwise: YES];   
        [self appendBezierPathWithArcWithCenter: NSMakePoint(topRight.x+radius/sqrt(3.0),topRight.y-radius) radius:2*radius/sqrt(3.0) startAngle:-180 endAngle:90+30 clockwise: YES];
    }else{
        [self appendBezierPathWithArcFromPoint:bottomRight toPoint:topRight radius:radius];
        [self appendBezierPathWithArcFromPoint:topRight toPoint:topLeft radius:radius];        
    }
    
    
    [self closePath];
}

@end