
#import <QSFoundation/NSTableView_BLTRExtensions.h>

#import "QSTableView.h"

#import "NSColor_QSModifications.h"

@implementation QSTableView

//- (void)awakeFromNib {
//	//[self setHeaderView:[[[ABPropertyHeaderView alloc] initWithFrame:[[self headerView] frame]]autorelease]];
//}
//

- (id <QSTableViewDelegate>)delegate {
    return (id <QSTableViewDelegate>)[super delegate];
}

- (id <QSTableViewDataSource>)dataSource {
    return (id <QSTableViewDataSource>)[super dataSource];
}

- (BOOL)canDragRowsWithIndexes:(NSIndexSet *)rowIndexes atPoint:(NSPoint)mouseDownPoint {
	return YES;
}
- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender {
	[draggingDelegate draggingEntered:sender];
	return [super draggingEntered:sender];
}
- (NSDragOperation) draggingUpdated:(id <NSDraggingInfo>)sender {
	[draggingDelegate draggingUpdated:sender];
	return [super draggingUpdated:sender];
}
- (void)draggingExited:(id <NSDraggingInfo>)sender {
	[draggingDelegate draggingExited:sender];
	[super draggingExited:sender];
	return;
}


- (NSDragOperation) draggingSourceOperationMaskForLocal:(BOOL)isLocal {
	//NSLog(@"source");
	if (isLocal) return NSDragOperationEvery;
	else return NSDragOperationEvery;
}

- (BOOL)isOpaque {
	return opaque;
}

- (void)setOpaque:(BOOL)flag {
	opaque = flag;
}
- (void)drawRow:(NSInteger)rowIndex clipRect:(NSRect)clipRect {
	// drawingRow = rowIndex;
	if (![[self window] isVisible]) {
		return;
	}
	if (self.hasSeparators && [[self delegate] respondsToSelector:@selector(tableView:rowIsSeparator:)]
		 && [[self delegate] tableView:self rowIsSeparator:rowIndex]) {

		if (![[self delegate] respondsToSelector:@selector(tableView:shouldDrawRow:inClipRect:)]
			 || [[self delegate] tableView:self shouldDrawRow:rowIndex inClipRect:clipRect]) {
			[self drawSeparatorForRow:rowIndex clipRect:clipRect];
		}
	} else {
		[super drawRow:rowIndex clipRect:clipRect];
	}
}


- (id)initWithFrame:(NSRect) rect {
	self = [super initWithFrame:rect];
	if (self != nil) {
		opaque = YES;
		drawsBackground = YES;
		_hasSeparators = YES;
	}
	return self;
}
- (void)awakeFromNib {
	opaque = YES;
	drawsBackground = YES;
}

- (void)drawBackgroundInClipRect:(NSRect)clipRect {
	if (drawsBackground) {
		if ([self backgroundColor]) {
			[[self backgroundColor] set];
			NSRectFillUsingOperation(clipRect, NSCompositingOperationCopy);
		} else {
			[super drawBackgroundInClipRect:clipRect];
		}
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



- (void)setHighlightColorForBackgroundColor:(NSColor *)color {
	[self setHighlightColor:[[self backgroundColor] blendedColorWithFraction:0.25 ofColor:[[self backgroundColor] readableTextColor]]];
}

- (id)_highlightColorForCell:(NSCell *)cell {
	if (highlightColor)
		return highlightColor;
	//return [super _highlightColorForCell:(NSCell *)cell];
	return [NSColor alternateSelectedControlColor];
}
- (NSColor *)highlightColor { return highlightColor;  }
- (void)setHighlightColor:(NSColor *)aHighlightColor {
	if (highlightColor != aHighlightColor) {
		highlightColor = [aHighlightColor copy];
		[self setNeedsDisplay:YES];
	}
}

- (void)setBackgroundColor:(NSColor *)color {
	[super setBackgroundColor:color];
	[self setNeedsDisplay:YES];
}


- (void)redisplayRows:(NSIndexSet *)indexes {
     [self setNeedsDisplay:YES];
}

- (NSMenu*)menuForEvent:(NSEvent*)evt {
	// NSLog (@"event");
	NSPoint point = [self convertPoint:[evt locationInWindow] fromView:NULL];
	NSInteger column = [self columnAtPoint:point];
	NSInteger row = [self rowAtPoint:point];
	if ( column >= 0 && row >= 0 && [[self delegate] respondsToSelector:@selector(tableView:menuForTableColumn:row:)] )
		return [[self delegate] tableView:self menuForTableColumn:[[self tableColumns] objectAtIndex:column] row:row];
	return [super menuForEvent:evt];
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation {
	[super draggedImage:anImage endedAt:aPoint operation:operation];

	if ([[self dataSource] respondsToSelector:@selector(tableView:dropEndedWithOperation:)] )
		[[self dataSource] tableView:self dropEndedWithOperation:operation];
}


- (id)draggingDelegate { return draggingDelegate;  }
- (void)setDraggingDelegate:(id)aDraggingDelegate {
	if (draggingDelegate != aDraggingDelegate) {
		draggingDelegate = aDraggingDelegate;
	}
}

@end

@implementation NSTableView (MenuExtensions)

- (NSMenu*)menuForEvent:(NSEvent*)evt {
	NSPoint point = [self convertPoint:[evt locationInWindow] fromView:NULL];
	NSInteger column = [self columnAtPoint:point];
	NSInteger row = [self rowAtPoint:point];
	if ( column >= 0 && row >= 0 && [[self delegate] respondsToSelector:@selector(tableView:menuForTableColumn:row:)] )
		return [(id <QSTableViewDelegate>)[self delegate] tableView:(QSTableView *)self menuForTableColumn:[[self tableColumns] objectAtIndex:column] row:row];
	return [super menuForEvent:evt];
}
@end
