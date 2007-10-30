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

#import <QSFoundation/NDHotKeyEvent_QSMods.h>
@implementation QSHotKeyTriggerManager
+ (void)initialize{
    [self setKeys:[NSArray arrayWithObject:@"currentTrigger"] triggerChangeNotificationsForDependentKey:@"hotKey"];
    
}
-(void)awakeFromNib{
	[self addObserver:self
		   forKeyPath:@"currentTrigger"
			  options:0
			  context:nil];
	
}
-(NSString *)name{
	return @"HotKey";
}

- (NSView *) settingsView{
    if (!settingsView){
        [NSBundle loadNibNamed:@"QSHotKeyTrigger" owner:self];		
	}
    return [[settingsView retain] autorelease];
}

-(NSImage *)image{
	return [NSImage imageNamed:@"KeyboardTrigger"];
}
- (void)initializeTrigger:(NSMutableDictionary *)trigger{
	
	[trigger setObject:[NSNumber numberWithBool:YES] forKey:@"onPress"];
}

-(BOOL)hotKeyReleased:(QSHotKeyEvent *)hotKey{
	return NO;
}

-(BOOL)hotKeyPressed:(QSHotKeyEvent *)hotKey{
	BOOL result=NO;
	NSDate *triggerDate=[NSDate date];
	id center=[NSClassFromString(@"QSTriggerCenter") sharedInstance];
	QSTrigger *trigger=[[NSClassFromString(@"QSTriggerCenter") sharedInstance]triggerWithID:[hotKey identifier]];
	
	BOOL showStatus=[[trigger objectForKey:@"showWindow"]boolValue];
	
	NSWindow *window=nil;
	if (showStatus){
		window=[self triggerDisplayWindowWithTrigger:trigger];
		[window setAlphaValue:0];

		[window reallyOrderFront:self];
		[(QSWindow *)window performEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"0.125",@"duration",@"QSGrowEffect",@"transformFn",@"show",@"type",nil]];
		//[(QSWindow *)window reallyOrderOut:self];	
	}
	BOOL onPress=[[trigger objectForKey:@"onPress"]boolValue];
	BOOL onRelease=[[trigger objectForKey:@"onRelease"]boolValue];
	
	BOOL onRepeat=[[trigger objectForKey:@"onRepeat"]boolValue];
	float repeatInterval=[[trigger objectForKey:@"onRepeatInterval"]floatValue];
	
	BOOL delay=[[trigger objectForKey:@"delay"]boolValue];
	float delayInterval=[[trigger objectForKey:@"delayInterval"]floatValue];
	
	if (!(onPress || onRepeat || onRelease))onPress=YES;
	NSEvent *upEvent=nil;
	
	if (delay){
		NSDate *delayDate=[NSDate dateWithTimeIntervalSinceNow:delayInterval];
		
		//NSLog(@"Delay: %@",delayDate);
		upEvent=[self nextHotKeyUpEventUntilDate:delayDate];
		
		
		if (upEvent){
			[(QSWindow *)window performEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"0.125",@"duration",@"QSShrinkEffect",@"transformFn",@"hide",@"type",nil]];
			[(QSWindow *)window reallyOrderOut:self];
			return NO;
		}
		//	NSLog(@"Delayed: %@",delayDate);
	}
	
	if (onPress){
		//NSLog(@"press fire: %@",upEvent);
		[trigger execute];
	}
	
	if (onRepeat){
		NSDate *repeatDate=[NSDate dateWithTimeIntervalSinceNow:repeatInterval];	
		
		while (!(upEvent=[self nextHotKeyUpEventUntilDate:repeatDate])){ // While no HotKeyUp
																		 //NSLog(@"repeat fire: %@",repeatDate);
			repeatDate=[NSDate dateWithTimeIntervalSinceNow:repeatInterval];	
			[trigger execute];
		}
	}else if (onRelease){
		upEvent=[self nextHotKeyUpEventUntilDate:[NSDate distantFuture]];
	}
	if (onRelease && upEvent){
		//NSLog(@"release fire: %@",upEvent);
		[trigger execute];
	}
	
	//	[(QSWindow *)window performEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"0.25",@"duration",@"QS",@"transformFn",@"visible",@"type",nil]];
	[window flare:self];
	//[(QSWindow *)window performEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"0.25",@"duration",@"QSShrinkEffect",@"transformFn",@"hide",@"type",nil]];
	[(QSWindow *)window reallyOrderOut:self];
	[window close];
	return result;
}
- (NSEvent *)nextHotKeyUpEventUntilDate:(NSDate *)date{
	NSEvent *event;
	while(1){
		event=[NSApp nextEventMatchingMask:NSAnyEventMask untilDate:date inMode:NSDefaultRunLoopMode dequeue:YES];
		if ([event type]==NSSystemDefined && [event subtype]==9){ // A hotkey up event
			return event;
		}else if (event){
			if (VERBOSE) NSLog(@"Foreign Event Ignored %@",event);
		}else{
			return nil;
		}
	}
	return nil;
}


//@"showWindow"
//@"count"


