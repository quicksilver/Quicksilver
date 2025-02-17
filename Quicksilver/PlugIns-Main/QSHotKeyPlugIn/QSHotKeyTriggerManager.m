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

// KVO
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    
    if ([key isEqualToString:@"hotKey"]) {
        keyPaths = [keyPaths setByAddingObject:@"currentTrigger"];
    }
    return keyPaths;
}

- (void)awakeFromNib { [self addObserver:self forKeyPath:@"currentTrigger" options:0 context:nil];
    [self addObserver:self forKeyPath:@"hotKey" options:0 context:nil];}

- (NSString *)name { return @"Keyboard";  }

- (NSView *)settingsView {
	if (!settingsView)
		[NSBundle loadNibNamed:@"QSHotKeyTrigger" owner:self];
	return settingsView;
}

- (NSImage *)image { return [QSResourceManager imageNamed:@"KeyboardTrigger"];  }

- (void)initializeTrigger:(NSMutableDictionary *)trigger { [trigger setObject:[NSNumber numberWithBool:YES] forKey:@"onPress"];  }

- (BOOL)hotKeyReleased:(QSHotKeyEvent *)hotKey {
    hotKeyPressed = NO;
    return NO;
}

- (BOOL)hotKeyPressed:(QSHotKeyEvent *)hotKey {
    hotKeyPressed = YES;
    
    NSArray *triggers = [[NSClassFromString(@"QSTriggerCenter") sharedInstance] performSelector:@selector(triggersWithIDs:) withObject:[hotKey identifiers]];
    for (QSTrigger *trigger in triggers) {
        if (![trigger activated]) {
            continue;
        }
        // let's try doing all of this on a background thread then shall we
        
        QSGCDAsync(^{
            BOOL triggerExecuted = NO;
            BOOL result;
            __block NSEvent *upEvent = nil;
            
            result = NO;
            __block QSWindow *window = nil;
            if ([[trigger objectForKey:@"showWindow"] boolValue]) {
                QSGCDMainAsync(^{
                    window = (QSWindow*)[self triggerDisplayWindowWithTrigger:trigger];
                    [window setAlphaValue:0];
                    [window reallyOrderFront:self];
                    [window performEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"0.125", @"duration", @"QSGrowEffect", @"transformFn", @"show", @"type", nil]];
                });
                
            }
            
            BOOL onPress = [[trigger objectForKey:@"onPress"] boolValue];
            BOOL onRelease = [[trigger objectForKey:@"onRelease"] boolValue];
            BOOL onRepeat = [[trigger objectForKey:@"onRepeat"] boolValue];
            
            if (!(onPress || onRepeat || onRelease) )
                onPress = YES;
            
            if ([[trigger objectForKey:@"delay"] boolValue]) {
                NSDate *delayDate = [NSDate dateWithTimeIntervalSinceNow:[[trigger objectForKey:@"delayInterval"] doubleValue]];
                //            wait until 'delayDate' and see if the 'hotKeyPressed' is now set to NO
                upEvent = [self nextHotKeyUpEventUntilDate:delayDate];
                if (upEvent || !self->hotKeyPressed) {
                    if (window) {
                        QSGCDMainSync(^{
                            [window performEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"0.125", @"duration", @"QSShrinkEffect", @"transformFn", @"hide", @"type", nil] completionHandler:^{
                                [window reallyOrderOut:self];
                                [window close];
                            }];
                        });
                        
                    }
                    result = YES;
                }
            }
            
            if (onPress && !result) {
                [trigger execute];
                triggerExecuted = YES;
            }
            
            if (onRepeat) {
                if ([trigger objectForKey:@"onRepeatInterval"] == nil) {
                    QSShowAppNotifWithAttributes(@"TriggerError", NSLocalizedString(@"Trigger Repeat Failure", @"Title of the notif when a 'repeat' trigger fails (interval not set)"), NSLocalizedString(@"Repeat interval not set", @"Message of 'trigger interval not set' error notif"));
                } else {
                    CGFloat repeatInterval = [[trigger objectForKey:@"onRepeatInterval"] doubleValue];
                    while (self->hotKeyPressed) {
                        NSDate *repeatDate = [NSDate dateWithTimeIntervalSinceNow:repeatInterval];
                        if (upEvent = [self nextHotKeyUpEventUntilDate:repeatDate]) {
                            break;
                        }
                        [trigger execute];
                        triggerExecuted = YES;
                    }
                }
            } else if (onRelease) {
                upEvent = [self nextHotKeyUpEventUntilDate:[NSDate distantFuture]];
            }
            if (onRelease && upEvent) {
                [trigger execute];
                triggerExecuted = YES;
            }
            if (triggerExecuted) {
                QSGCDMainSync(^{
                    [window performEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"0.125", @"duration", @"QSFlareEffect", @"transformFn", @"hide", @"type", nil] completionHandler:^{
                        [window reallyOrderOut:self];
                        [window close];
                    }];
                });
 
            }
            if (!triggerExecuted) {
                [hotKey typeHotkey];
            }
        });
    }
    return YES;// this isn't actually used by anything, so it doesn't matter what we return
}

