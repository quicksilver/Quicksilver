#import <Cocoa/Cocoa.h>

@interface NSWindow (Fade)
- (void)setSticky:(BOOL)flag;
- (void)setAlphaValue:(CGFloat)fadeOut fadeTime:(CGFloat)seconds completionHandler:(nullable void (^)(void))completionHandler;
- (void)setAlphaValue:(CGFloat)fadeOut fadeTime:(CGFloat)seconds;
- (void)reallyCenter;
- (id _Nullable )windowPropertyForKey:(NSString *_Nullable)key;
@end

@interface NSWindow (Resize)

- (void)resizeToFrame:(NSRect)frameRect alpha:(CGFloat)alpha display:(BOOL)flag completionHandler:(nullable void (^)(void))completionHandler;
- (void)resizeToFrame:(NSRect)frameRect alpha:(CGFloat)alpha display:(BOOL)flag;

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
