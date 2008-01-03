

//#import <AppKit/AppKit.h>
#import "QSShading.h"

@interface QSBezelBackgroundView : NSView {
    NSColor *color;
    float radius;
	BOOL isGlass;
	QSGlossStyle glassStyle;
}

- (NSColor *)color;
- (void)setColor:(NSColor *)newColor;

- (float)radius;
- (void)setRadius:(float)newRadius;

- (BOOL)isGlass;
- (void)setIsGlass:(NSNumber *)flag;

- (QSGlossStyle)glassStyle;
- (void)setGlassStyle:(QSGlossStyle)aGlassStyle;

- (void)bindColors;
@end