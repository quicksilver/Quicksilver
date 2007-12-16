//
//  NSView_BLTRExtensions.m
//  Quicksilver
//
//  Created by Alcor on Sun Dec 21 2003.

//


#import "NSView_BLTRExtensions.h"
unsigned int flipMask(unsigned int mask,int axis){
    unsigned int newMask=0;

    
    newMask=newMask | (mask & NSViewNotSizable);
    newMask=newMask | (mask & NSViewWidthSizable);
    newMask=newMask | (mask & NSViewHeightSizable);
    
    if (axis==0){
        if (mask & NSViewMinXMargin) newMask|=NSViewMaxXMargin;
        if (mask & NSViewMaxXMargin) newMask|=NSViewMinXMargin;
        newMask=newMask | (mask & NSViewMaxYMargin);
        newMask=newMask | (mask & NSViewMinYMargin);
    }else{
        if (mask & NSViewMinYMargin) newMask|=NSViewMaxYMargin;
        if (mask & NSViewMaxYMargin) newMask|=NSViewMinYMargin;
        newMask=newMask | (mask & NSViewMaxXMargin);
        newMask=newMask | (mask & NSViewMinXMargin);  
    }
    return newMask;
}

    
@implementation NSView (Mirroring)
-(BOOL)containsEvent:(NSEvent *)event{
	return NSPointInRect([[self superview]convertPoint:[event locationInWindow] fromView:nil],[self frame]);
}


-(void)flipSubviewsOnAxis:(bool)vertical{
    NSSize parentSize=[self frame].size;
    NSEnumerator *subviewEnumerator=[[self subviews]objectEnumerator];
    NSView *thisView;
    while ((thisView=[subviewEnumerator nextObject])){
        NSRect frame=[thisView frame];
        if (vertical==0)
        [thisView setFrameOrigin:NSMakePoint(parentSize.width-NSMaxX(frame),frame.origin.y)];
        else
            [thisView setFrameOrigin:NSMakePoint(frame.origin.x,parentSize.height-NSMaxY(frame))];
        
        [thisView setAutoresizingMask:flipMask([thisView autoresizingMask],vertical)];
    }
}
@end
