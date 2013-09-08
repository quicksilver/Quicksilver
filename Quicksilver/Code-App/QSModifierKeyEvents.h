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
    NSUInteger _modifierActivationMask;
	NSString *identifier;
	SEL action;

	@private
		NSInteger keyCode;
        NSTimeInterval timeSinceLastKeyDown;
        NSDate *firstModifierPressedTime;
    
}

@property __block NSInteger timesKeysPressed;
@property (nonatomic, retain) id target;
@property SEL action;
@property NSString *identifier;
@property NSInteger modifierActivationCount;

+ (void)checkForModifierEvent:(NSEvent *)theEvent;
+ (QSModifierKeyEvent *)eventWithIdentifier:(NSString *)identifier;

- (void)enable;
- (void)disable;
+ (BOOL)alphaShiftReleased:(NSTimeInterval)eventTime;
- (void)checkForModifierTap:(BOOL)modsAdded;

+ (BOOL)modifierToggled:(NSTimeInterval)eventTime;
- (NSUInteger) modifierActivationMask;
- (void)setModifierActivationMask:(NSUInteger)newModifierActivationMask;
- (void)sendAction;
@end
