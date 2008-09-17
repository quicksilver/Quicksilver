//
// QSTrigger.m
// Quicksilver
//
// Created by Alcor on 6/19/05.
// Copyright 2005 Blacktree, Inc. All rights reserved.
//

#import "QSTriggersPrefPane.h"

#import "QSTrigger.h"
#import "QSTriggerCenter.h"
#import "QSCommand.h"
#import "QSRegistry.h"

@implementation QSTrigger
+ (void)initialize {
	[self setKeys:[NSArray arrayWithObject:@"command"] triggerChangeNotificationsForDependentKey:@"name"];
	[self setKeys:[NSArray arrayWithObjects:@"name", @"icon", nil] triggerChangeNotificationsForDependentKey:@"imageAndText"];
}

+ (id)triggerWithInfo:(NSDictionary *)dict {
    return [self triggerWithDictionary:dict];
}

+ (id)triggerWithDictionary:(NSDictionary *)dict {
	return [[[self alloc] initWithDictionary:dict] autorelease];
}

- (id)initWithInfo:(NSDictionary *)dict {
    return [self initWithDictionary:dict];
}

- (id)initWithDictionary:(NSDictionary *)dict {
	self = [super init];
	if (self != nil) {
		info = [dict mutableCopy];
	}
	return self;
}

