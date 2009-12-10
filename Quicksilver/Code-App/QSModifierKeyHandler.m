//
//  QSModifierKeyHandler.m
//  Quicksilver
//
//  Created by disterics on 07/12/2009.
//

#import "QSModifierKeyHandler.h"
#import "GTMCarbonEvent.h"

static const EventTypeSpec kModifierEventTypeSpec[] 
  = { { kEventClassKeyboard, kEventRawKeyModifiersChanged } };
static const size_t kModifierEventTypeSpecSize 
  = sizeof(kModifierEventTypeSpec) / sizeof(EventTypeSpec);

@interface QSModifierKeyHandler (Private)
-(void) registerForGlobalModifiers; 
@end
 


@implementation QSModifierKeyHandler

+ (void) initialize {
    //	[self registerForGlobalModifiers];
}

- (void) registerForGlobalModifiers {
    GTMCarbonEventMonitorHandler *handler = [GTMCarbonEventMonitorHandler sharedEventMonitorHandler];
    [handler registerForEvents:kModifierEventTypeSpec 
	     count:kModifierEventTypeSpecSize];
    [handler setDelegate:self];
}

- (id)init {
    if (self = [super init]) {
	if (DEBUG_STARTUP) NSLog(@"KeyHandler Init");
	[self registerForGlobalModifiers];
    }
    return self;
}


- (void) dealloc {
    GTMCarbonEventMonitorHandler *handler 
	= [GTMCarbonEventMonitorHandler sharedEventMonitorHandler];
    [handler unregisterForEvents:kModifierEventTypeSpec 
	     count:kModifierEventTypeSpecSize];
    [handler setDelegate:nil];
     [super dealloc];
}

- (OSStatus)gtm_eventHandler:(GTMCarbonEventHandler *)sender 
               receivedEvent:(GTMCarbonEvent *)event 
                     handler:(EventHandlerCallRef)handler {
    OSStatus status = eventNotHandledErr;
    if ([event eventClass] == kEventClassKeyboard &&
	[event eventKind] == kEventRawKeyModifiersChanged) {
	UInt32 modifiers;
	if ([event getUInt32ParameterNamed:kEventParamKeyModifiers
		   data:&modifiers]) {
	    NSUInteger cocoaMods = GTMCarbonToCocoaKeyModifiers(modifiers);
	    NSEvent *nsEvent = [NSEvent keyEventWithType:NSFlagsChanged
					location:[NSEvent mouseLocation]
					modifierFlags:cocoaMods
					timestamp:[event time]
					windowNumber:0
					context:nil
                                        characters:nil
					charactersIgnoringModifiers:nil
					isARepeat:NO
					keyCode:0];
	    [self modifiersChangedWhileInactive:nsEvent];
	}
    }
    return status;
}



