//
//  QSModifierKeyHandler.h
//  Quicksilver
//
//  Created by disterics on 07/12/2009.
//

#import <Cocoa/Cocoa.h>


@interface QSModifierKeyHandler : NSObject {

@private
    EventHotKeyRef hotKey_;  // the hot key we're looking for. 
    NSUInteger hotModifiers_;  // if we are getting double taps, the mods to look for.
    NSUInteger hotModifiersState_;
    NSTimeInterval lastHotModifiersEventCheckedTime_;
    NSUInteger modifierActivationCount;
    NSString *identifier;
    id target;
    SEL action;

}

// Accessor to get the QSModifierKeyHandler singleton.
//
// Returns:
//  pointer to the GTMCarbonEventMonitorHandler singleton.
+ (QSModifierKeyHandler *)sharedModifierKeyHandler;

// method that is called when the modifier keys are hit and we are inactive
- (void)modifiersChangedWhileInactive:(NSEvent*)event;

// method that is called when the modifier keys are hit and we are active
- (void)modifiersChangedWhileActive:(NSEvent*)event;

// method that is called when a key changes state and we are active
- (void)keysChangedWhileActive:(NSEvent*)event;

- (unsigned int) modifierActivationMask;
- (void)setModifierActivationMask:(NSUInteger)newModifierActivationMask;
- (int) modifierActivationCount;
- (void)setModifierActivationCount:(NSUInteger)newModifierActivationCount;
- (id)target;
- (void)setTarget:(id)newTarget;
- (SEL) action;
- (void)setAction:(SEL)newAction;
- (NSString *)identifier;
- (void)setIdentifier:(NSString *)newIdentifier;
- (void)sendAction;
- (NSTimeInterval)doubleClickTime;
- (void)enable;
- (void)disable;

@end
