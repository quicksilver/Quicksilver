//
// QSCGSTransition.m
// Quicksilver
//
// Created by Nicholas Jitkoff on 10/9/05.
// Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "QSCGSTransition.h"
#import <unistd.h>

@implementation QSCGSTransition
+ (id)transitionWithType:(CGSTransitionType)type option:(CGSTransitionOption)option duration:(CGFloat)duration {
	return [[self alloc] initWithType:(CGSTransitionType) type option:(CGSTransitionOption)option];
}
+ (id)transitionWithWindow:(NSWindow *)window type:(CGSTransitionType)type option:(CGSTransitionOption)option duration:(CGFloat)duration {
	id transition = [[self alloc] initWithType:(CGSTransitionType)type option:(CGSTransitionOption)option];
	[transition attachToWindow:window];
	return transition;
}
+ (id)transitionWithWindow:(NSWindow *)window type:(CGSTransitionType)type option:(CGSTransitionOption)option {
	id transition = [[self alloc] initWithType:(CGSTransitionType) type option:(CGSTransitionOption)option];
	[transition attachToWindow:window];
	return transition;
}

- (id)initWithType:(CGSTransitionType) type option:(CGSTransitionOption)option {
	self = [super init];
	if (self != nil) {
		spec.unknown1 = 0;
		spec.type = type;
		spec.option = option | (1<<7);
		spec.wid = 0;
		spec.backColour = NULL;
	}
	return self;
}
- (void)dealloc {
	if (handle)
		CGSReleaseTransition(_CGSDefaultConnection(), handle);
}
- (void)attachToWindow:(NSWindow *)window {
	CGSConnection cgs = _CGSDefaultConnection();
	spec.wid = [window windowNumber];
	CGSNewTransition(cgs, &spec, &handle);
}
- (void)finishTransition {
	CGSReleaseTransition(_CGSDefaultConnection(), handle);
	handle = 0;
}
- (void)runTransition:(CGFloat)duration {
	if (!handle) return;
	CGSInvokeTransition(_CGSDefaultConnection(), handle, duration);
	usleep((useconds_t) (duration*1000000));
	[self finishTransition];
}

@end
