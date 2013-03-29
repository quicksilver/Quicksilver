#import "QSBackgroundView.h"
#import "NSColor_QSModifications.h"
#import "QSShading.h"

@implementation QSBackgroundView
- (id)initWithFrame:(NSRect)frame {
	if (self = [super initWithFrame:frame]) {
		[self bindColors];
		depth = 1.0;
	}
	return self;
}
- (void)bindColors {
	if (self == [[self window] contentView] && !NSEqualRects([[[self window] contentView] frame] , [[[[self window] contentView] superview] frame])) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"QSEnableThemeSupport"]) {
			[self setBackgroundColor:[[[[NSColor windowBackgroundColor] colorUsingColorSpaceName:NSPatternColorSpace] patternImage] averageColor]];
		} else {
			[self setBackgroundColor:[NSColor controlHighlightColor]];
		}
	} else {
		[self bind:@"backgroundColor" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.QSAppearance2B" options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:@"NSValueTransformerName"]];
	}
}

- (void)dealloc {
	[self unbind:@"backgroundColor"];
}

- (void)awakeFromNib {
	[self bindColors];
	depth = 1.0;
}

- (void)_drawRect:(NSRect)rect withGradientFrom:(NSColor*)colorStart to:(NSColor*)colorEnd start:(NSRectEdge)edge {
	NSRect remainingRect;
	NSInteger i;
	NSInteger index = (edge == NSMinXEdge || edge == NSMaxXEdge) ? rect.size.width : rect.size.height;
	remainingRect = rect;
	NSColor *colors[index];
	NSRect rects[index];
	for ( i = 0; i < index; i++ ) {
		CGFloat fraction = sqrt((CGFloat) i/(CGFloat)index);
		NSDivideRect ( remainingRect, &rects[i] , &remainingRect, 1.0, edge);
		colors[i] = [colorStart blendedColorWithFraction:fraction ofColor:colorEnd];
	}
	NSRectFillListWithColors(&rects[0] , &colors[0] , index);
}

- (void)viewDidMoveToWindow {
	[self bindColors];
	[super viewDidMoveToWindow];
}

- (void)drawRect:(NSRect)rect {
	NSRect fullRect = [self convertRect:[self frame] fromView:[self superview]];
	if (![[self window] isOpaque] && [[self window] contentView] == self && [[self window] backgroundColor] == [NSColor clearColor]) {
		NSBezierPath *cornerEraser = [NSBezierPath bezierPath];
		[cornerEraser appendBezierPathWithRoundedRectangle:[self frame] withRadius:4];
		[cornerEraser addClip];
	}
	NSRect topRect, bottomRect;
	NSDivideRect(fullRect, &topRect, &bottomRect, NSHeight(fullRect) /2, NSMaxYEdge);
	[backgroundColor set];
	NSRectFill(fullRect);
	NSColor *highlightColor = [backgroundColor colorWithLighting:0.5*depth plasticity:0.667*depth];
	NSColor *shadowColor = [backgroundColor colorWithLighting:-0.1*depth];
	QSFillRectWithGradientFromEdge(topRect, highlightColor, backgroundColor, NSMaxYEdge);
	QSFillRectWithGradientFromEdge(bottomRect, shadowColor, backgroundColor, NSMinYEdge);
	[super drawRect:rect];
}

- (BOOL)mouseDownCanMoveWindow { return YES; }

- (NSColor *)backgroundColor { return backgroundColor;  }
- (void)setBackgroundColor:(NSColor *)aBackgroundColor {
	if (backgroundColor != aBackgroundColor) {
		backgroundColor = aBackgroundColor;
		[self setNeedsDisplay:YES];
	}
}

- (CGFloat) depth { return depth;  }
- (void)setDepth:(CGFloat)aDepth { depth = aDepth;  }
@end
