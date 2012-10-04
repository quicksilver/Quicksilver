#import <Cocoa/Cocoa.h>

@interface NSWindow (Fade)
- (void)setSticky:(BOOL)flag;
- (void)setAlphaValue:(CGFloat)fadeOut fadeTime:(CGFloat)seconds;
- (void)reallyCenter;
+(NSWindow *)windowWithImage:(NSImage *)image;
- (id)windowPropertyForKey:(NSString *)key;
@end

@interface NSWindow (Physics)
- (void)animateVelocity:(CGFloat)velocity inDirection:(CGFloat)angle withFriction:(CGFloat)friction startTime:(NSTimeInterval)startTime;
@end


@interface NSWindow (Widgets)
- (void)addInternalWidgets;
- (void)addInternalWidgetsForStyleMask:(NSInteger) styleMask;
- (void)addInternalWidgetsForStyleMask:(NSInteger) styleMask closeOnly:(BOOL)closeOnly;
@end

@interface NSWindow (Visibility)
- (void)useQuicksilverCollectionBehavior;
@end
