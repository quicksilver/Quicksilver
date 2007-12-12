#import "QSMenuButton.h"

@implementation QSMenuButton

- (void)mouseDown:(NSEvent *)theEvent {
	[[self cell] setHighlighted:YES];
	[NSMenu popUpContextMenu:[self menu] withEvent:[NSEvent mouseEventWithType:NSRightMouseDown location:[self convertPoint:NSMakePoint(menuOffset.x, menuOffset.y+NSHeight([self frame]) +4) toView:nil] modifierFlags:0 timestamp:0 windowNumber:[[self window] windowNumber] context:nil eventNumber:0 clickCount:1 pressure:0] forView: self];
	[[self cell] setHighlighted:NO];
}
- (void)drawRect:(NSRect)rect {
	if ([self state] && drawBackground) {
		[[NSColor selectedMenuItemColor] set];
		NSRectFill([self bounds]);
	}
	[super drawRect:rect];
}
- (BOOL)mouseDownCanMoveWindow {
	return NO;
}
- (BOOL)acceptsFirstResponder {
	return NO;
}
- (NSPoint)menuOffset { return menuOffset; }
- (void)setMenuOffset:(NSPoint)newMenuOffset {
	menuOffset = newMenuOffset;
}
- (BOOL)drawBackground { return drawBackground; }
- (void)setDrawBackground:(BOOL)flag {
	drawBackground = flag;
}

@end
