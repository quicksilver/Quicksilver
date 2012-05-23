//
// QSEffects.m
// Quicksilver
//
// Created by Alcor on 9/27/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "QSEffects.h"
#import "QSWindowAnimation.h"

CGFloat QSStandardAlphaBlending(QSWindowAnimation *hl, CGFloat f) {
	return (1-f) *hl->_alphaA + f*hl->_alphaB;
}

CGFloat QSStandardBrightBlending(QSWindowAnimation *hl, CGFloat f) {
	f = f/4;
	return (1-f) *hl->_brightA + f*hl->_brightB;
}

CGAffineTransform QSStandardTransformBlending(QSWindowAnimation *hl, CGFloat f) {
	CGAffineTransform start = hl->_transformA;
	CGAffineTransform end = hl->_transformB;
	CGAffineTransform t;
	t.a = ((1-f) *start.a+f*end.a);
	t.b = ((1-f) *start.b+f*end.b);
	t.c = ((1-f) *start.c+f*end.c);
	t.d = ((1-f) *start.d+f*end.d);
	t.tx = ((1-f) *start.tx+f*end.tx);
	t.ty = ((1-f) *start.ty+f*end.ty);
	return t;
}

CGAffineTransform QSPurgeEffect(QSWindowAnimation *hl, CGFloat f) {
	NSSize size = [hl->_window frame].size;
	f = cos(f*M_PI_2);
	CGFloat s = pow(f, 2);
	CGAffineTransform modTransform = CGAffineTransformMakeScale(1/s, 1);
	modTransform = CGAffineTransformTranslate(modTransform, -size.width/2 + size.width/2*s, 0);
	return CGAffineTransformConcat(hl->_transformA, modTransform);
}

CGAffineTransform QSBingeEffect(QSWindowAnimation *hl, CGFloat f) {
	NSSize size = [hl->_window frame] .size;
	f = sin(f*M_PI_2);
	CGFloat s = pow(f, 2);
	CGAffineTransform modTransform = CGAffineTransformMakeScale(1/s, 1);
	modTransform = CGAffineTransformTranslate(modTransform, -size.width/2 + size.width/2*s, 0);
	return CGAffineTransformConcat(hl->_transformA, modTransform);
}

CGAffineTransform QSVContractEffect(QSWindowAnimation *hl, CGFloat f) {
	NSSize size = [hl->_window frame] .size;
	f = cos(f*M_PI_2);
	CGFloat s = pow(f, 2);
	CGFloat s2 = pow(f, 16);
	CGAffineTransform t = CGAffineTransformMakeTranslation(size.width/2, size.height/2);
	t = CGAffineTransformScale(t, s, 1/s2);
	t = CGAffineTransformTranslate(t, -size.width/2, -size.height/2);
	return CGAffineTransformConcat(hl->_transformA, t);
}

CGAffineTransform QSVExpandEffect(QSWindowAnimation *hl, CGFloat f) {
	NSSize size = [hl->_window frame] .size;
	f = sin(f*M_PI_2);
	CGFloat s = pow(f, 2);
	CGAffineTransform modTransform = CGAffineTransformMakeScale(1, 1/s);
	modTransform = CGAffineTransformTranslate(modTransform, 0, size.height/2 * (s-1) );
	return CGAffineTransformConcat(hl->_transformA, modTransform);
}

CGAffineTransform QSSlightGrowEffect(QSWindowAnimation *hl, CGFloat f) {
	NSSize size = [hl->_window frame] .size;
	CGFloat s = pow(f, 0.5);
	s = s/8+0.875f;
	CGAffineTransform newTransform = CGAffineTransformConcat(hl->_transformA, CGAffineTransformTranslate(CGAffineTransformMakeScale(1/s, 1/s), -size.width/2 + size.width/2*s, -size.height/2+size.height/2*s) );
	return newTransform;
}

CGAffineTransform QSSlightShrinkEffect(QSWindowAnimation *hl, CGFloat f) {
	NSSize size = [hl->_window frame] .size;
	CGFloat s = 1-f; //pow(1-f, 4);
	s = s/8+0.875f;
	CGAffineTransform newTransform = CGAffineTransformConcat(hl->_transformA, CGAffineTransformTranslate(CGAffineTransformMakeScale(1/s, 1/s), -size.width/2 + size.width/2*s, -size.height/2+size.height/2*s) );
	return newTransform;
}

CGAffineTransform QSDefaultGrowEffect(QSWindowAnimation *hl, CGFloat f) {
	NSSize size = [hl->_window frame] .size;
	CGFloat s = pow(f, 0.5);
	s = s/20+0.95f;
	CGAffineTransform newTransform = CGAffineTransformConcat(hl->_transformA, CGAffineTransformTranslate(CGAffineTransformMakeScale(1/s, 1/s), -size.width/2 + size.width/2*s, -size.height/2+size.height/2*s+(1-f) *40));
	return newTransform;
}

CGAffineTransform QSDefaultShrinkEffect(QSWindowAnimation *hl, CGFloat f) {
	NSSize size = [hl->_window frame] .size;
	CGFloat s = 1-f; //pow(1-f, 4);
		s = s/20+0.95f;
		CGAffineTransform newTransform = CGAffineTransformConcat(hl->_transformA, CGAffineTransformTranslate(CGAffineTransformMakeScale(1/s, 1/s), -size.width/2 + size.width/2*s, -size.height/2+size.height/2*s-f*20) );
		return newTransform;
}

