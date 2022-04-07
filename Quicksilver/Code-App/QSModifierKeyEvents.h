//
//  QSModifierKeyEvents.h
//  Quicksilver
//
//  Created by Alcor on 8/16/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSInteger NSAllModifierKeysMask;
extern NSUInteger lastModifiers;

@interface NSApplication (QSModifierKeyEvents)
- (void)checkForModifierEvent:(NSEvent *)theEvent;
@end

@interface QSModifierKeyEvent : NSObject {
    NSUInteger _modifierActivationMask;
	NSString *identifier;
	SEL action;

	@private
    uint32_t pressedKeyDownCount;

}

@property __block NSInteger timesKeysPressed;
@property (nonatomic, retain) id target;
@property SEL action;
@property NSString *identifier;
@property NSInteger modifierActivationCount;

+ (void)checkForModifierEvent:(NSEvent *)theEvent;
+ (QSModifierKeyEvent *)eventWithIdentifier:(NSString *)identifier;
+ (void)resetModifierState;

- (void)enable;
- (void)disable;

- (void)checkForModifierTap:(BOOL)modsAdded;

- (NSUInteger) modifierActivationMask;
- (void)setModifierActivationMask:(NSUInteger)newModifierActivationMask;
- (void)sendAction;
@end
