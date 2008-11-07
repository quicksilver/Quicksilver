//
//  QSHotKeyTriggerManager.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on Sun Jun 13 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "QSHotKeyTriggerManager.h"
#import <QSInterface/QSHotKeyEditor.h>
#import <QSCore/QSTrigger.h>
#import <QSEffects/QSWindow.h>
#import <QSEffects/QSShading.h>
#import <QSFoundation/QSHotKeyEvent.h>

@implementation QSHotKeyTriggerManager

+ (void)initialize { [self setKeys:[NSArray arrayWithObject:@"currentTrigger"] triggerChangeNotificationsForDependentKey:@"hotKey"];  }

- (void)awakeFromNib { [self addObserver:self forKeyPath:@"currentTrigger" options:0 context:nil];  }

- (NSString *)name { return @"HotKey";  }

- (NSView *)settingsView {
	if (!settingsView)
		[NSBundle loadNibNamed:@"QSHotKeyTrigger" owner:self];
	return settingsView;
}

- (NSImage *)image { return [NSImage imageNamed:@"KeyboardTrigger"];  }

- (void)initializeTrigger:(NSMutableDictionary *)trigger { [trigger setObject:[NSNumber numberWithBool:YES] forKey:@"onPress"];  }

- (BOOL)hotKeyReleased:(QSHotKeyEvent *)hotKey { return NO;  }

- (BOOL)hotKeyPressed:(QSHotKeyEvent *)hotKey {
	BOOL result = NO;
	QSTrigger *trigger = [[NSClassFromString(@"QSTriggerCenter") sharedInstance] performSelector:@selector(triggerWithID:) withObject:[hotKey identifier]];

	QSWindow *window = nil;
	if ([[trigger objectForKey:@"showWindow"] boolValue]) {
		window = (QSWindow*)[self triggerDisplayWindowWithTrigger:trigger];
		[window setAlphaValue:0];
		[window reallyOrderFront:self];
		[window performEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"0.125", @"duration", @"QSGrowEffect", @"transformFn", @"show", @"type", nil]];
	}

	BOOL onPress = [[trigger objectForKey:@"onPress"] boolValue];
	BOOL onRelease = [[trigger objectForKey:@"onRelease"] boolValue];
	BOOL onRepeat = [[trigger objectForKey:@"onRepeat"] boolValue];

	if (!(onPress || onRepeat || onRelease) )
		onPress = YES;

	NSEvent *upEvent = nil;

	if ([[trigger objectForKey:@"delay"] boolValue]) {
		NSDate *delayDate = [NSDate dateWithTimeIntervalSinceNow:[[trigger objectForKey:@"delayInterval"] floatValue]];
		upEvent = [self nextHotKeyUpEventUntilDate:delayDate];
		if (upEvent) {
			[window performEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"0.125", @"duration", @"QSShrinkEffect", @"transformFn", @"hide", @"type", nil]];
			[window reallyOrderOut:self];
			return NO;
		}
	}

	if (onPress)
		[trigger execute];

	if (onRepeat) {
		float repeatInterval = [[trigger objectForKey:@"onRepeatInterval"] floatValue];
		NSDate *repeatDate = [NSDate dateWithTimeIntervalSinceNow:repeatInterval];
		while (!(upEvent = [self nextHotKeyUpEventUntilDate:repeatDate]) ) {
			repeatDate = [NSDate dateWithTimeIntervalSinceNow:repeatInterval];
			[trigger execute];
		}
	} else if (onRelease) {
		upEvent = [self nextHotKeyUpEventUntilDate:[NSDate distantFuture]];
	}
	if (onRelease && upEvent)
		[trigger execute];
	[window flare:self];
	[window reallyOrderOut:self];
	[window close];
	return result;
}
- (NSEvent *)nextHotKeyUpEventUntilDate:(NSDate *)date {
	NSEvent *event;
	while(1) {
		event = [NSApp nextEventMatchingMask:NSAnyEventMask untilDate:date inMode:NSDefaultRunLoopMode dequeue:YES];
		if ([event type] == NSSystemDefined && [event subtype] == 9) // A hotkey up event
			return event;
		else if (event)
			if (VERBOSE) NSLog(@"Foreign Event Ignored %@", event);
		else
			return nil;
	}
	return nil;
}


//@"showWindow"
//@"count"


