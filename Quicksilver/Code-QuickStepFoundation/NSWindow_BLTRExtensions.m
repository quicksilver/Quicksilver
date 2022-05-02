#import "NSWindow_BLTRExtensions.h"
#import "NSGeometry_BLTRExtensions.h"
#import "CGSPrivate.h"

@implementation NSWindow (Fade)
- (id)windowPropertyForKey:(NSString *)key { return nil; }

- (void)setSticky:(BOOL)flag {
	[self setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorStationary | NSWindowCollectionBehaviorIgnoresCycle];
}

- (void)setAlphaValue:(CGFloat)fadeOut fadeTime:(CGFloat)seconds completionHandler:(nullable void (^)(void))completionHandler {
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
		[context setDuration:seconds];
		[[self animator] setAlphaValue:fadeOut];
	} completionHandler:^{
		if (completionHandler) {
			completionHandler();
		}
	}];

}
- (void)setAlphaValue:(CGFloat)fadeOut fadeTime:(CGFloat)seconds {
	[self setAlphaValue:fadeOut fadeTime:seconds completionHandler:nil];
}

- (BOOL)animationIsValid { return YES; }
- (void)reallyCenter {
	NSRect screenRect = [[self screen] frame];
	NSRect windowRect = [self frame];
	NSRect centeredRect = NSOffsetRect(windowRect, NSMidX(screenRect) -NSMidX(windowRect), NSMidY(screenRect)-NSMidY(windowRect));
	[self setFrame:centeredRect display:NO];
}


@end

@implementation NSWindow (Resize)
- (void)resizeToFrame:(NSRect)frameRect alpha:(CGFloat)alpha display:(BOOL)flag completionHandler:(nullable void (^)(void))completionHandler {
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
		[context setDuration:[self animationResizeTime:frameRect]];
		[[self animator] setFrame:frameRect display:flag];
		[[self animator] setAlphaValue:alpha];
	} completionHandler:^{
		if (completionHandler) {
			completionHandler();
		}
	}];
}

- (void)resizeToFrame:(NSRect)frameRect alpha:(CGFloat)alpha display:(BOOL)flag {
	[self resizeToFrame:frameRect alpha:alpha display:flag completionHandler:nil];
}
@end

