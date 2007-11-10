//
//  QSCGSEffectHelper.m
//  Quicksilver
//
//  Created by Alcor on 10/14/04.

//

#import "QSCGSEffectHelper.h"

#import "QSWarpEffects.h"



@implementation QSCGSEffectHelper

- (id)init{
	if (self = [super init]) {
		
		cgs = _CGSDefaultConnection();
		_totalTime=0.333;
		_timer=nil;
		alphaFt=QSStandardAlphaBlending;
		transformFt=NULL;
		warpFt=NULL;
		brightFt=NULL;
		effectFt=NULL;
		restoreTransform=YES;
	}
	return self;	
}

- (id)initWithWindow:(NSWindow *)window{
	if (self = [self init]) {
		[self setWindow:window];
		CGSGetWindowTransform(cgs,wid, &_transformA); 
	}
	return self;	
}

- (void)dealloc{
//	NSLog(@"help dealloc");
	[self setWindow:nil];
	[super dealloc];	
}

- (void)setAttributes:(NSDictionary *)attr{
	id value;
	//void *function;
	
	if (value=[attr objectForKey:kQSGSTransformF])
		transformFt=CFBundleGetFunctionPointerForName (CFBundleGetBundleWithIdentifier(kQSEffectsID),(CFStringRef)value);
	if (value=[attr objectForKey:kQSGSBrightF])
		brightFt=CFBundleGetFunctionPointerForName (CFBundleGetBundleWithIdentifier(kQSEffectsID),(CFStringRef)value);
	if (value=[attr objectForKey:kQSGSWarpF])
		warpFt=CFBundleGetFunctionPointerForName (CFBundleGetBundleWithIdentifier(kQSEffectsID),(CFStringRef)value);
	if (value=[attr objectForKey:kQSGSAlphaF])
		alphaFt=CFBundleGetFunctionPointerForName (CFBundleGetBundleWithIdentifier(kQSEffectsID),(CFStringRef)value);
	if (value=[attr objectForKey:kQSGSAlphaF])
		alphaFt=CFBundleGetFunctionPointerForName (CFBundleGetBundleWithIdentifier(kQSEffectsID),(CFStringRef)value);
	if (value=[attr objectForKey:kQSGSDuration])
		_totalTime=[value floatValue];
	if (value=[attr objectForKey:kQSGSType]){
		if ([value isEqualToString:@"show"]){
			_alphaA=0.0;
			_alphaB=1.0;
		}else if ([value isEqualToString:@"hide"]){
			_alphaA=1.0;
			_alphaB=0.0;
		}else if ([value isEqualToString:@"visible"]){
			_alphaA=1.0;
			_alphaB=1.0;
			restoreTransform=NO;
		}
	}
	if (value=[attr objectForKey:kQSGSBrightA])
		_brightA=[value floatValue];
	if (value=[attr objectForKey:kQSGSBrightB])
		_brightB=[value floatValue];
	if (value=[attr objectForKey:kQSGSAlphaA])
		_alphaA=[value floatValue];
	if (value=[attr objectForKey:kQSGSAlphaB])
		_alphaB=[value floatValue];
//	transformFt=QSExtraExtraEffect;
}


- (void)_doAnimationStep{
	if (effectFt){
		(*effectFt)(self);
	}
	if (transformFt){
		CGAffineTransform newTransform=(*transformFt)(self,_percent);
		CGSSetWindowTransform(cgs,wid, newTransform); 
		//CGSTransformLog(newTransform);
	}
	if (warpFt){
		int w,h;
		CGPointWarp *mesh=(*warpFt)(self,_percent,&w,&h);
		CGSSetWindowWarp(cgs,wid,w,h,(void *)mesh);
		free(mesh);
	}
	if (alphaFt){
		float alpha=(*alphaFt)(self,_percent);
		CGSSetWindowAlpha(cgs,wid,alpha);
	}
	if (brightFt){
		float brightness=(*brightFt)(self,_percent);
		CGSSetWindowListBrightness(cgs, &wid, &brightness,1);
	}
	
}

- (NSString *)description{
	return [NSString stringWithFormat:@"Window:%@\rAlpha:%f %f\rBright:%f %f\rTime %f\rTransform %p %p",
		[self window],_alphaA,_alphaB,_brightA,_brightB,_totalTime,
		QSExtraExtraEffect,transformFt];
}


- (NSWindow *)window { return _window; }

- (void)setWindow:(NSWindow *)aWindow{
    [_window autorelease];
    _window = [aWindow retain];
	wid=[aWindow windowNumber];
}

- (void)setAlphaFt:(void *)anAlphaFt{alphaFt=anAlphaFt;}
- (void)setTransformFt:(void *)aTransformFt{transformFt=aTransformFt;}



- (void)animate:(id)sender{
	
	_startTime=[NSDate timeIntervalSinceReferenceDate];
	
	//	CGSConnection cgs = _CGSDefaultConnection();
	//CGSGetWindowTransform(cgs,wid, &_transformA);
	//NSLog(@"animate");
	[self _threadAnimation];
	
}



