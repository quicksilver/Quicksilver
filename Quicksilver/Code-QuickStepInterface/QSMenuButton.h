#import <Foundation/Foundation.h>

@interface QSMenuButton : NSButton {
	NSPoint menuOffset;
	BOOL drawBackground;
}
- (NSPoint) menuOffset;
- (void)setMenuOffset:(NSPoint)newMenuOffset;

- (BOOL)drawBackground;
- (void)setDrawBackground:(BOOL)flag;

@end
