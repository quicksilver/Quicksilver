
#import <Cocoa/Cocoa.h>

@interface NSWindow (Fade)
-(void)setSticky:(BOOL)flag;
-(void)setAlphaValue:(float)fadeOut fadeTime:(float)seconds;
- (void)setFrame:(NSRect)frameRect alphaValue:(float)alpha display:(BOOL)displayFlag animate:(BOOL)animationFlag;
-(void)reallyCenter;
+(NSWindow *)windowWithImage:(NSImage *)image;
- (id)windowPropertyForKey:(NSString *)key;
@end

@interface NSWindow (Physics)
-(void)animateVelocity:(float)velocity inDirection:(float)angle withFriction:(float)friction startTime:(NSTimeInterval)startTime;
@end


@interface NSWindow (Widgets)
- (void) addInternalWidgets;
- (void) addInternalWidgetsForStyleMask:(int)styleMask;
@end

