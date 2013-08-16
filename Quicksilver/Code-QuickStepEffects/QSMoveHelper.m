#import "QSMoveHelper.h"
/*#import "QSEffects.h"
#import "NSGeometry_BLTRExtensions.h"*/


NSRect QSBlendRects(NSRect start, NSRect end, CGFloat b) {
	return NSMakeRect(	round(NSMinX(start) *(1-b) + NSMinX(end)*b),
						round(NSMinY(start) *(1-b) + NSMinY(end)*b),
						round(NSWidth(start) *(1-b) + NSWidth(end)*b),
						round(NSHeight(start) *(1-b) + NSHeight(end)*b));
}

@implementation QSAnimationHelper
+ (CGFloat) _windowAnimationVelocity {
	return 0.1;
}

+ (id)helper {
	return [[self alloc] init];
}

- (id)init {
	if (self = [super init]) {
		_timer = nil;
	}
	return self;
}

- (void)dealloc {
	[_timer invalidate];
}

- (void)_startAnimation {
	_timer = [NSTimer scheduledTimerWithTimeInterval:1.0/30.0 target:self selector:@selector(_doAnimation) userInfo:nil repeats:YES];
}

- (void)_threadAnimation {
	while(([NSDate timeIntervalSinceReferenceDate] -_startTime) <_totalTime) {
		[self _doAnimation];
		usleep(100);
	}
	[self _doAnimation];
}

- (void)_doAnimationStep {}
- (void)_finishAnimation {}

- (void)_doAnimation {
	_percent = ([NSDate timeIntervalSinceReferenceDate] -_startTime) /_totalTime;
	if (_percent>1.0) _percent = 1.0f;

	[self _doAnimationStep];
	if (_percent == 1.0f) {
		[self _stopAnimation];
		[self _finishAnimation];
		[[self target] performSelector:[self action]];
	} else {
		usleep(10000);
	}
}

- (void)_stopAnimation {
	[_timer invalidate];
	_timer = nil;
}

- (id)target { return target;  }
- (void)setTarget:(id)aTarget {
	if (target != aTarget) {
		target = aTarget;
	}
}

- (SEL)action { return endAction;  }
- (void)setAction:(SEL)anAction {
	endAction = anAction;
}

- (BOOL)usesThreadedAnimation { return usesThreadedAnimation;  }
- (void)setUsesThreadedAnimation:(BOOL)flag {
	usesThreadedAnimation = flag;
}

- (NSTimeInterval) startTime { return _startTime;  }
- (void)setStartTime:(NSTimeInterval)aStartTime {
	_startTime = aStartTime;
}

- (NSTimeInterval) totalTime { return _totalTime;  }
- (void)setTotalTime:(NSTimeInterval)aTotalTime {
	_totalTime = aTotalTime;
}

@end

@implementation QSMoveHelper
- (void)_doAnimation {
	_percent = ([NSDate timeIntervalSinceReferenceDate] -_startTime) /_totalTime;
	if (_percent>1.0) {
		[_window setAlphaValue:_endAlpha];
		[_window setFrame:_endFrame display:YES];
		[self _stopAnimation];
		[[self target] performSelector:[self action]];
	} else {
		[_window setFrame:QSBlendRects(_startFrame, _endFrame, _percent) display:NO];
		[_window setAlphaValue: _startAlpha+_percent*(_endAlpha-_startAlpha)];
	}
}

- (void)_resizeWindow:(id)window toFrame:(NSRect)frameRect alpha:(CGFloat)alpha display:(BOOL)flag {
	_startTime = [NSDate timeIntervalSinceReferenceDate];
	_totalTime = [window animationResizeTime:frameRect];

	_startFrame = [window frame];
	_endFrame = frameRect;

	_startAlpha = [window alphaValue];
	_endAlpha = alpha;

	_window = window;
	[self _threadAnimation];

}
@end