- (BOOL)enableTrigger:(QSTrigger *)trigger {
	NSDictionary *entry = (NSDictionary*)[trigger info];
	if ([entry objectForKey:@"keyCode"]) {
		QSHotKeyEvent *activationKey = [QSHotKeyEvent getHotKeyForKeyCode:[[entry objectForKey:@"keyCode"] shortValue] character:([[entry objectForKey:@"characters"] length]) ? [[entry objectForKey:@"characters"] characterAtIndex:0] :0 safeModifierFlags:[[entry objectForKey:@"modifiers"] intValue]];

		[activationKey setTarget:self selectorReleased:@selector(hotKeyReleased:) selectorPressed:@selector(hotKeyPressed:)];
		[activationKey setIdentifier:[entry objectForKey:kItemID]];
		[activationKey setEnabled:YES];
		return YES;
	} else
		return NO;
}

- (BOOL)disableTrigger:(QSTrigger *)trigger {
	[[QSHotKeyEvent hotKeyWithIdentifier:[[trigger info] objectForKey:kItemID]] setEnabled:NO];
	return YES;
}

- (NSString *)descriptionForTrigger:(NSDictionary *)thisTrigger {
	if ([thisTrigger objectForKey:@"keyCode"] && [thisTrigger objectForKey:@"modifiers"])
		return [[QSHotKeyEvent getHotKeyForKeyCode:[[thisTrigger objectForKey:@"keyCode"] shortValue] character:0 safeModifierFlags:[[thisTrigger objectForKey:@"modifiers"] intValue]] stringValue];
	else
		return @"None";
}

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject {
	if (anObject == hotKeyField || ![anObject isDescendantOf:settingsView]) {
		id instance = [QSHotKeyFieldEditor sharedInstance];
		[instance setDelegate:anObject];
		return instance;
	} else
		return nil;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector { return NO;  }

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	[self willChangeValueForKey:@"hotKey"];
	[self didChangeValueForKey:@"hotKey"];
}

- (BOOL)shouldEditTrigger:(QSTrigger *)trigger { return NO;  }
- (void)triggerDoubleClicked:(QSTrigger *)trigger { [hotKeyField absorbEvents];  }

- (void)setHotKey:(NSDictionary *)dict {
	QSTrigger *trigger = [self currentTrigger];
	if (!dict || [[dict allKeys] count] == 0)
		[[trigger info] removeObjectsForKeys:[NSArray arrayWithObjects:@"modifiers", @"keyCode", @"character", nil]];
	else
		[[trigger info] addEntriesFromDictionary:dict];
	[[self currentTrigger] willChangeValueForKey:@"triggerDescription"];
	[[self currentTrigger] didChangeValueForKey:@"triggerDescription"];
	[self willChangeValueForKey:@"hotKey"];
	[self didChangeValueForKey:@"hotKey"];
	[[NSClassFromString(@"QSTriggerCenter") sharedInstance] performSelector:@selector(triggerChanged:) withObject:[self currentTrigger]];
}

- (NSDictionary *)hotKey {
	NSMutableDictionary *dict = [[[[self currentTrigger] info] dictionaryWithValuesForKeys:[NSArray arrayWithObjects:@"modifiers", @"keyCode", @"characters", nil]] mutableCopy];
	[dict removeObjectsForKeys:[dict allKeysForObject:[NSNull null]]];
	return [dict autorelease];
}

- (void)trigger:(QSTrigger *)trigger setTriggerDescription:(NSString *)description {
	NSDictionary *dict = [NSPropertyListSerialization propertyListFromData:[description dataUsingEncoding:NSUTF8StringEncoding] mutabilityOption:NSPropertyListImmutable format:nil errorDescription:nil];
	if (dict && [dict isKindOfClass:[NSDictionary class]]) {
		if ([[dict allKeys] count] == 0)
			[[trigger info] removeObjectsForKeys:[NSArray arrayWithObjects:@"modifiers", @"keyCode", @"character", nil]];
		else
			[[trigger info] addEntriesFromDictionary:dict];
		[[self currentTrigger] willChangeValueForKey:@"triggerDescription"];
		[[self currentTrigger] didChangeValueForKey:@"triggerDescription"];
		[self willChangeValueForKey:@"hotKey"];
		[self didChangeValueForKey:@"hotKey"];
		[[NSClassFromString(@"QSTriggerCenter") sharedInstance] performSelector:@selector(triggerChanged:) withObject:[self currentTrigger]];
	}
}

@end
