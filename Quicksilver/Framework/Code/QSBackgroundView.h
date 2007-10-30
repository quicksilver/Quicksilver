

#import <AppKit/AppKit.h>


@interface QSBackgroundView : NSView {
    NSButtonCell *background;
	NSColor *backgroundColor;
	float depth;
}
- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)aBackgroundColor;
- (float)depth;
- (void)setDepth:(float)aDepth;

- (void)bindColors;
@end
