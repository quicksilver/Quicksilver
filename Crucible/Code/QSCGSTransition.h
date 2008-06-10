//
//  QSCGSTransition.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 10/9/05.

//

#import <Cocoa/Cocoa.h>

@interface QSCGSTransition : NSObject {
	int handle;
	CGSTransitionSpec spec;
}
+ (id)transitionWithWindow:(NSWindow *)window type:(CGSTransitionType)type option:(CGSTransitionOption)option;
+ (id)transitionWithWindow:(NSWindow *)window type:(CGSTransitionType)type option:(CGSTransitionOption)option duration:(float)duration;
+ (id)transitionWithType:(CGSTransitionType)type option:(CGSTransitionOption)option duration:(float)duration;
- (id) initWithType:(CGSTransitionType)type option:(CGSTransitionOption)option;
- (void)attachToWindow:(NSWindow *)window;
- (void)runTransition:(float)duration;
@end
