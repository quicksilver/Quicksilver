//
//  QSModifierKeyHandler.m
//  Quicksilver
//
//  Created by disterics on 07/12/2009.
//

#import "QSModifierKeyHandler.h"
#import "QSKeyMap.h"
#import "GTMCarbonEvent.h"
#import "GTMObjectSingleton.h"

@interface NSEvent (QuickSilverEventAdditions)

- (NSUInteger)qsModifierFlags;

@end
 
static const EventTypeSpec kModifierEventTypeSpec[] 
  = { { kEventClassKeyboard, kEventRawKeyModifiersChanged } };
static const size_t kModifierEventTypeSpecSize 
  = sizeof(kModifierEventTypeSpec) / sizeof(EventTypeSpec);


@implementation QSModifierKeyHandler

GTMOBJECT_SINGLETON_BOILERPLATE(QSModifierKeyHandler, sharedModifierKeyHandler);


- (id)init {
    if (self = [super init]) {
	if (DEBUG_STARTUP) NSLog(@"KeyHandler Init");
    }
    return self;
}


- (void) dealloc {
    [identifier release];
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
    // If we aren't activated by hotmodifiers, we don't want to be here
    // and if we are in the process of activating, we want to ignore the hotkey
    // so we don't try to process it twice.
    if (!hotModifiers_ || [NSApp keyWindow]) 
	return;

    NSUInteger flags = [event qsModifierFlags];
    // is the modifier we are looking for
    if (flags != hotModifiers_) return;
    const useconds_t oneMilliSecond = 10000;
    UInt16 modifierKeys[] = {
	0,
	kVK_Shift,
	kVK_CapsLock,
	kVK_RightShift,
    };
  
    if (hotModifiers_ == NSControlKeyMask) {
	modifierKeys[0] = kVK_Control;
    } else if (hotModifiers_ == NSAlternateKeyMask) {
	modifierKeys[0]  = kVK_Option;
    } else if (hotModifiers_ == NSCommandKeyMask) {
	modifierKeys[0]  = kVK_Command;
    }

    QSKeyMap *hotMap = [[[QSKeyMap alloc] initWithKeys:modifierKeys
					  count:1] autorelease];
    QSKeyMap *invertedHotMap
	= [[[QSKeyMap alloc] initWithKeys:modifierKeys
			     count:sizeof(modifierKeys) / sizeof(UInt16)]
	      autorelease];
    invertedHotMap = [invertedHotMap keyMapByInverting];
    NSTimeInterval startDate = [NSDate timeIntervalSinceReferenceDate];
    BOOL isGood = NO;
    // check if our modifier was released
    while(([NSDate timeIntervalSinceReferenceDate] - startDate) < [self doubleClickTime]) {
	QSKeyMap *currentKeyMap = [QSKeyMap currentKeyMap];
	if ([currentKeyMap containsAnyKeyIn:invertedHotMap]
	    || GetCurrentButtonState()) {
	    return;
	}

	if (![currentKeyMap containsAnyKeyIn:hotMap]) {
	    // Key released;
	    isGood = YES;
	    break;
	}
	usleep(oneMilliSecond);
    }

    if (!isGood) return;
    startDate = [NSDate timeIntervalSinceReferenceDate];
    isGood = NO;
    // check if our modifier key is pressed again 
    while(([NSDate timeIntervalSinceReferenceDate] - startDate) < [self doubleClickTime]) {
	QSKeyMap *currentKeyMap = [QSKeyMap currentKeyMap];
	if ([currentKeyMap containsAnyKeyIn:invertedHotMap]
	    || GetCurrentButtonState()) {
	    return;
	}
	if ([currentKeyMap containsAnyKeyIn:hotMap]) {
	    // Key down
	    isGood = YES;
	    break;
	}
	usleep(oneMilliSecond);
    }
    if (!isGood) return;
  
    startDate = [NSDate timeIntervalSinceReferenceDate];

    // and now look for the release of the second tap 
    while(([NSDate timeIntervalSinceReferenceDate] - startDate)
	  < [self doubleClickTime]) {
	QSKeyMap *currentKeyMap = [QSKeyMap currentKeyMap];
	if ([currentKeyMap containsAnyKeyIn:invertedHotMap]) {
	    return;
	}
	if (![currentKeyMap containsAnyKeyIn:hotMap]) {
	    // Key Released
	    isGood = YES;
	    break;
	}
	usleep(oneMilliSecond);
    }

    if (isGood) {
	// Houston - we have liftoff
	[self sendAction];
    }
}

