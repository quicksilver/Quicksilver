//
//  QSWindowAnimation.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 10/24/05.

//

#import "QSWindowAnimation.h"

#import "QSWindowAnimation.h"

#import "QSWarpEffects.h"
//@interface QSWindowAnimationInfo : NSObject <NSCopying>
//{
   // struct _NSRect _startFrame;
   // struct _NSRect _endFrame;
   // int _effect;
 //   struct _NSRect _lastFrame;
//}
//- (id)copyWithZone:(struct _NSZone *)fp8;
//@end

@implementation QSWindowAnimation

- (id)init{
	if ((self = [super init])) {
		cgs = _CGSDefaultConnection();
		[self setDuration:0.3333f];
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
	if ((self = [self init])) {
		[self setWindow:window];
		CGSGetWindowTransform(cgs,wid, &_transformA); 
	}
	return self;	
}

- (void)dealloc{
	//	QSLog(@"help dealloc");
	[self setWindow:nil];
	[super dealloc];	
}

- (void)setAttributes:(NSDictionary *)attr{
	id value;
	if ((value = [attr objectForKey:kQSGSTransformF]) != nil) {
		transformFt=CFBundleGetFunctionPointerForName (CFBundleGetBundleWithIdentifier(kQSEffectsID),(CFStringRef)value);
  }
	if ((value=[attr objectForKey:kQSGSBrightF]))
		brightFt=CFBundleGetFunctionPointerForName (CFBundleGetBundleWithIdentifier(kQSEffectsID),(CFStringRef)value);
	if ((value=[attr objectForKey:kQSGSWarpF]))
		warpFt=CFBundleGetFunctionPointerForName (CFBundleGetBundleWithIdentifier(kQSEffectsID),(CFStringRef)value);
	if ((value=[attr objectForKey:kQSGSAlphaF]))
		alphaFt=CFBundleGetFunctionPointerForName (CFBundleGetBundleWithIdentifier(kQSEffectsID),(CFStringRef)value);
	if ((value=[attr objectForKey:kQSGSAlphaF]))
		alphaFt=CFBundleGetFunctionPointerForName (CFBundleGetBundleWithIdentifier(kQSEffectsID),(CFStringRef)value);
	if ((value=[attr objectForKey:kQSGSDuration]))
		[self setDuration:[value floatValue]];
	if ((value=[attr objectForKey:kQSGSType])){
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
	if ((value=[attr objectForKey:kQSGSBrightA]))
		_brightA=[value floatValue];
	if ((value=[attr objectForKey:kQSGSBrightB]))
		_brightB=[value floatValue];
	if ((value=[attr objectForKey:kQSGSAlphaA]))
		_alphaA=[value floatValue];
	if ((value=[attr objectForKey:kQSGSAlphaB]))
		_alphaB=[value floatValue];
	
	if (attributes != attr) {
        [attributes release];
        attributes = [attr retain];
    }
}
- (NSDictionary *)attributes {
    return [[attributes retain] autorelease];
}




- (void)setCurrentProgress:(NSAnimationProgress)progress{
  if (wid < 0) return;
	NSArray *childWindows=[_window childWindows];
	float _percent=progress;
	 [super setCurrentProgress:progress];
//- (void)_doAnimationStep{
	if (effectFt){
		(*effectFt)(self);
	}
	if (transformFt){
		CGAffineTransform newTransform=(*transformFt)(self,_percent);
		CGSSetWindowTransform(cgs,wid, newTransform); 
		
//		if ([childWindows count]){
//			CGSSetWindowTransform(cgs,[[childWindows lastObject]windowNumber],newTransform);
//		}
	}
	if (warpFt){
		int w,h;
		CGPointWarp *mesh=(*warpFt)(self,_percent,&w,&h);
		CGSSetWindowWarp(cgs,wid,w,h,(void *)mesh);
		free(mesh);
	}
	if (alphaFt){
		float alpha=(*alphaFt)(self,progress);
		
	//	QSLog(@"step a %f",alpha);
	//	alpha=progress;
		CGSSetWindowAlpha(cgs,wid,alpha);
		
		if ([childWindows count]){
			// TODO: set as list
			foreach(window, childWindows) {
			CGSSetWindowAlpha(cgs,[window windowNumber],alpha);
			}
		}
		if (progress==1.0f)
			[_window setAlphaValue:alpha];
		
	}
	if (brightFt){
		float brightness=(*brightFt)(self,_percent);
		CGSSetWindowListBrightness(cgs, &wid, &brightness,1);
	}
	if (progress==1.0f)
	[self finishAnimation];
}

- (NSString *)description{
	return [NSString stringWithFormat:@"Window:%@\rAlpha:%f %f\rBright:%f %f\rTime ?\rTransform %p %p",
		[self window],_alphaA,_alphaB,_brightA,_brightB,
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


- (void)startAnimation{
//	CGSConnection cgs = _CGSDefaultConnection();
	CGSGetWindowTransform(cgs,wid, &_transformA);
	
	//CGSTransformLog(_transformA);
	[super startAnimation];
}

- (void)finishAnimation{
	if (restoreTransform){
		//	CGSTransformLog(_transformA);
		//[_window reallyOrderOut:nil];
		
		CGSSetWindowTransform(cgs,wid, _transformA); 
		//CGSSetWindowAlpha(cgs,wid,1.0);
		//sleep(1);
		//	[_window setAlphaValue:0.9f];
		//	[_window setAlphaValue:1.0f];
		
	}
	CGSSetWindowListBrightness(cgs, &wid, &_brightA,1);
	
}


@end

































@implementation QSWindowAnimation (DefaultEffects)

+ (QSWindowAnimation *)effectWithWindow:(NSWindow *)window attributes:(NSDictionary *)attr{
	QSWindowAnimation *helper=[[[QSWindowAnimation alloc]initWithWindow:window]autorelease];
	[helper setAttributes:attr];
	return helper;
}


+ (QSWindowAnimation *)showHelperForWindow:(NSWindow *)window{
	QSWindowAnimation *helper=[[[QSWindowAnimation alloc]initWithWindow:window]autorelease];
	helper->_alphaA=0.0;
	helper->_alphaB=1.0;
	return helper;
}

+ (QSWindowAnimation *)hideHelperForWindow:(NSWindow *)window{
	QSWindowAnimation *helper=[[[QSWindowAnimation alloc]initWithWindow:window]autorelease];
	helper->_alphaA=1.0;
	helper->_alphaB=0.0;
	return helper;
}





//- (void)flipHide:(id)window{
//	_startTime=[NSDate timeIntervalSinceReferenceDate];
//	_totalTime=0.25;
//	_alphaA=1.0; //[window alphaValue];
//	_alphaB=1.0;
//	
//	_window=[window retain];
//	
//	//NSSize size=[_window frame].size;
//	cgs = _CGSDefaultConnection();
//	CGSGetWindowTransform(cgs,[window windowNumber], &_transformA);
//	
//	transformFt=QSPurgeEffect;	
//	
//	
//	_brightA=0.0f; //[window alphaValue];
//	_brightB=0.1f;
//	
//	brightFt=QSStandardBrightBlending;
//	
//	
//	
//	[self _threadAnimation];
//}
//
//- (void)flipShow:(id)window{
//	_startTime=[NSDate timeIntervalSinceReferenceDate];
//	_totalTime=0.25;
//	_alphaA=1.0;
//	_alphaB=1.0;
//	
//	_window=[window retain];
//	
//	//	NSSize size=[_window frame].size;
//	cgs = _CGSDefaultConnection();
//	CGSGetWindowTransform(cgs,[window windowNumber], &_transformA);
//	
//	transformFt=QSBingeEffect;		
//	
//	_brightA=-0.40f; //[window alphaValue];
//	_brightB=0.0;
//	brightFt=QSStandardBrightBlending;
//	
//	
//	
//	[self _threadAnimation];
//	
//}
//
//
//- (void)zoomWindow:(id)window{
//	_startTime=[NSDate timeIntervalSinceReferenceDate];
//	_totalTime=0.15;
//	_alphaA=0.0f; //[window alphaValue];
//	_alphaB=1.0f;
//	
//	//NSSize size=[_window frame].size;
//	cgs = _CGSDefaultConnection();
//	CGSGetWindowTransform(cgs,[window windowNumber], &_transformA); 
//	//CGSTransformLog(_transformA);
//	//	_transformB=CGAffineTransformRotate(CGAffineTransformTranslate(_transformA,_transformA.tx*2,_transformA.ty*2),90);
//	//float s=.1;
//	//	_transformB=CGAffineTransformConcat(_transformA,CGAffineTransformScale(CGAffineTransformMakeTranslation(200,400),1,.3));
//	transformFt=QSMMBlowEffect;		
//	_window=[window retain];
//	[self _threadAnimation];
//}
//
//- (void)spinShowWindow:(id)window{
//	//	QSLog(@"self %@",self);
//	[self retain];
//	_startTime=[NSDate timeIntervalSinceReferenceDate];
//	_totalTime=3.0;
//	_alphaA=0.0f; //[window alphaValue];
//	_alphaB=1.0f;
//	
//	//NSSize size=[_window frame].size;
//	cgs = _CGSDefaultConnection();
//	CGSGetWindowTransform(cgs,[window windowNumber], &_transformA); 
//	//CGSTransformLog(_transformA);
//	_transformB=CGAffineTransformRotate(CGAffineTransformTranslate(_transformA,_transformA.tx*2,_transformA.ty*2),90);
//	_transformB=CGAffineTransformConcat(_transformA,CGAffineTransformScale(CGAffineTransformMakeTranslation(200,400),1,.3));
//	
//	//QSLog(@"self %@",self);
//	transformFt=QSExtraExtraEffect;	
//	
//	_brightA=1.0f; //[window alphaValue];
//	_brightB=0.0f;
//	
//	brightFt=QSStandardBrightBlending;
//	
//	
//	
//	
//	warpFt=QSTestMeshEffect;
//	
//	_window=[window retain];
//	[self _threadAnimation];
//}
@end