- (NSEvent *)nextHotKeyUpEventUntilDate:(NSDate *)date {
    __block NSEvent *upEvent = nil;
    // this is such a hack. Does it work properly?
    while ([[NSDate date] isLessThan:date] && hotKeyPressed) {
        QSGCDMainSync(^{
            upEvent = [NSApp nextEventMatchingMask:NSEventMaskKeyUp untilDate:[NSDate dateWithTimeIntervalSinceNow:0.08] inMode:NSDefaultRunLoopMode dequeue:YES];
        });
        CFRunLoopRun();
        if (upEvent) {
            break;
        }
    }
    return upEvent;
}


//@"showWindow"
//@"count"


- (BOOL)enableTrigger:(QSTrigger *)trigger {
	NSDictionary *entry = (NSDictionary*)[trigger info];
	if ([entry objectForKey:@"keyCode"]) {
		QSHotKeyEvent *activationKey = [QSHotKeyEvent getHotKeyForKeyCode:[[entry objectForKey:@"keyCode"] unsignedShortValue] modifierFlags:[[entry objectForKey:@"modifiers"] integerValue]];

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
		return [[QSHotKeyEvent getHotKeyForKeyCode:[[thisTrigger objectForKey:@"keyCode"] unsignedShortValue] modifierFlags:[[thisTrigger objectForKey:@"modifiers"] unsignedLongValue]] stringValue];
	else
		return NSLocalizedString(@"None", @"text to display when a keyboard trigger doesn't have a shortcut set");
}

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject {
	if (anObject == hotKeyField) {
		id instance = [QSHotKeyFieldEditor sharedInstance];
		[instance setDelegate:anObject];
		return instance;
	} else
		return nil;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector { return NO;  }

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (![keyPath isEqualToString:@"hotKey"]) {

	[self willChangeValueForKey:@"hotKey"];
	[self didChangeValueForKey:@"hotKey"];
    }
}

- (BOOL)shouldEditTrigger:(QSTrigger *)trigger { return NO;  }
- (void)triggerDoubleClicked:(QSTrigger *)trigger { [hotKeyField absorbEvents];  }

- (void)setHotKey:(NSDictionary *)dict {
	QSTrigger *trigger = [self currentTrigger];
	if (!dict || [[dict allKeys] count] == 0) {
		[[trigger info] removeObjectsForKeys:[NSArray arrayWithObjects:@"modifiers", @"keyCode", @"character", nil]];
    } else {
		[[trigger info] addEntriesFromDictionary:dict];
    }

    // This KVC call to 'triggerDescription' sets the new hotKey
	[[self currentTrigger] willChangeValueForKey:@"triggerDescription"];
	[self willChangeValueForKey:@"hotKey"];
	[[NSClassFromString(@"QSTriggerCenter") sharedInstance] performSelector:@selector(triggerChanged:) withObject:[self currentTrigger]];
	[[self currentTrigger] didChangeValueForKey:@"triggerDescription"];
	[self didChangeValueForKey:@"hotKey"];
}

- (NSDictionary *)hotKey {
	NSMutableDictionary *dict = [[[[self currentTrigger] info] dictionaryWithValuesForKeys:[NSArray arrayWithObjects:@"modifiers", @"keyCode", @"characters", nil]] mutableCopy];
	[dict removeObjectsForKeys:[dict allKeysForObject:[NSNull null]]];
	return dict;
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
