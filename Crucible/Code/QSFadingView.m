//
//  QSFadingBox.m
//  QSPrimerInterfacePlugIn
//
//  Created by Alcor on 12/25/04.

//

#import "QSFadingView.h"


@interface NSView (NSDecendantsPrivate)
-(void)_setDrawsOwnDescendants:(BOOL)flag;
@end

@implementation QSFadingView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		opacity=1.0;
        // Initialization code here.
		[self _setDrawsOwnDescendants:YES];
    }
    return self;
}
- (float)opacity { return opacity; }
- (void)setOpacity:(float)newOpacity{
	if (opacity!=newOpacity)
		[self setNeedsDisplay:YES];
	opacity = newOpacity;
}	


//- (void)displayRect:(struct _NSRect)fp8{	
//}

//- (void)_lightWeightRecursiveDisplayInRect:(struct _NSRect)fp8{
//	//QSLog(@"boo");	
//	//return nil;
//	[super _lightWeightRecursiveDisplayInRect:(struct _NSRect)fp8];
//}

- (void)_recursiveDisplayAllDirtyWithLockFocus:(BOOL)lock visRect:(NSRect)rect{
	if (!opacity){
		return;
	}else if (opacity>=1.0){
		[(id)super _recursiveDisplayAllDirtyWithLockFocus:(BOOL)lock visRect:(NSRect)rect];
	}else{
		CGContextRef context = (CGContextRef)([[NSGraphicsContext currentContext] graphicsPort]);
		CGContextSaveGState(context);
		CGContextSetAlpha(context, opacity);
		CGContextBeginTransparencyLayer(context, 0);
		[(id)super _recursiveDisplayAllDirtyWithLockFocus:(BOOL)lock visRect:(NSRect)rect];
		CGContextEndTransparencyLayer(context);
		CGContextRestoreGState(context);
	}
}

//- (void)_drawRect:(struct _NSRect)fp8 clip:(BOOL)fp24{
//	
//	QSLog(@"moox");	
//	return nil;
//	[NSGraphicsContext saveGraphicsState];
//	CGContextSetAlpha([[NSGraphicsContext currentContext]graphicsPort], 0.25);
//	[super _drawRect:(struct _NSRect)fp8 clip:(BOOL)fp24];
//	
//	[NSGraphicsContext restoreGraphicsState];
//}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
	//[super drawRect:rect];
	//if ([self superview]!=[[self window]contentView])
	//	QSLog(@"draw1");
	//QSLog(@"draw2");
//	CGContextSetAlpha([[NSGraphicsContext currentContext]graphicsPort], 0.5);
//	[[NSColor whiteColor]set];
//	NSRectFill(rect);
}

@end
