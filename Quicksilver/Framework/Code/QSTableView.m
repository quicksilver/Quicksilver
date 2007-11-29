

#import "QSTableView.h"

#import "NSColor_QSModifications.h"


@interface NSTableView (SingleRowDisplay)
- (void)_setNeedsDisplayInRow:(int)fp8;
@end 


@implementation QSTableView
//- (void)awakeFromNib{
//    //[self setHeaderView:[[[ABPropertyHeaderView alloc]initWithFrame:[[self headerView]frame]]autorelease]];
//}
//

- (BOOL)canDragRowsWithIndexes:(NSIndexSet *)rowIndexes atPoint:(NSPoint)mouseDownPoint{
	return YES;	
}
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender{
	[draggingDelegate draggingEntered:sender];
	return [super draggingEntered:sender];
}
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender{
	[draggingDelegate draggingUpdated:sender];
	return [super draggingUpdated:sender];
}
- (void)draggingExited:(id <NSDraggingInfo>)sender{
	[draggingDelegate draggingExited:sender];
	[super draggingExited:sender];
	return;
}


- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
	//QSLog(@"source");
    if (isLocal) return NSDragOperationEvery;
    else return NSDragOperationEvery;
}
- (BOOL)isOpaque{
	return opaque;
}
- (void)setOpaque:(BOOL)flag{
	opaque=flag;
}
- (void)drawRow:(int)rowIndex clipRect:(NSRect)clipRect{
	//  drawingRow=rowIndex;
    
    if ([[self delegate] respondsToSelector:@selector(tableView:rowIsSeparator:)]
        && [[self delegate]tableView:self rowIsSeparator:rowIndex]){
		
		if (![[self delegate] respondsToSelector:@selector(tableView:shouldDrawRow:inClipRect:)]
			|| [[self delegate]tableView:self shouldDrawRow:rowIndex inClipRect:clipRect]){
			[self drawSeparatorForRow:rowIndex clipRect:clipRect];
		}
	}else{
		[super drawRow:rowIndex clipRect:clipRect];
	}
}


- (id) initWithFrame:(NSRect)rect {
	self = [super initWithFrame:rect];
	if (self != nil) {
		opaque=YES;
		drawsBackground=YES;
	}
	return self;
}
- (void)awakeFromNib{
	
	opaque=YES;
	drawsBackground=YES;
}
- (void)drawBackgroundInClipRect:(NSRect)clipRect{
	if (!drawsBackground){
		return;
	}else if ([self backgroundColor]){
		[[self backgroundColor]set];
		NSRectFillUsingOperation(clipRect,NSCompositeCopy);
	} else {
		[super drawBackgroundInClipRect:clipRect];
	}
	
}

- (BOOL)drawsBackground {
    return drawsBackground;
}

- (void)setDrawsBackground:(BOOL)value {
    if (drawsBackground != value) {
        drawsBackground = value;
    }
}



- (void)setHighlightColorForBackgroundColor:(NSColor *)color{
	[self setHighlightColor:[[self backgroundColor]blendedColorWithFraction:0.25 ofColor:[[self backgroundColor]readableTextColor]]];
}

- (id)_highlightColorForCell:(NSCell *)cell{
	if (highlightColor)
		return highlightColor;
	//return [super _highlightColorForCell:(NSCell *)cell];
	return [NSColor alternateSelectedControlColor];
}
- (NSColor *)highlightColor { return [[highlightColor retain] autorelease]; }

- (void)setHighlightColor:(NSColor *)aHighlightColor
{
    if (highlightColor != aHighlightColor) {
        [highlightColor release];
        highlightColor = [aHighlightColor copy];
		
		[self setNeedsDisplay:YES];
    }
}

- (void)setBackgroundColor:(NSColor *)color{
	[super setBackgroundColor:color];
	[self setNeedsDisplay:YES];
}


- (void)redisplayRows:(NSIndexSet *)indexes{
    if ([self respondsToSelector:@selector(_setNeedsDisplayInRow:)])
        [self _setNeedsDisplayInRow:[indexes firstIndex]]; 
	// ***warning   * incomplete
    else [self setNeedsDisplay:YES];
}
-(NSMenu*)menuForEvent:(NSEvent*)evt { 
	//  QSLog (@"event");
    NSPoint point = [self convertPoint:[evt locationInWindow] fromView:NULL]; 
    int column = [self columnAtPoint:point]; 
    int row = [self rowAtPoint:point]; 
    if ( column >= 0 && row >= 0 && [[self delegate] respondsToSelector:@selector(tableView:menuForTableColumn:row:)] ) 
        return [[self delegate] tableView:self menuForTableColumn:[[self tableColumns] objectAtIndex:column] row:row]; 
    return [super menuForEvent:evt]; 
} 

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation{
    [super draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation]; 
	
    if ([[self dataSource] respondsToSelector:@selector(tableView:dropEndedWithOperation:)] ) 
        [[self dataSource] tableView:self dropEndedWithOperation:operation]; 
}


- (id)draggingDelegate { return [[draggingDelegate retain] autorelease]; }

- (void)setDraggingDelegate:(id)aDraggingDelegate{
    if (draggingDelegate != aDraggingDelegate) {
        [draggingDelegate release];
        draggingDelegate = [aDraggingDelegate retain];
    }
}


@end

@implementation NSTableView (MenuExtensions) 

-(NSMenu*)menuForEvent:(NSEvent*)evt { 
    NSPoint point = [self convertPoint:[evt locationInWindow] fromView:NULL]; 
    int column = [self columnAtPoint:point]; 
    int row = [self rowAtPoint:point]; 
    if ( column >= 0 && row >= 0 && [[self delegate] respondsToSelector:@selector(tableView:menuForTableColumn:row:)] ) 
        return [[self delegate] tableView:self menuForTableColumn:[[self tableColumns] objectAtIndex:column] row:row]; 
    return [super menuForEvent:evt]; 
} 
@end 
