//
//  QSModifierKeyEvents.h
//  Quicksilver
//
//  Created by Alcor on 8/16/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSInteger NSAllModifierKeysMask;

NSUInteger lastModifiers;
@interface NSApplication (QSModifierKeyEvents)
- (void)checkForModifierEvent:(NSEvent *)theEvent;
@end

@interface QSModifierKeyEvent : NSObject {
	NSUInteger modifierActivationMask;
	NSInteger modifierActivationCount;
	NSString *identifier;
	SEL action;


	@private
		NSInteger keyCode;
    
}

@property __block NSInteger timesKeysPressed;

+ (void)checkForModifierEvent:(NSEvent *)theEvent;
+ (QSModifierKeyEvent *)eventWithIdentifier:(NSString *)identifier;

- (void)enable;
- (void)disable;
+ (BOOL)alphaShiftReleased:(NSTimeInterval)eventTime;
- (void)checkForModifierTap:(BOOL)modsAdded;
//+(BOOL)modifierToggled:(unsigned int)modifierKeysMask eventTime:(NSTimeInterval)eventTime ;
+(BOOL)modifierToggled:(NSTimeInterval)eventTime ;
- (NSUInteger) modifierActivationMask;
- (void)setModifierActivationMask:(NSUInteger)newModifierActivationMask;
- (NSInteger) modifierActivationCount;
- (void)setModifierActivationCount:(NSInteger)newModifierActivationCount;
- (id)target;
- (void)setTarget:(id)newTarget;
- (SEL) action;
- (void)setAction:(SEL)newAction;
- (NSString *)identifier;
- (void)setIdentifier:(NSString *)newIdentifier;
- (void)sendAction;
@end