@implementation NSWindow (Physics)
- (void)animateVelocity:(CGFloat)velocity inDirection:(CGFloat)angle withFriction:(CGFloat)friction startTime:(NSTimeInterval)startTime {
	//NSLog(@"Animating Velocity:%f, %f, %f", velocity, angle, friction);
	//friction = friction/10;

	CGFloat v = velocity;
	// NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
	//NSTimeInterval thisTime, elapsedTime;
    //thisTime = startTime;
	//NSRect startFrame = [self frame];

	NSRect newFrame = [self frame];
    NSTimeInterval elapsedTime;

	while (v>0) {

		//NSLog(@"Animating Velocity:%f", v);

		//thisTime = [NSDate timeIntervalSinceReferenceDate];
		elapsedTime = [NSDate timeIntervalSinceReferenceDate] -startTime;


		newFrame.origin.x += v * elapsedTime * sin(angle);
		newFrame.origin.y += v * elapsedTime * cos(angle);

		if (!NSContainsRect([[self screen] frame] , newFrame) ) {
			//NSLog(@"---------");

			CGFloat dMaxX = NSMaxX(newFrame) - NSMaxX([[self screen] frame]);
			CGFloat dMinX = NSMinX(newFrame) - NSMinX([[self screen] frame]);
			CGFloat dMaxY = NSMaxY(newFrame) - NSMaxY([[self screen] frame]);
			CGFloat dMinY = NSMinY(newFrame) - NSMinY([[self screen] frame]);

			NSPoint coordVelocity = NSMakePoint(sin(angle), cos(angle) );
			//NSLog(@"bounce %f %f, %f", coordVelocity.x, coordVelocity.y, angle*180/pi);

			if (dMaxX >= 0) {
				//NSLog(@"xmax");
				coordVelocity.x = -fabs(coordVelocity.x);
				newFrame.origin.x -= 2*dMaxX;
			} else if (dMinX <= 0) {
				//NSLog(@"xmin");
				coordVelocity.x = fabs(coordVelocity.x);
				newFrame.origin.x -= 2*dMinX;
			}
			//else NSLog(@"notx %f %f", dMaxX, dMinX);

			if (dMaxY >= 0) {
				//NSLog(@"ymax");
				coordVelocity.y = -fabs(coordVelocity.y);
				newFrame.origin.y -= 2*dMaxY;
			} else if (dMinY <= 0) {
				//NSLog(@"xmin");
				coordVelocity.y = fabs(coordVelocity.y);
				newFrame.origin.y -= 2*dMinY;
			}
			// else NSLog(@"noty %f %f", dMaxY, dMinY);

			// if (NSMaxY([self frame]) > NSMaxY([[self screen] frame]) )coordVelocity.y = -fabs(coordVelocity.y);
			//else if ( NSMinY([self frame]) < NSMinY([[self screen] frame]) ) coordVelocity.y = fabs(coordVelocity.y);




			angle = atan2(coordVelocity.x, coordVelocity.y);
			v -= friction * 4;
			//NSLog(@"bouncd %f %f, %f", coordVelocity.x, coordVelocity.y, angle*180/pi);
			//newFrame = NSOffsetRect([self frame] , v * elapsedTime * coordVelocity.x, v * elapsedTime * coordVelocity.y);
		}

		[self setFrame:newFrame display:YES animate:NO];
		v = v-friction * elapsedTime;

	}
	newFrame.origin.x = (NSInteger) newFrame.origin.x;
	newFrame.origin.y = (NSInteger) newFrame.origin.y;
 [self setFrame:newFrame display:YES animate:NO];
}
@end

@implementation NSWindow (Widgets)
- (void)addInternalWidgets {
	[self addInternalWidgetsForStyleMask:[self styleMask]];
}


- (void)addInternalWidgetsForStyleMask:(NSInteger) styleMask closeOnly:(BOOL)closeOnly {
	NSButton *closeButton = [NSWindow standardWindowButton:NSWindowCloseButton forStyleMask:styleMask];
	NSPoint widgetOrigin = NSMakePoint(3, NSHeight([self frame]) -NSHeight([closeButton frame])-3);
	[closeButton setFrameOrigin:widgetOrigin];
	[closeButton setAutoresizingMask:NSViewMinYMargin];
	[[self contentView] addSubview:closeButton];

	widgetOrigin.x += NSWidth([closeButton frame]) +2;


	if (!closeOnly) {
	NSButton *minimizeButton = [NSWindow standardWindowButton:NSWindowMiniaturizeButton forStyleMask:styleMask];
	NSButton *zoomButton = [NSWindow standardWindowButton:NSWindowZoomButton forStyleMask:styleMask];
	[minimizeButton setFrameOrigin:widgetOrigin];
	widgetOrigin.x += NSWidth([closeButton frame]) +2;
	[zoomButton setFrameOrigin:widgetOrigin];
	widgetOrigin.x += NSWidth([closeButton frame]) +2;
	[minimizeButton setAutoresizingMask:NSViewMinYMargin];
	[zoomButton setAutoresizingMask:NSViewMinYMargin];
	[[self contentView] addSubview:minimizeButton];
	[[self contentView] addSubview:zoomButton];
	}
//	[zoomButton cell] ._hasRollover = YES;

}
- (void)addInternalWidgetsForStyleMask:(NSInteger) styleMask {
	[self addInternalWidgetsForStyleMask:(NSInteger) styleMask closeOnly:NO];
}
@end

@implementation NSWindow (Visibility)

- (void)useQuicksilverCollectionBehavior
{
    // make windows visible in all spaces
    [self setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary];
}

@end
