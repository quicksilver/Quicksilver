//
//  QSModifierKeyEvents.h
//  Quicksilver
//
//  Created by Alcor on 8/16/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern int NSAllModifierKeysMask;

@interface NSApplication (QSModifierKeyEvents)
- (BOOL)checkForModifierEvent:(NSEvent *)theEvent;
@end

@interface QSModifierKeyEvent : NSObject {
	unsigned int modifierActivationMask;
	int modifierActivationCount;
	
    NSString *identifier;
    NSMutableArray * /* NSDate * */ activationAttempts;
	id target;
	SEL action;

/*	@private
		int keyCode;*/
}
+ (BOOL)checkForModifierEvent:(NSEvent *)theEvent;
+ (QSModifierKeyEvent *)eventWithIdentifier:(NSString *)identifier;


- (void)enable;
- (void)disable;
- (BOOL)modifierToggled:(unsigned int)modifierKeysMask countTimes:(unsigned int)count;
//- (BOOL)checkForModifierTap;

- (unsigned int)modifierActivationMask;
- (void)setModifierActivationMask:(unsigned int)newModifierActivationMask;
- (int)modifierActivationCount;
- (void)setModifierActivationCount:(int)newModifierActivationCount;
- (id)target;
- (void)setTarget:(id)newTarget;
- (SEL)action;
- (void)setAction:(SEL)newAction;
- (NSString *)identifier;
- (void)setIdentifier:(NSString *)newIdentifier;
- (void)sendAction;
@end
