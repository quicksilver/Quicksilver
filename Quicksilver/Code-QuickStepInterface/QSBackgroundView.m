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
		[self bind:@"backgroundColor" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.QSAppearance2B" options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:NSValueTransformerNameBindingOption]];
	}
}

- (void)dealloc {
	[self unbind:@"backgroundColor"];
}

- (void)awakeFromNib {
	[self bindColors];
	depth = 1.0;
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
	[backgroundColor set];
	NSRectFill(fullRect);
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
