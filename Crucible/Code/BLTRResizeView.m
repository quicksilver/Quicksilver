//
//  BLTRResizeView.m
//  Quicksilver
//
//  Created by Alcor on Sat Aug 30 2003.

//

#import "BLTRResizeView.h"



@implementation BLTRResizeView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {        // Initialization code here.
		 [self setAutoresizingMask:NSViewMinXMargin];
    }
    return self;
}
- (void)awakeFromNib{
    [self setAutoresizingMask:NSViewMinXMargin];
}

- (void)drawRect:(NSRect)rect {
    
    int q=oppositeQuadrant(closestCorner([self frame],[[self superview]frame]));

    NSAffineTransform* transform = [NSAffineTransform transform];
    if (q==3){
        [transform scaleXBy:-1 yBy:1];
        [transform translateXBy:-16 yBy:0];
    }
    [transform concat];
    
    [[[NSBundle bundleForClass:[self class]] imageNamed:@"ResizeWidget"]drawInRect:rect fromRect:rect operation:NSCompositeSourceOver fraction:1.0];
}


- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent{return YES;}
- (BOOL)mouseDownCanMoveWindow{return NO;}

- (void)mouseDown:(NSEvent *)theEvent{
    mouseDownPoint=[[self window]convertBaseToScreen:[theEvent locationInWindow]];   
    oldFrame=[[self window] frame];
    
    quadrant=oppositeQuadrant(closestCorner([self frame],[[self superview]frame]));
}
/*
- (void)mouseDragged:(NSEvent *)theEvent{
    NSPoint mouseDraggedPoint=[[self window]convertBaseToScreen:[theEvent locationInWindow]];   
    NSPoint offset={mouseDraggedPoint.x-mouseDownPoint.x,mouseDraggedPoint.y-mouseDownPoint.y};
 
    NSRect newFrame=oldFrame;    
    NSSize minSize=[[self window]minSize];
    
    newFrame.size.width=MAX(minSize.width,newFrame.size.width+offset.x);
    newFrame.size.height=MAX(minSize.height,newFrame.size.height-offset.y);
    newFrame=[[self window]constrainFrameRect:newFrame toScreen:[[self window]screen]];
    newFrame.origin.y+=oldFrame.size.height-newFrame.size.height;
    [[self window]setFrame:newFrame display:YES];
    
    //[[self window] setContentSize:newSize];
    //[[self window] setFrameTopLeftPoint:NSMakePoint(NSMinX(oldFrame),NSMaxY(oldFrame))];
    //mouseDownPoint=NSMakePoint(newMouseDownPoint.x,mouseDownPoint.y);
}
*/

- (void)mouseDragged:(NSEvent *)event {
    NSPoint eventLocation = [[self window]convertBaseToScreen:[event locationInWindow]];

    NSPoint eventOffset = NSMakePoint( eventLocation.x-mouseDownPoint.x,eventLocation.y-mouseDownPoint.y);

   // lastMousePoint=eventLocation;
   // lastMouseTime=[NSDate timeIntervalSinceReferenceDate];
    
    NSRect newFrame=oldFrame;
    NSPoint frameOffset=NSZeroPoint;
 
    int xMod = (quadrant == 3 || quadrant == 2) ? -1 : 1;
    int yMod = (quadrant == 4 || quadrant == 3) ? -1 : 1;
    NSPoint sizeOffset=NSMakePoint(xMod*eventOffset.x,yMod*eventOffset.y);
    newFrame.size.width=MAX([[self window]minSize].width,NSWidth(oldFrame)+sizeOffset.x);
    newFrame.size.height=MAX([[self window]minSize].height,NSHeight(oldFrame)+sizeOffset.y);
    frameOffset=rectOffset(newFrame,oldFrame,quadrant);
    
    newFrame=NSOffsetRect(newFrame,frameOffset.x,frameOffset.y);
    [[self window] setFrame:newFrame  display:YES animate:NO];    
}

@end
