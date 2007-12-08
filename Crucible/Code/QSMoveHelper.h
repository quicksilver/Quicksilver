

#import <Foundation/Foundation.h>

@interface QSAnimationHelper : NSObject {
	NSTimer *_timer;
	
	NSTimeInterval _startTime;
	NSTimeInterval _totalTime;
	float _percent;
	
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
- (SEL)action;
- (BOOL)usesThreadedAnimation;
- (void)setUsesThreadedAnimation:(BOOL)flag;
- (void)_threadAnimation;

- (NSTimeInterval)startTime;
- (void)setStartTime:(NSTimeInterval)aStartTime;

- (NSTimeInterval)totalTime;
- (void)setTotalTime:(NSTimeInterval)aTotalTime;
@end

@interface QSMoveHelper : QSAnimationHelper {
	NSWindow *_window;
	struct _NSRect _endFrame;
	struct _NSRect _startFrame;
	float _startAlpha;
	float _endAlpha;
	BOOL _displayFlag;
}
- (void)_resizeWindow:(id)window toFrame:(struct _NSRect)frameRect alpha:(float)alpha display:(BOOL)flag;
@end
