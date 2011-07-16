#import <Foundation/Foundation.h>

@interface QSMenuButton : NSButton {
	NSPoint menuOffset;
	BOOL drawBackground;
}
- (NSPoint) menuOffset;
- (void)setMenuOffset:(NSPoint)newMenuOffset;

- (BOOL)drawBackground;
- (void)setDrawBackground:(BOOL)flag;

// added by RCS
// This is a button event handler. The old code looked for a mouse down event on top of the button, which isn't keyboard accessible.
- (void)qsMenuButtonWasPressed;

@end
