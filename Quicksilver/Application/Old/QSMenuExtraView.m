

#import "QSMenuExtraView.h"


@implementation QSMenuExtraView


- initWithFrame:(NSRect)frame menuExtra:(NSMenuExtra *)extra{
 
    self = [super initWithFrame:frame menuExtra:extra];
    if (self) {
	//	[self registerForDraggedTypes:[NSArray arrayWithObject:@"NSFilenamesPboardType"]];
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
//    [[_menuExtra image] drawInRect:rect fromRect:rect operation:NSCompositeSourceOver fraction:1.0];
   // QSLog(@"%@",[_menuExtra image]);
   // logRect(rect);
	

	[[NSColor blueColor]set];
	NSRectFill(NSInsetRect(rect,-10,-10));
	
	[super drawRect:rect];
	
	// NSImage *menuImage=[NSImage imageNamed:@"QuicksilverMenuNormal"];
  //  [[statusItem statusBar] drawBackgroundInRect:rect inView:self highlight:YES]; 
// ***warning   * private method
  //  [menuImage drawAtPoint:rectOffset(rectFromSize([menuImage size]),rect,0)
//fromRect:rectFromSize([menuImage size]) operation:NSCompositeSourceOver fraction:1.0];
        
    // [statusItem setAlternateImage:[NSImage imageNamed:@"QuicksilverMenuPressed"]];
    
   
    // Drawing code here.
}
/*
- (void)mouseDown:(NSEvent *)theEvent{
     ///   [self setState:YES];
    //    theEvent=[NSEvent mouseEventWithType:NSRightMouseDown location:[self convertPoint:NSMakePoint(0,-4) toView:nil]
   //                            modifierFlags:0 timestamp:0 windowNumber:[[self window]windowNumber] context:nil eventNumber:0 clickCount:1 pressure:0];

    //[NSMenu popUpContextMenu:[delegate statusMenu] withEvent:theEvent forView: self];
    [self setState:YES];
    [delegate displayStatusMenuAtPoint:[[self window]convertBaseToScreen:[self frame].origin]];
     [self setState:NO];
    [super mouseDown:theEvent];
}
*/
//Dragging

/*
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	QSLog(@"drag");
    return [sender draggingSourceOperationMask];
}
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    [delegate readSelectionFromPasteboard:[sender draggingPasteboard]];
    return YES;
}
*/

- (id)delegate { return delegate; }

- (void)setDelegate:(id)newDelegate {
    [delegate release];
    delegate = [newDelegate retain];
    
  //  [self setStatusMenu:[[self delegate] statusMenu]];
}
@end