-(BOOL)enableTrigger:(QSTrigger *)trigger{
	NSDictionary *entry=[trigger info];
	if (![entry objectForKey:@"keyCode"])return NO;
	//NSLog(@"enable %@",entry);
	
	QSHotKeyEvent *activationKey=(QSHotKeyEvent *)[QSHotKeyEvent getHotKeyForKeyCode:[[entry objectForKey:@"keyCode"] shortValue]
																		   character:[[entry objectForKey:@"characters"]length]?[[entry objectForKey:@"characters"]characterAtIndex:0]:NULL
																   safeModifierFlags:[[entry objectForKey:@"modifiers"] intValue]];
	
	
	
	[activationKey setTarget:self selectorReleased:@selector(hotKeyReleased:) selectorPressed:@selector(hotKeyPressed:)];
	[activationKey setIdentifier:[entry objectForKey:kItemID]];
	[activationKey setEnabled:YES];
	
	//	NSLog(@"%@ %@",activationKey,[activationKey identifier]);
	
    return YES;
}

-(BOOL)disableTrigger:(QSTrigger *)trigger{
	
	NSDictionary *entry=[trigger info];
    NSString *theID=[entry objectForKey:kItemID];
	
	QSHotKeyEvent *hotKey=[QSHotKeyEvent hotKeyWithIdentifier:theID];
	
	[hotKey setEnabled:NO];
	
    return YES;
}



- (NSString *)descriptionForTrigger:(NSDictionary *)thisTrigger{
	if ([thisTrigger objectForKey:@"keyCode"] &&[thisTrigger objectForKey:@"modifiers"]){
		QSHotKeyEvent *activationKey=(QSHotKeyEvent *)[QSHotKeyEvent getHotKeyForKeyCode:[[thisTrigger objectForKey:@"keyCode"] shortValue]
																			   character:0
																	   safeModifierFlags:[[thisTrigger objectForKey:@"modifiers"] intValue]];
		return [activationKey stringValue];
	
	}
	//	return [ KeyCombo keyComboWithKeyCode:[[thisTrigger objectForKey:@"keyCode"]shortValue]
	//							 andModifiers:[[thisTrigger objectForKey:@"modifiers"]longValue]];
	return @"None";
}

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject{
	if (anObject==hotKeyField || ![anObject isDescendantOf:settingsView]){
		id instance=[QSHotKeyFieldEditor sharedInstance];
		[instance setDelegate:anObject];
		return instance;
	}
	return nil;
}
- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor 
                                    doCommandBySelector:(SEL)commandSelector {
	//NSLog(@"%@ %@",fieldEditor, NSStringFromSelector(commandSelector));
	return NO;
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification{
	[self setHotKey:[[aNotification object]stringValue]];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	[self willChangeValueForKey:@"hotKey"];
				[self didChangeValueForKey:@"hotKey"];
}

- (BOOL)shouldEditTrigger:(QSTrigger *)trigger{
	return NO;
}
- (void)triggerDoubleClicked:(QSTrigger *)trigger{
	[hotKeyField absorbEvents];
}

- (void)setHotKey:(NSDictionary *)dict{
	
	QSTrigger *trigger=[self currentTrigger];
	if (!dict || [[dict allKeys]count]==0){
		
		[[trigger info] removeObjectsForKeys:[NSArray arrayWithObjects:@"modifiers",@"keyCode",@"character",nil]];
	}else{
		[[trigger info] addEntriesFromDictionary:dict];
	}
	[[self currentTrigger]setEnabled:YES];
	[[self currentTrigger]willChangeValueForKey:@"triggerDescription"];
	[[self currentTrigger]didChangeValueForKey:@"triggerDescription"];
	[self willChangeValueForKey:@"hotKey"];
	[self didChangeValueForKey:@"hotKey"];
	[[NSClassFromString(@"QSTriggerCenter") sharedInstance] triggerChanged:[self currentTrigger]];
}

- (NSDictionary *)hotKey{
	NSMutableDictionary *dict=[[[self currentTrigger]info]dictionaryWithValuesForKeys:[NSArray arrayWithObjects:@"modifiers",@"keyCode",@"characters",nil]];
	dict=[[dict mutableCopy]autorelease];
	[dict removeObjectsForKeys:[dict allKeysForObject:[NSNull null]]];
	return dict;
}

- (void)trigger: (QSTrigger *)trigger setTriggerDescription:(NSString *)description;
{
	
	NSDictionary *dict=[NSPropertyListSerialization propertyListFromData:[description dataUsingEncoding:NSUTF8StringEncoding] mutabilityOption:NSPropertyListImmutable format:nil errorDescription:nil]; 
	//NSLog(@"description '%@'",description);
	if (!dict)return;
	if ([dict isKindOfClass:[NSDictionary class]]){
		if (dict && [[dict allKeys]count]==0){
			//NSLog(@"Deleting hotkey %@",[dict allValues]);
			[[trigger info] removeObjectsForKeys:[NSArray arrayWithObjects:@"modifiers",@"keyCode",@"character",nil]];
		}else{
			//NSLog(@"Setting hotkey %@",[dict allValues]);
			[[trigger info] addEntriesFromDictionary:dict];
		}
		[[self currentTrigger]willChangeValueForKey:@"triggerDescription"];
		[[self currentTrigger]didChangeValueForKey:@"triggerDescription"];
		[self willChangeValueForKey:@"hotKey"];
		[self didChangeValueForKey:@"hotKey"];
		[[NSClassFromString(@"QSTriggerCenter") sharedInstance] triggerChanged:[self currentTrigger]];
	}
}

@end

