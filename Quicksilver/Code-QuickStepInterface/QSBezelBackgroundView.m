#import "QSBezelBackgroundView.h"
#import "NSColor_QSModifications.h"

@implementation QSBezelBackgroundView

- (void)dealloc {
	[self unbind:@"isGlass"];
}

- (void)bindColors {
	[self bind:@"isGlass" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.QSBezelIsGlass" options:nil];
}

- (id)initWithFrame:(NSRect)frame {
	if ((self = [super initWithFrame:frame])) {
		[self bindColors];
		[self setColor:[NSColor colorWithDeviceWhite:0 alpha:0.64]];
		[self setRadius:NSHeight(frame) /8];
		[self setGlassStyle:QSGlossFlat];
	}
	return self;
}

- (void)awakeFromNib { [self bindColors];  }

- (BOOL)isOpaque { return NO;  }

- (void)drawRect:(NSRect)rect {
	[color set];
	rect = [self bounds];

	NSBezierPath *roundRect = [NSBezierPath bezierPath];
	CGFloat minRadius = MIN(NSWidth(rect), NSHeight(rect) )/2;

	if (radius < 0)
		[roundRect appendBezierPathWithRoundedRectangle:rect withRadius:minRadius];
	else
		[roundRect appendBezierPathWithRoundedRectangle:rect withRadius:MIN(minRadius, radius)];

	[roundRect addClip];

	if (isGlass) {
		NSColor *highlightColor = [color colorWithLighting:0.3 plasticity:0.4];
		NSColor *shadowColor = [color colorWithLighting:-0.1];
		//[self _drawRect:rect withGradientFrom:highlightColor to:color start:NSMinYEdge];
		QSFillRectWithGradientFromEdge(rect, highlightColor, shadowColor, NSMinYEdge);

		[QSGlossClipPathForRectAndStyle(rect, glassStyle) addClip];
		CGFloat brightnessGloss = MIN(0.7, MAX(0.2, [color brightnessComponent]) );
		CGFloat desaturationGloss = MIN(0.7, MAX(0.3, 1-[color saturationComponent]) );
		CGFloat hueGloss = 0.25*MAX(0, [color greenComponent] +[color redComponent] -[color blueComponent] *0.5-1.0);
		CGFloat alpha = MIN(0.7, brightnessGloss*desaturationGloss+hueGloss);
		[[NSColor colorWithCalibratedWhite:1.0 alpha:alpha] set];
		NSRectFillUsingOperation(rect, NSCompositingOperationSourceOver);
	} else {
		[color set];
		NSRectFill(rect);
	}
	[super drawRect:rect];
}

- (NSColor *)color { return color;  }

- (void)setColor:(NSColor *)newColor {
	color = [newColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	[self setNeedsDisplay:YES];
}

- (CGFloat) radius { return radius;  }
- (void)setRadius:(CGFloat)newRadius {
	radius = newRadius;
	[self setNeedsDisplay:YES];
}

- (QSGlossStyle) glassStyle { return glassStyle;  }
- (void)setGlassStyle:(QSGlossStyle)aGlassStyle {
	glassStyle = aGlassStyle;
	[self setNeedsDisplay:YES];
}
- (BOOL)isGlass { return isGlass;  }
- (void)setIsGlass:(NSNumber *)flag {
	isGlass = [flag boolValue];
	[self setNeedsDisplay:YES];
}

@end
