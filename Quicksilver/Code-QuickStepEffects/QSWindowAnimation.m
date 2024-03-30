//
// QSWindowAnimation.m
// Quicksilver
//
// Created by Nicholas Jitkoff on 10/24/05.
// Copyright 2005 __MyCompanyName__. All rights reserved.
//

// Ankur, Dec 13: No longer retaining "attributes" dict. Just retain the individual values.

#import "QSWindowAnimation.h"

#import "QSEmbeddedEffects.h"

@implementation QSWindowAnimation

- (id)init {
	if (self = [super init]) {
		[self setDuration:0.3333f];
		transformFt = NULL;
		brightFt = NULL;
		effectFt = NULL;
		restoreTransform = YES;
	}
	return self;
}

- (id)initWithWindow:(NSWindow *)window {
	if (self = [self init]) {
		[self setWindow:window];
	}
	return self;
}

- (void)dealloc {
	
#ifdef DEBUG
	if(DEBUG_MEMORY) NSLog(@"qswindowanimation dealloc");
#endif
	
}

- (void)setAttributes:(NSDictionary *)attr {
	id value;
	if (value = [attr objectForKey:kQSGSTransformF])
		transformFt = CFBundleGetFunctionPointerForName (CFBundleGetBundleWithIdentifier(kQSEffectsID), (__bridge CFStringRef) value);
	if (value = [attr objectForKey:kQSGSBrightF])
		brightFt = CFBundleGetFunctionPointerForName (CFBundleGetBundleWithIdentifier(kQSEffectsID), (__bridge CFStringRef) value);
	if (value = [attr objectForKey:kQSGSAlphaF])
		alphaFt = CFBundleGetFunctionPointerForName (CFBundleGetBundleWithIdentifier(kQSEffectsID), (__bridge CFStringRef) value);
	if (value = [attr objectForKey:kQSGSDuration])
		[self setDuration:[value doubleValue]];
	if (value = [attr objectForKey:kQSGSType]) {
		[self setType:value];
		if ([value isEqualToString:@"show"]) {
			_alphaA = 0.0;
			_alphaB = 1.0;
		} else if ([value isEqualToString:@"hide"]) {
			_alphaA = 1.0;
			_alphaB = 0.0;
		} else if ([value isEqualToString:@"visible"]) {
			_alphaA = 1.0;
			_alphaB = 1.0;
			restoreTransform = NO;
		}
	}
	if (value = [attr objectForKey:kQSGSBrightA])
		_brightA = [value doubleValue];
	if (value = [attr objectForKey:kQSGSBrightB])
		_brightB = [value doubleValue];
	if (value = [attr objectForKey:kQSGSAlphaA])
		_alphaA = [value doubleValue];
	if (value = [attr objectForKey:kQSGSAlphaB])
		_alphaB = [value doubleValue];
}

- (void)setCurrentProgress:(NSAnimationProgress)progress {
	NSArray *childWindows = [_window childWindows];
//	NSLog(@"step %f", progress);
	CGFloat _percent = progress;
	 [super setCurrentProgress:progress];
//- (void)_doAnimationStep {
	if (effectFt) { 
		(*effectFt) (self);
	}
	if (transformFt) {
		CGAffineTransform newTransform = (*transformFt) (self, (CGFloat)_percent);


		if (progress >= 0.99f )
			newTransform = _transformA;
	}

	if (brightFt) {
		CGFloat brightness = (*brightFt) (self, _percent);
	}
	if (progress == 1.0f)
	[self finishAnimation];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"Window:%@\rAlpha:%f %f\rBright:%f %f\rTime ?\rTransform %p %p",
		[self window] , _alphaA, _alphaB, _brightA, _brightB,
		QSExtraExtraEffect, transformFt];
}


- (NSWindow *)window { return _window;  }
- (void)setWindow:(NSWindow *)aWindow {
	if(_window != aWindow){
		_window = aWindow;
	}
}

- (NSString *)type { return animType;  }
- (void)setType:(NSString *)aType {
	if(aType != animType){
		animType = aType;
	}
}

- (void)setAlphaFt:(void *)anAlphaFt {alphaFt = anAlphaFt;}
- (void)setTransformFt:(void *)aTransformFt {transformFt = aTransformFt;}


- (void)startAnimation {
//	CGSConnection cgs = _CGSDefaultConnection();
//	CGSGetWindowTransform(cgs, wid, &_transformA);

	//CGSTransformLog(_transformA);
	[super startAnimation];
}

- (void)finishAnimation {
	if (restoreTransform) {
		//	CGSTransformLog(_transformA);
		//[_window reallyOrderOut:nil];
//		CGSSetWindowTransform(cgs, wid, _transformA);
		//CGSSetWindowAlpha(cgs, wid, 1.0);
		//sleep(1);
		//	[_window setAlphaValue:0.9f];
		//	[_window setAlphaValue:1.0f];

	}
//	CGSSetWindowListBrightness(cgs, &wid, (float *)&_brightA, 1);

}


@end


@implementation QSWindowAnimation (DefaultEffects)

+ (QSWindowAnimation *)effectWithWindow:(NSWindow *)window attributes:(NSDictionary *)attr {
	QSWindowAnimation *helper = [[QSWindowAnimation alloc] initWithWindow:window];
	[helper setAttributes:attr];
	return helper;
}


+ (QSWindowAnimation *)showHelperForWindow:(NSWindow *)window {
	QSWindowAnimation *helper = [[QSWindowAnimation alloc] initWithWindow:window];
	helper->_alphaA = 0.0;
	helper->_alphaB = 1.0;
	return helper;
}

+ (QSWindowAnimation *)hideHelperForWindow:(NSWindow *)window {
	QSWindowAnimation *helper = [[QSWindowAnimation alloc] initWithWindow:window];
	helper->_alphaA = 1.0;
	helper->_alphaB = 0.0;
	return helper;
}

@end