- (id)init {
	self = [super init];
	if (self != nil) {
		info = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc {
	NSLog(@"dealloc %@", self);
    [command release];
	[info release];
	[children release];
	[super dealloc];
}

- (NSString *)identifier {
	return [info objectForKey:kItemID];
}

- (BOOL)isGroup {
	return [[self type] isEqualToString:@"QSGroupTrigger"];
}

- (NSImage *)smallIcon {
	if ([[self type] isEqualToString:@"QSGroupTrigger"]) {
		return [[self manager] image];
	} else {
		[[self command] loadIcon];
		NSImage *icon = [[self command] icon];
		[icon setFlipped:NO];
		[icon setSize:QSSize16];
		return icon;
	}
}

- (NSString *)name {
	NSString *name = [info objectForKey:@"name"];
	if (!name)
		name = [[self command] name];
	return name;
}

- (BOOL)hasCustomName {
	if ([self isPreset]) return NO;
	return [info objectForKey:@"name"] != nil;
}

- (void)setName:(NSString *)name {
	if (![name length]) {
		[info removeObjectForKey:@"name"];
	} else if (name) {
		[info setObject:name forKey:@"name"];
	}
}
- (NSString *)type {
	NSString *type = [info objectForKey:@"type"];
	if (type)
		return type;
	[self setType:@"QSHotKeyTrigger"];
	return @"QSHotKeyTrigger";
}

- (void)setType:(NSString *)type {
	BOOL wasEnabled = [self enabled];
	if (wasEnabled)
		[self setEnabled:NO];
	[info setObject:type forKey:@"type"];
	[self initializeTrigger];
	[[QSTriggerCenter sharedInstance] triggerChanged:self];
	if (wasEnabled)
		[self setEnabled:YES];
}

- (void)initializeTrigger {
	[[self manager] initializeTrigger:self];
}

- (void)rescope:(NSString *)ident {
	int scoped = [[info objectForKey:@"applicationScopeType"] intValue];
	if (!scoped) return;
	NSArray *apps = [info objectForKey:@"applicationScope"];
	BOOL shouldActivate = [apps containsObject:ident];
	if (scoped<0) shouldActivate = !shouldActivate;

	[self setActivated:shouldActivate];
}

- (BOOL)execute {
	[[self command] executeIgnoringModifiers];
	if ([info objectForKey:@"oneshot"]) {
		[self disable];
	}
	return YES;
}

- (void)setCommand:(QSCommand*)newCommand {
    if (newCommand != command) {
        [command release];
        command = [newCommand retain];
    }
}

- (QSCommand *)command {
    if (command)
        return command;
    
	id archivedCommand = [info objectForKey:@"command"];
    if (archivedCommand)
        command = [[QSCommand commandWithInfo:archivedCommand] retain];
	return command;
}

- (NSArray *)commands {
    NSArray * array = nil;
    QSCommand * aCommand = [self command];
    
    if (aCommand != nil)
        array = [NSArray arrayWithObject:aCommand];
    
	return array;
}

- (BOOL)isPreset {
	return [[info objectForKey:kItemID] hasPrefix:@"QS"];
}

- (BOOL)usesPresetCommand {
	return ([[info objectForKey:@"command"] isKindOfClass:[NSString class]]);
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dict = [info mutableCopy];
    id rep = nil;
    if ([self usesPresetCommand]) {
		rep = [[self command] identifier];
    } else {
        rep = [[self command] objectForType:QSCommandType];
    }
    if (rep)
        [dict setObject:rep forKey:@"command"];
    else
        [dict removeObjectForKey:@"command"];
	return [dict autorelease];
}

- (NSString *)triggerDescription {
	return [[self manager] descriptionForTrigger:self];
}
- (void)setTriggerDescription:(NSString *)description {
	[[self manager] trigger:self setTriggerDescription:description];
}

- (NSString *)description {
	return [[self command] description];
}

- (id)manager {
	return [QSReg instanceForKey:[info objectForKey:@"type"] inTable:QSTriggerManagers];
}

- (void)tryToActivate {
	[self setActivated:YES];
}
- (BOOL)activated { return activated;  }
- (void)setActivated: (BOOL)flag {
	if (activated == flag) return;
	if (![[info objectForKey:@"enabled"] boolValue])
		return;
	if (flag) {
		[[self manager] enableTrigger:self];
	} else {
		[[self manager] disableTrigger:self];
	}
	activated = flag;
}

- (BOOL)enabled {
	return [[info objectForKey:@"enabled"] boolValue];
}
- (void)disable {
	[self setEnabled:NO];
	[[QSTriggerCenter sharedInstance] writeTriggers];
}

- (void)reactivate {
	[self setActivated:NO];
	[self setActivated:YES];
}
- (void)setEnabled:(BOOL)enabled {
	[info setObject:[NSNumber numberWithBool:enabled] forKey:@"enabled"];
	[self setActivated:enabled];
	[[QSTriggerCenter sharedInstance] triggerChanged:self];
}

- (id)objectForKey:(NSString *)key {
	return 	[info objectForKey:key];
}
- (void)setObject:(id)object forKey:(NSString *)key {
	[info setObject:object forKey:key];
}
- (id)valueForUndefinedKey:(NSString *)key {
	return [info objectForKey:key];
}
//- (void)triggerChanged {
//	[self disableTrigger:trigger];
//	[self enableTrigger:trigger];
//	[self writeTriggers];
//	[[NSNotificationCenter defaultCenter] postNotificationName:QSTriggerChangedNotification object:trigger];
//}

- (NSMutableDictionary *)info {
	return info;
}

//- (QSCommand *)command {
//	return [[command retain] autorelease];
//}

//- (void)setCommand:(QSCommand *)value {
//	if (command != value) {
//		[command release];
//		command = [value retain];
//	}
//}

- (NSString *)triggerSet {
	return [info valueForKey:@"set"];
}

// Tree methods

- (NSString *)parentID {
	return [info valueForKey:@"parent"];
}
- (void)setParentID:(NSString *)ident {
	if (!ident)
		[info removeObjectForKey:@"parent"];
	else
		[info setObject:ident forKey:@"parent"];
}
- (NSString *)path {
	if ([self parent])
		return [[[self parent] path] stringByAppendingPathComponent:[self identifier]];
	else
		return [self identifier];
}
- (QSTrigger *)parent {
	return [[QSTriggerCenter sharedInstance] triggerWithID:[self parentID]];
}

- (NSComparisonResult) compare:(id)compareObject {
	return [[self name] compare:[compareObject name]];
}

- (BOOL)isLeaf {
	if ([[self type] isEqualToString:@"QSGroupTrigger"]) return NO;
	return YES;
}
- (NSArray *)children {
	if (![[self type] isEqualToString:@"QSGroupTrigger"]) return nil;
	return [[QSTriggerCenter sharedInstance] triggersWithParentID:[self identifier]];
}

// Image and text cell methods
- (id)imageAndText {return self;}
- (void)setImageAndText:(id)value {
	[self setName:value];
}
- (NSString *)text {return [self name];}
- (NSImage *)image {return [self smallIcon];}

@end
