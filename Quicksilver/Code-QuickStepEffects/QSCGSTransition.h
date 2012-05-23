//
//  QSCGSTransition.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 10/9/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QSFoundation/CGSPrivate.h>

@interface QSCGSTransition : NSObject {
	int handle;
	CGSTransitionSpec spec;
}
+ (id)transitionWithWindow:(NSWindow *)window type:(CGSTransitionType)type option:(CGSTransitionOption)option;
+ (id)transitionWithWindow:(NSWindow *)window type:(CGSTransitionType)type option:(CGSTransitionOption)option duration:(CGFloat)duration;
+ (id)transitionWithType:(CGSTransitionType)type option:(CGSTransitionOption)option duration:(CGFloat)duration;
- (id)initWithType:(CGSTransitionType) type option:(CGSTransitionOption)option;
- (void)attachToWindow:(NSWindow *)window;
- (void)runTransition:(CGFloat)duration;
@end
