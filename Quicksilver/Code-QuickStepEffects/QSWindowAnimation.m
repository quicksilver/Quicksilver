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
	
	[super startAnimation];
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