- (void)modifiersChangedWhileActive:(NSEvent*)event {
    // A statemachine that tracks our state via hotModifiersState_.
    // Simple incrementing state.
    if (!hotModifiers_) {
	return;
    }
    NSTimeInterval timeWindowToRespond
	= lastHotModifiersEventCheckedTime_ + [self doubleClickTime];
    lastHotModifiersEventCheckedTime_ = [event timestamp];
    if (hotModifiersState_
	&& lastHotModifiersEventCheckedTime_ > timeWindowToRespond) {
	// Timed out. Reset.
	hotModifiersState_ = 0;
	return;
    }

    NSUInteger flags = [event qsModifierFlags];
    BOOL isGood = NO;
    if (!(hotModifiersState_ % 2)) {
	// This is key down cases
	isGood = (flags == hotModifiers_);
    } 
    else {
	// This is key up cases
	isGood = (flags == 0);
    }
    if (!isGood) {
	// reset
	hotModifiersState_ = 0;
	return;
    } 
    else {
	hotModifiersState_ += 1;
    }
    if (hotModifiersState_ == 3) {
	// We've worked our way through the state machine to success!
	[self sendAction];
    }
}

// method that is called when a key changes state and we are active
- (void)keysChangedWhileActive:(NSEvent*)event {
    // we should never hit this method.
    if (!hotModifiers_) return;
    hotModifiersState_ = 0;
}


- (void)setModifierActivationMask:(NSUInteger)value {
    
    hotModifiers_ = (1 << value);
    if (VERBOSE) {

	switch (hotModifiers_) {
	case NSCommandKeyMask:
	    NSLog(@"Using command key : ");
	    break;
	case NSAlternateKeyMask:
	    NSLog(@"Using option key");
	    break;
	case NSControlKeyMask:
	    NSLog(@"Using control key");
	    break;
	case NSShiftKeyMask:
	    NSLog(@"Using shift key");
	    break;
	case NSFunctionKeyMask:
	    NSLog(@"Using function key");
	    break;
	case NSAlphaShiftKeyMask:
	    NSLog(@"Using caps lock");
	    break;
	default:
	    NSLog(@"unknown mod");
	}
    }
}

- (unsigned int)modifierActivationMask { return hotModifiers_; }

- (int)modifierActivationCount { return modifierActivationCount; }
- (void)setModifierActivationCount:(NSUInteger)newModifierActivationCount {
    modifierActivationCount = newModifierActivationCount;
}

- (id)target { return target; }
- (void)setTarget:(id)newTarget {
    if (target != newTarget) {
	[target release];
	target = [newTarget retain];
    }
}

- (SEL) action { return action; }
- (void)setAction:(SEL)newAction {
    action = newAction;
}

- (NSString *)identifier { return identifier; }
- (void)setIdentifier:(NSString *)newIdentifier {
    if (identifier != newIdentifier) {
	[identifier release];
	identifier = [newIdentifier retain];
    }
}

- (void)sendAction {
    [target performSelector:action];
}

// Returns the amount of time between two clicks to be considered a double click
- (NSTimeInterval)doubleClickTime {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSTimeInterval doubleClickThreshold
    = [defaults doubleForKey:@"com.apple.mouse.doubleClickThreshold"];

  // if we couldn't find the value in the user defaults, take a
  // conservative estimate
  if (doubleClickThreshold <= 0.0) {
    doubleClickThreshold = 1.0;
  }
  return doubleClickThreshold;
}

- (void)enable {
    GTMCarbonEventMonitorHandler *handler = [GTMCarbonEventMonitorHandler sharedEventMonitorHandler];
    [handler registerForEvents:kModifierEventTypeSpec 
	     count:kModifierEventTypeSpecSize];
    [handler setDelegate:self];
}

- (void)disable {
    GTMCarbonEventMonitorHandler *handler 
	= [GTMCarbonEventMonitorHandler sharedEventMonitorHandler];
    [handler unregisterForEvents:kModifierEventTypeSpec 
	     count:kModifierEventTypeSpecSize];
    [handler setDelegate:nil];
}


@end

@implementation NSEvent (QuickSilverEventAdditions)
/**
 * Remove caps lock and numeric loc
 */
- (NSUInteger)qsModifierFlags {
    NSUInteger flags
	= ([self modifierFlags] & NSDeviceIndependentModifierFlagsMask);
    // if (flags & NSAlphaShiftKeyMask) flags -= NSAlphaShiftKeyMask;
    if (flags & NSNumericPadKeyMask) flags -= NSNumericPadKeyMask;
    return flags;
}

@end
