#import <AppKit/AppKit.h>

@interface QSBackgroundView : NSView {
//	NSButtonCell *background;
	NSColor *backgroundColor;
	CGFloat depth;
}
- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)aBackgroundColor;
- (CGFloat)depth;
- (void)setDepth:(CGFloat)aDepth;

- (void)bindColors;
@end