// method that is called when the modifier keys are hit and we are inactive
- (void)modifiersChangedWhileInactive:(NSEvent*)event {
    NSLog(@"modifiers changed while inactive");
//   // If we aren't activated by hotmodifiers, we don't want to be here
//   // and if we are in the process of activating, we want to ignore the hotkey
//   // so we don't try to process it twice.
//   if (!hotModifiers_ || [NSApp keyWindow]) return;

//   NSUInteger flags = [event qsbModifierFlags];
//   if (flags != hotModifiers_) return;
//   const useconds_t oneMilliSecond = 10000;
//   UInt16 modifierKeys[] = {
//     0,
//     kVK_Shift,
//     kVK_CapsLock,
//     kVK_RightShift,
//   };
//   if (hotModifiers_ == NSControlKeyMask) {
//     modifierKeys[0] = kVK_Control;
//   } else if (hotModifiers_ == NSAlternateKeyMask) {
//     modifierKeys[0]  = kVK_Option;
//   } else if (hotModifiers_ == NSCommandKeyMask) {
//     modifierKeys[0]  = kVK_Command;
//   }
//   QSBKeyMap *hotMap = [[[QSBKeyMap alloc] initWithKeys:modifierKeys
//                                                count:1] autorelease];
//   QSBKeyMap *invertedHotMap
//     = [[[QSBKeyMap alloc] initWithKeys:modifierKeys
//                                 count:sizeof(modifierKeys) / sizeof(UInt16)]
//        autorelease];
//   invertedHotMap = [invertedHotMap keyMapByInverting];
//   NSTimeInterval startDate = [NSDate timeIntervalSinceReferenceDate];
//   BOOL isGood = NO;
//   while(([NSDate timeIntervalSinceReferenceDate] - startDate)
//         < [self doubleClickTime]) {
//     QSBKeyMap *currentKeyMap = [QSBKeyMap currentKeyMap];
//     if ([currentKeyMap containsAnyKeyIn:invertedHotMap]
//         || GetCurrentButtonState()) {
//       return;
//     }
//     if (![currentKeyMap containsAnyKeyIn:hotMap]) {
//       // Key released;
//       isGood = YES;
//       break;
//     }
//     usleep(oneMilliSecond);
//   }
//   if (!isGood) return;
//   isGood = NO;
//   startDate = [NSDate timeIntervalSinceReferenceDate];
//   while(([NSDate timeIntervalSinceReferenceDate] - startDate)
//         < [self doubleClickTime]) {
//     QSBKeyMap *currentKeyMap = [QSBKeyMap currentKeyMap];
//     if ([currentKeyMap containsAnyKeyIn:invertedHotMap]
//         || GetCurrentButtonState()) {
//       return;
//     }
//     if ([currentKeyMap containsAnyKeyIn:hotMap]) {
//       // Key down
//       isGood = YES;
//       break;
//     }
//     usleep(oneMilliSecond);
//   }
//   if (!isGood) return;
//   startDate = [NSDate timeIntervalSinceReferenceDate];
//   while(([NSDate timeIntervalSinceReferenceDate] - startDate)
//         < [self doubleClickTime]) {
//     QSBKeyMap *currentKeyMap = [QSBKeyMap currentKeyMap];
//     if ([currentKeyMap containsAnyKeyIn:invertedHotMap]) {
//       return;
//     }
//     if (![currentKeyMap containsAnyKeyIn:hotMap]) {
//       // Key Released
//       isGood = YES;
//       break;
//     }
//     usleep(oneMilliSecond);
//   }
//   if (isGood) {
//     [self hitHotKey:self];
//   }
}

- (void)modifiersChangedWhileActive:(NSEvent*)event {
    NSLog(@"modifiers changed while active");
  // A statemachine that tracks our state via hotModifiersState_.
  // Simple incrementing state.
//   if (!hotModifiers_) {
//     return;
//   }
//   NSTimeInterval timeWindowToRespond
//     = lastHotModifiersEventCheckedTime_ + [self doubleClickTime];
//   lastHotModifiersEventCheckedTime_ = [event timestamp];
//   if (hotModifiersState_
//       && lastHotModifiersEventCheckedTime_ > timeWindowToRespond) {
//     // Timed out. Reset.
//     hotModifiersState_ = 0;
//     return;
//   }
//   NSUInteger flags = [event qsbModifierFlags];
//   BOOL isGood = NO;
//   if (!(hotModifiersState_ % 2)) {
//     // This is key down cases
//     isGood = flags == hotModifiers_;
//   } else {
//     // This is key up cases
//     isGood = flags == 0;
//   }
//   if (!isGood) {
//     // reset
//     hotModifiersState_ = 0;
//     return;
//   } else {
//     hotModifiersState_ += 1;
//   }
//   if (hotModifiersState_ == 3) {
//     // We've worked our way through the state machine to success!
//     [self hitHotKey:self];
//   }
}

// method that is called when a key changes state and we are active
- (void)keysChangedWhileActive:(NSEvent*)event {
//   if (!hotModifiers_) return;
//   hotModifiersState_ = 0;
    NSLog(@"keys changed while inactive");
}



@end
