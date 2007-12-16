

#import "QSMoveHelper.h"

#import "QSEffects.h"
#import "NSGeometry_BLTRExtensions.h"

#include <unistd.h>


NSRect QSBlendRects(NSRect start, NSRect end,float b){
    
    return NSMakeRect(  round(NSMinX(start)*(1-b) + NSMinX(end)*b),
                        round(NSMinY(start)*(1-b) + NSMinY(end)*b),
                        round(NSWidth(start)*(1-b) + NSWidth(end)*b),
                        round(NSHeight(start)*(1-b) + NSHeight(end)*b));
}
@implementation QSAnimationHelper
+ (float)_windowAnimationVelocity{
	return 0.1;	
}

+ (id)helper{
	id helper=[[[self alloc]init]autorelease];
	return helper;
}


- (id)init{
	if ((self = [super init])) {
		_timer=nil;
	}
	return self;	
}
//- (void *)_effect;
//- (void)_releaseEffect;
//- (void)dealloc{
//	[super dealloc];
//}

- (void)_startAnimation{
	_timer=[[NSTimer scheduledTimerWithTimeInterval:1.0/30.0 target:self selector:@selector(_doAnimation) userInfo:nil repeats:YES]retain];	
}

- (void)_threadAnimation{
    while(([NSDate timeIntervalSinceReferenceDate]-_startTime)<_totalTime){
		[self _doAnimation];
		usleep(100);
		//  [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0/30]];
    }
	[self _doAnimation];
}

- (void)_doAnimationStep{}

- (void)_finishAnimation{
	//QSLog(@"finish");
}



- (void)_doAnimation{
	_percent=([NSDate timeIntervalSinceReferenceDate]-_startTime)/_totalTime;
	if (_percent>1.0) _percent=1.0f;
	
	[self _doAnimationStep];
	//QSLog(@"percent %f",_percent);
	if (_percent==1.0f){
		[self _stopAnimation];
		[self _finishAnimation];
		[[self target]performSelector:[self action]];	
	}else{
		usleep(10000);
	}
}


- (void)_stopAnimation{
	[_timer invalidate];	
	[_timer release];
	_timer=nil;
}


- (id)target { return [[target retain] autorelease]; }

- (void)setTarget:(id)aTarget {
    if (target != aTarget) {
        [target release];
        target = [aTarget retain];
    }
}

- (SEL)action { return endAction; }
- (void)setAction:(SEL)anAction {
	endAction = anAction;
}

- (BOOL)usesThreadedAnimation { return usesThreadedAnimation; }
- (void)setUsesThreadedAnimation:(BOOL)flag{
    usesThreadedAnimation = flag;
}

- (NSTimeInterval)startTime { return _startTime; }
- (void)setStartTime:(NSTimeInterval)aStartTime
{
    _startTime = aStartTime;
}


- (NSTimeInterval)totalTime { return _totalTime; }
- (void)setTotalTime:(NSTimeInterval)aTotalTime
{
    _totalTime = aTotalTime;
}

@end





@implementation QSMoveHelper
- (void)_doAnimation{
	_percent=([NSDate timeIntervalSinceReferenceDate]-_startTime)/_totalTime;
	//	QSLog(@"self %@",self);
	if (_percent>1.0){
		[_window setAlphaValue:_endAlpha];
		[_window setFrame:_endFrame display:YES];
		[self _stopAnimation];
		[[self target]performSelector:[self action]];
	}else{
		[_window setFrame: QSBlendRects(_startFrame,_endFrame,_percent) display:NO];
		[_window setAlphaValue: _startAlpha+_percent*(_endAlpha-_startAlpha)];
	}
}

- (void)_resizeWindow:(id)window toFrame:(struct _NSRect)frameRect alpha:(float)alpha display:(BOOL)flag{
	_startTime=[NSDate timeIntervalSinceReferenceDate];
	_totalTime=[window animationResizeTime:frameRect];
	
	_startFrame=[window frame];
	_endFrame=frameRect;
	
	_startAlpha=[window alphaValue];
	_endAlpha=alpha;
	
	_window=[window retain];
	[self _threadAnimation]; 
	
}
@end


/*
@implementation QSWarpEffectHelper
- (id)init{
	if ((self = [super init])) {
		_timer=nil;
		alphaFt=QSStandardAlphaBlending;
		effectFt=QSStandardTransformBlending;
		//_endTransform=CGAffineTransformIdentity;
	}
	return self;	
}

- (void)_doAnimation{
	[super _doAnimation];
	NSSize size=[_window frame].size;
	
	float f=_percent;
	
	CGSConnection cgs = _CGSDefaultConnection();
	
	int w,h;
	CGPointWarp *mesh=(*effectFt)(_window,_percent,&w,&h);
	CGSSetWindowWarp(cgs,[_window windowNumber], w,h, mesh);
	free(mesh);
	float alpha=(*alphaFt)(_window,_startAlpha,_endAlpha,_percent,2.0);
	CGSSetWindowAlpha(cgs,[_window windowNumber],alpha);
	
	if (_percent==1.0f){
		[self _stopAnimation];
		[[self target]performSelector:[self action]];	
	}
}

- (void)test:(id)window{
	_startTime=[NSDate timeIntervalSinceReferenceDate];
	_totalTime=3.0;
	_startAlpha=0.0f; //[window alphaValue];
	_endAlpha=1.0f;
	
	NSSize size=[_window frame].size;
	CGSConnection cgs = _CGSDefaultConnection();
	
	effectFt=QSTestMeshEffect;		
	_window=[window retain];
	[self _threadAnimation];
}
@end

*/