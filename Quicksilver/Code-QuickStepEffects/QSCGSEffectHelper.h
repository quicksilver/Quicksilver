//
//  QSCGSEffectHelper.h
//  Quicksilver
//
//  Created by Alcor on 10/14/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QSMoveHelper.h"
#import "QSEmbeddedEffects.h"

#import "CGSPrivate.h"
#import "CGSPrivate+QSMods.h"


#define kQSGSTransformF @"transformFn"
#define kQSGSBrightF @"brightnessFn"
#define kQSGSWarpF @"warpFn"
#define kQSGSAlphaF @"alphaFn"
#define kQSGSType @"type"
#define kQSGSDuration @"duration"
#define kQSEffectsID (CFStringRef)@"com.blacktree.QSEffects"
#define kQSGSBrightA @"brightnessA"
#define kQSGSAlphaA @"alphaA"
#define kQSGSBrightB @"brightnessB"
#define kQSGSAlphaB @"alphaB"


@interface QSCGSEffectHelper : QSAnimationHelper {
	@public
	NSWindow *_window;
	int wid;
	CGSConnection cgs;
	
	void (*effectFt)(QSCGSEffectHelper *);
	
	CGPointWarp *(*warpFt)(QSCGSEffectHelper *,float,int *,int *);
	
	CGAffineTransform (*transformFt)(QSCGSEffectHelper *,float);
	struct CGAffineTransform _transformA;
	struct CGAffineTransform _transformB;
	
	float (*alphaFt)(QSCGSEffectHelper *,float);
	float _alphaA;
	float _alphaB;
	
	float (*brightFt)(QSCGSEffectHelper *,float);
	float _brightA;
	float _brightB;
	
	BOOL restoreTransform;
}
- (void)setAttributes:(NSDictionary *)attr;
- (NSWindow *)window;
- (void)setWindow:(NSWindow *)aWindow;
- (void)setTransformFt:(void *)aTransformFt;
- (void)animate:(id)sender;
//- (void)_transformWindow:(NSWindow *)window toTransformation:(CGAffineTransform)end  alpha:(float)alpha;
@end

@interface QSCGSEffectHelper (DefaultEffects)
+ (QSCGSEffectHelper *)effectWithWindow:(NSWindow *)window attributes:(NSDictionary *)attr;
+ (QSCGSEffectHelper *)showHelperForWindow:(NSWindow *)window;
+ (QSCGSEffectHelper *)hideHelperForWindow:(NSWindow *)window;

@end