CGAffineTransform QSGrowEffect(QSWindowAnimation *hl, CGFloat f) {
	NSSize size = [hl->_window frame] .size;
	CGFloat s = pow(f, 4);
	CGAffineTransform newTransform = CGAffineTransformConcat(hl->_transformA, CGAffineTransformTranslate(CGAffineTransformMakeScale(1/s, 1/s), -size.width/2 + size.width/2*s, -size.height/2+size.height/2*s) );
	return newTransform;
}

CGAffineTransform QSShrinkEffect(QSWindowAnimation *hl, CGFloat f) {
	NSSize size = [hl->_window frame] .size;
	CGFloat s = pow(1-f, 4);
	CGAffineTransform newTransform = CGAffineTransformConcat(hl->_transformA, CGAffineTransformTranslate(CGAffineTransformMakeScale(1/s, 1/s), -size.width/2 + size.width/2*s, -size.height/2+size.height/2*s) );
	return newTransform;
}

CGAffineTransform QSVillainousKryptonianEffect(QSWindowAnimation *hl, CGFloat f) {
	//NSSize size = [hl->_window frame] .size;
	//float s = pow(1-f, 4);
//	CGAffineTransform newTransform = CGAffineTransformConcat(hl->_transformA, CGAffineTransformTranslate(CGAffineTransformMakeScale(1/s, 1/s), -size.width/2 + size.width/2*s, -size.height/2+size.height/2*s) );
	return hl->_transformA;
}

CGAffineTransform QSShakeItLikeAPolaroidPictureEffect(QSWindowAnimation *hl, CGFloat f) {
//	NSSize size = [hl->_window frame] .size;
	CGFloat s = 0.1*sin(f*M_PI*3);
	CGAffineTransform t = CGAffineTransformIdentity;
	//t.b = 1+.25*sin(f*M_PI*4);
	t.c = s;
	//CGAffineTransformMakeTranslation(size.width/2, size.height/2);
	//t = CGAffineTransformRotate(t, 4*M_PI*r);
	//t = CGAffineTransformScale(t, 1/s, 1/s);
	//t = CGAffineTransformTranslate(t, -s*size.width/2, (1-f) *4*size.height);
	return CGAffineTransformConcat(hl->_transformA, t);
}

CGAffineTransform QSLudicrousSpeedEffect(QSWindowAnimation *hl, CGFloat f) {
	NSSize size = [hl->_window frame].size;
//	float s = pow(f, 2);
	CGFloat r = pow(1-f, 2);
	CGFloat h = 1-pow(f, 4);
	CGAffineTransform t = CGAffineTransformMakeTranslation(size.width/2, size.height/2);
	//t = CGAffineTransformScale(t, 1/s, (2-s) /s);
	t.c = h*2.0;
	t = CGAffineTransformTranslate(t, r*4*size.width-size.width/2, -size.height/2);
	return CGAffineTransformConcat(hl->_transformA, t);
}

CGAffineTransform QSExtraExtraEffect(QSWindowAnimation *hl, CGFloat f) {
	NSSize size = [hl->_window frame] .size;
	CGFloat s = pow(f, 2);
	CGFloat r = -pow(1-f, 2);
	CGAffineTransform t = CGAffineTransformMakeTranslation(size.width/2, size.height/2);
	t = CGAffineTransformRotate(t, 4*M_PI*r);
	t = CGAffineTransformScale(t, 1/s, 1/s);
	t = CGAffineTransformTranslate(t, -size.width/2, -size.height/2);
	return CGAffineTransformConcat(hl->_transformA, t);
}

CGAffineTransform QSMMBlowEffect(QSWindowAnimation *hl, CGFloat f) {
	NSSize size = [hl->_window frame] .size;
	CGFloat s = pow(f, 2);
//	float r = pow(1-f, 2);
	CGAffineTransform t = CGAffineTransformMakeTranslation(size.width/2, size.height/2);
	t = CGAffineTransformScale(t, 1/s, 1/s);
	t = CGAffineTransformTranslate(t, -size.width/2, -size.height/2);
	//t.d = 1;
	return CGAffineTransformConcat(hl->_transformA, t);
}

CGAffineTransform QSExplodeEffect(QSWindowAnimation *hl, CGFloat f) {
	NSSize size = [hl->_window frame] .size;
	//float s = pow(f, 4);
	CGFloat s = .97+1*pow(f-0.1, 2);
	CGAffineTransform newTransform = CGAffineTransformConcat(hl->_transformA, CGAffineTransformTranslate(CGAffineTransformMakeScale(1/s, 1/s), -size.width/2 + size.width/2*s, -size.height/2+size.height/2*s) );
	return newTransform;
}

void CGSTransformLog(CGAffineTransform t) {
#warning 64BIT: Check formatting arguments
	NSLog(@" a:%f b:%f c:%f d:%f tx:%f ty:%f", t.a, t.b, t.c, t.d, t.tx, t.ty);
}
