//
//  QSSplitHandleView.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 4/21/06.

//

#import "QSSplitHandleView.h"


@implementation QSSplitHandleView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}
- (void)awakeFromNib{
	[[self superview]addSubview:self positioned:NSWindowAbove relativeTo:nil];
	

}

- (void)viewDidMoveToWindow{
	if (splitView)return;
	
	NSView *grandparent=[[self superview]superview];
	if ([grandparent isKindOfClass:[NSSplitView class]]){
		
	//	QSLog(@"binding handle to splyt %@",grandparent);
		splitView=(QSHandledSplitView *)grandparent;
	}
}


- (void)drawRect:(NSRect)rect {
	[super drawRect:rect];
    // Drawing code here.
	//
	//[[NSColor blueColor] set];
	//NSRectFill(rect);
	NSRect frame=[self frame];
	NSPoint origin=NSZeroPoint;//frame.origin;
		origin.x+=NSWidth(frame)-12;
		origin.x+=0.5;
		[NSBezierPath setDefaultLineWidth:1.0];
		int i;
		for (i=0;i<3;i++){
			[[NSColor colorWithDeviceWhite:0.0 alpha:0.5]set];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(origin.x+i*3,origin.y+6)
									  toPoint:NSMakePoint(origin.x+i*3,origin.y+NSHeight(frame)-6)];
			
			[[NSColor colorWithDeviceWhite:1.0 alpha:0.5]set];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(origin.x+i*3+1,origin.y+5)
									  toPoint:NSMakePoint(origin.x+i*3+1,origin.y+NSHeight(frame)-7)];
			
		}
}

- (void)mouseDown:(NSEvent *)theEvent{
	NSPoint origPoint, curPoint;
	
	origPoint = curPoint = [theEvent locationInWindow];
	
	NSArray *subviews= [splitView subviews];
	NSRect frame0=[[subviews objectAtIndex:0]frame];
	NSRect frame1=[[subviews objectAtIndex:1]frame];
	
	
	float min=[[splitView delegate]splitView:splitView
					  constrainMinCoordinate:0
								 ofSubviewAt:0];
	
	float max=[[splitView delegate]splitView:splitView
					  constrainMaxCoordinate:NSWidth([splitView frame])-[splitView dividerThickness]
								 ofSubviewAt:0];
	
	while (1) {
        theEvent = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
        curPoint = [theEvent locationInWindow] ;
        if (NSEqualPoints(origPoint, curPoint)) {
        } else {
			[[NSNotificationCenter defaultCenter]postNotificationName:NSSplitViewWillResizeSubviewsNotification
															   object:splitView];
			float change=curPoint.x-origPoint.x;
			
	
			NSRect newFrame0=frame0;
			NSRect newFrame1=frame1;
			newFrame0.size.width+=change;
			newFrame0.size.width=MIN(MAX(newFrame0.size.width,min),max);
			 
			newFrame1.size.width=NSWidth([splitView frame])-[splitView dividerThickness]-NSWidth(newFrame0);

			[[subviews objectAtIndex:0]setFrame:newFrame0];
			[[subviews objectAtIndex:1]setFrame:newFrame1];
			[splitView adjustSubviews];
			
			[[NSNotificationCenter defaultCenter]postNotificationName:NSSplitViewDidResizeSubviewsNotification
															   object:splitView];
			
		}
		if ([theEvent type] == NSLeftMouseUp) {
			break;
		}
    }
	
}
- (void)resetCursorRects{
	NSRect rect=[self frame];
	rect.origin=NSZeroPoint;
	[self addCursorRect:rect cursor:[NSCursor resizeLeftRightCursor]];	
}
@end