- (void)_finishAnimation{
	if (restoreTransform){
	//	CGSTransformLog(_transformA);
		CGSSetWindowTransform(cgs,wid, _transformA); 
				CGSSetWindowAlpha(cgs,wid,1.0);
	//	[_window setAlphaValue:0.9f];
	//	[_window setAlphaValue:1.0f];
	
	}
	CGSSetWindowListBrightness(cgs, &wid, &_brightA,1);
	
}


@end


@implementation QSCGSEffectHelper (DefaultEffects)

+ (QSCGSEffectHelper *)effectWithWindow:(NSWindow *)window attributes:(NSDictionary *)attr{
	QSCGSEffectHelper *helper=[[[QSCGSEffectHelper alloc]initWithWindow:window]autorelease];
	[helper setAttributes:attr];
	return helper;
}


+ (QSCGSEffectHelper *)showHelperForWindow:(NSWindow *)window{
	QSCGSEffectHelper *helper=[[[QSCGSEffectHelper alloc]initWithWindow:window]autorelease];
	helper->_alphaA=0.0;
	helper->_alphaB=1.0;
	return helper;
}

+ (QSCGSEffectHelper *)hideHelperForWindow:(NSWindow *)window{
	QSCGSEffectHelper *helper=[[[QSCGSEffectHelper alloc]initWithWindow:window]autorelease];
	helper->_alphaA=1.0;
	helper->_alphaB=0.0;
	return helper;
}





- (void)flipHide:(id)window{
	_startTime=[NSDate timeIntervalSinceReferenceDate];
	_totalTime=0.25;
	_alphaA=1.0; //[window alphaValue];
	_alphaB=1.0;
	
	_window=[window retain];
	
	//NSSize size=[_window frame].size;
	 cgs = _CGSDefaultConnection();
	CGSGetWindowTransform(cgs,[window windowNumber], &_transformA);
	
	transformFt=QSPurgeEffect;	
	
	
	_brightA=0.0f; //[window alphaValue];
	_brightB=0.1f;
	
	brightFt=QSStandardBrightBlending;
	
	
	
	[self _threadAnimation];
}

- (void)flipShow:(id)window{
	_startTime=[NSDate timeIntervalSinceReferenceDate];
	_totalTime=0.25;
	_alphaA=1.0;
	_alphaB=1.0;
	
	_window=[window retain];
	
	//	NSSize size=[_window frame].size;
	 cgs = _CGSDefaultConnection();
	CGSGetWindowTransform(cgs,[window windowNumber], &_transformA);
	
	transformFt=QSBingeEffect;		
	
	_brightA=-0.40f; //[window alphaValue];
	_brightB=0.0;
	brightFt=QSStandardBrightBlending;
	
	
	
	[self _threadAnimation];
	
}


- (void)zoomWindow:(id)window{
	_startTime=[NSDate timeIntervalSinceReferenceDate];
	_totalTime=0.15;
	_alphaA=0.0f; //[window alphaValue];
	_alphaB=1.0f;
	
	//NSSize size=[_window frame].size;
	 cgs = _CGSDefaultConnection();
	CGSGetWindowTransform(cgs,[window windowNumber], &_transformA); 
	//CGSTransformLog(_transformA);
//	_transformB=CGAffineTransformRotate(CGAffineTransformTranslate(_transformA,_transformA.tx*2,_transformA.ty*2),90);
	//float s=.1;
//	_transformB=CGAffineTransformConcat(_transformA,CGAffineTransformScale(CGAffineTransformMakeTranslation(200,400),1,.3));
	transformFt=QSMMBlowEffect;		
	_window=[window retain];
	[self _threadAnimation];
}

- (void)spinShowWindow:(id)window{
	//	NSLog(@"self %@",self);
	[self retain];
	_startTime=[NSDate timeIntervalSinceReferenceDate];
	_totalTime=3.0;
	_alphaA=0.0f; //[window alphaValue];
	_alphaB=1.0f;
	
	//NSSize size=[_window frame].size;
	 cgs = _CGSDefaultConnection();
	CGSGetWindowTransform(cgs,[window windowNumber], &_transformA); 
	//CGSTransformLog(_transformA);
	_transformB=CGAffineTransformRotate(CGAffineTransformTranslate(_transformA,_transformA.tx*2,_transformA.ty*2),90);
	_transformB=CGAffineTransformConcat(_transformA,CGAffineTransformScale(CGAffineTransformMakeTranslation(200,400),1,.3));
	
	//NSLog(@"self %@",self);
	transformFt=QSExtraExtraEffect;	
	
	_brightA=1.0f; //[window alphaValue];
	_brightB=0.0f;
	
	brightFt=QSStandardBrightBlending;
	
	
	
	
	warpFt=QSTestMeshEffect;
	
	_window=[window retain];
	[self _threadAnimation];
}
@end