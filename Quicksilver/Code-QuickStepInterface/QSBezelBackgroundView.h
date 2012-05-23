#import <AppKit/AppKit.h>
#import <QSEffects/QSShading.h>

@interface QSBezelBackgroundView : NSView {
	NSColor *color;
	CGFloat radius;
	BOOL isGlass;
	QSGlossStyle glassStyle;
}

- (void)bindColors;

- (NSColor *)color;
- (void)setColor:(NSColor *)newColor;

- (CGFloat) radius;
- (void)setRadius:(CGFloat)newRadius;

- (BOOL)isGlass;
- (void)setIsGlass:(NSNumber *)flag;

- (QSGlossStyle) glassStyle;
- (void)setGlassStyle:(QSGlossStyle)aGlassStyle;

@end
