#import <Foundation/Foundation.h>

@interface QSAnimationHelper : NSObject {
	NSTimer *_timer;

	NSTimeInterval _startTime;
	NSTimeInterval _totalTime;
	CGFloat _percent;

	id target;
	SEL endAction;

	BOOL _done;
	BOOL usesThreadedAnimation;
}
- (void)_doAnimation;
- (void)_stopAnimation;
- (void)setTarget:(id)anObject;
- (id)target;
- (void)setAction:(SEL)aSelector;
- (SEL) action;
- (BOOL)usesThreadedAnimation;
- (void)setUsesThreadedAnimation:(BOOL)flag;
- (void)_threadAnimation;

- (NSTimeInterval) startTime;
- (void)setStartTime:(NSTimeInterval)aStartTime;

- (NSTimeInterval) totalTime;
- (void)setTotalTime:(NSTimeInterval)aTotalTime;
@end

@interface QSMoveHelper : QSAnimationHelper {
	NSWindow *_window;
	NSRect _endFrame;
	NSRect _startFrame;
	CGFloat _startAlpha;
	CGFloat _endAlpha;
	BOOL _displayFlag;
}
- (void)_resizeWindow:(id)window toFrame:(NSRect)frameRect alpha:(CGFloat)alpha display:(BOOL)flag;
@end
