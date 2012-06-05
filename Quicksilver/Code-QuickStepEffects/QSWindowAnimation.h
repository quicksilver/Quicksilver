//
//  QSWindowAnimation.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 10/24/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QSFoundation/CGSPrivate.h>

#define kQSGSTransformF @"transformFn"
#define kQSGSBrightF @"brightnessFn"
#define kQSGSWarpF @"warpFn"
#define kQSGSAlphaF @"alphaFn"
#define kQSGSType @"type"
#define kQSGSDuration @"duration"
#define kQSEffectsID (CFStringRef) @"com.blacktree.QSEffects"
#define kQSGSBrightA @"brightnessA"
#define kQSGSAlphaA @"alphaA"
#define kQSGSBrightB @"brightnessB"
#define kQSGSAlphaB @"alphaB"

@interface QSWindowAnimation : NSAnimation {
	@public
	NSWindow *_window;
	int wid;
	CGSConnection cgs;

	void (*effectFt) (QSWindowAnimation *);

	CGPointWarp *(*warpFt) (QSWindowAnimation *, CGFloat, NSInteger *, NSInteger *);

	CGAffineTransform (*transformFt) (QSWindowAnimation *, CGFloat);
	struct CGAffineTransform _transformA;
	struct CGAffineTransform _transformB;

	CGFloat (*alphaFt) (QSWindowAnimation *, CGFloat);
	CGFloat _alphaA;
	CGFloat _alphaB;

	CGFloat (*brightFt) (QSWindowAnimation *, CGFloat);
	CGFloat _brightA;
	CGFloat _brightB;

	NSString *animType;
	BOOL restoreTransform;
}
- (void)setAttributes:(NSDictionary *)value;

- (NSString *)type;
- (void)setType:(NSString *)aType;

- (NSWindow *)window;
- (void)setWindow:(NSWindow *)aWindow;
- (void)setTransformFt:(void *)aTransformFt;
//- (void)animate:(id)sender;
//- (void)_transformWindow:(NSWindow *)window toTransformation:(CGAffineTransform)end  alpha:(float)alpha;
- (void)finishAnimation;
@end

@interface QSWindowAnimation (DefaultEffects)
+ (QSWindowAnimation *)effectWithWindow:(NSWindow *)window attributes:(NSDictionary *)attr;
+ (QSWindowAnimation *)showHelperForWindow:(NSWindow *)window;
+ (QSWindowAnimation *)hideHelperForWindow:(NSWindow *)window;

@end
