//
// QSTrigger.m
// Quicksilver
//
// Created by Alcor on 6/19/05.
// Copyright 2005 Blacktree, Inc. All rights reserved.
//
// Modified by p_j_r on 24/04/2011

#import "QSTriggersPrefPane.h"

#import "QSTrigger.h"
#import "QSTriggerCenter.h"
#import "QSCommand.h"
#import "QSRegistry.h"

@implementation QSTrigger

// KVO
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

    if ([key isEqualToString:@"name"]) {
        keyPaths = [keyPaths setByAddingObject:kCommand];
    } else if ([key isEqualToString:@"imageAndText"]) {
        keyPaths = [keyPaths setByAddingObjectsFromSet:[NSSet setWithObjects:@"name",@"icon",nil]];
    }
    return keyPaths;
}

+ (id)triggerWithInfo:(NSDictionary *)dict {
    return [self triggerWithDictionary:dict];
}

+ (id)triggerWithDictionary:(NSDictionary *)dict {
	return [[self alloc] initWithDictionary:dict];
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
        activated = YES;
	}
	return self;
}


#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self == [super init]) {
        info = [aDecoder decodeObjectForKey:kData];
        command = [aDecoder decodeObjectForKey:kCommand];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.command forKey:kCommand];
    [aCoder encodeObject:self.info forKey:kData];
}

#pragma mark Instance Methods

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
		NSImage *icon = [[[self command] icon] copy];
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

// On app change, checks all triggers to see if they should be enabled/disabled based on scope in prefs
- (void)rescope:(NSString *)ident {
	// If the trigger's disabled there's no point rescoping
	if([info objectForKey:@"enabled"] && ![[info objectForKey:@"enabled"] boolValue]) return;
	// Scoped is 0 for unscoped triggers, -1 for 'disabled in application xxx' and +1 for 'enabled in application xxx'
	NSInteger scoped = [[info objectForKey:@"applicationScopeType"] integerValue];
	if (!scoped) return;
	NSArray *apps = [info objectForKey:@"applicationScope"];
	BOOL shouldActivate = [apps containsObject:ident];
	if (scoped<0) shouldActivate = !shouldActivate;

	[self setActivated:shouldActivate];
}

- (BOOL)execute {
    if(!activated) {
        return NO;
    }
    QSCommand *cmd = [self command];
    // if a trigger loaded before the catalog, an identifier will appear as plain text
    if ([[[cmd dObject] primaryType] isEqualToString:QSTextType]) {
        NSString *ident = [[cmd dObject] objectForType:QSTextType];
        QSObject *realObject = [[QSLibrarian sharedInstance] objectWithIdentifier:ident];
        // update the trigger with the real object
        [cmd setDirectObject:realObject];
    }
    if ([[[cmd iObject] primaryType] isEqualToString:QSTextType]) {
        NSString *ident = [[cmd iObject] objectForType:QSTextType];
        QSObject *realObject = [[QSLibrarian sharedInstance] objectWithIdentifier:ident];
        // update the trigger with the real object
        [cmd setIndirectObject:realObject];
    }
    void (^block)(void) =  ^{
        [cmd executeIgnoringModifiers];
        if ([self->info objectForKey:@"oneshot"]) {
            [self setEnabled:NO];
        }
    };
//	defaultBool(x) [[NSUserDefaults standardUserDefaults] boolForKey:x]
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kExecuteInThread] && [cmd canThread]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), block);
    } else {
        block();
    }

	return YES;
}

- (void)setCommand:(QSCommand*)newCommand {
    if (newCommand != command) {
        command = newCommand;
    }
}

- (QSCommand *)command {
    if (command)
        return command;
    
	id archivedCommand = [info objectForKey:kCommand];
    if (archivedCommand)
        command = [QSCommand commandWithInfo:archivedCommand];
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

// if the command has a preset (e.g. a built in command/trigger for a plugin: performs a single action),
// it is a single string as opposed to an NSDict with an 'action' and 'direct object' (or 'indirect object')
- (BOOL)usesPresetCommand {
	return ([[info objectForKey:kCommand] isKindOfClass:[NSString class]]);
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
        [dict setObject:rep forKey:kCommand];
    else
        [dict removeObjectForKey:kCommand];
	return dict;
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

- (void)reactivate {
    activated = [self enabled];
    if (activated) {
        [[self manager] enableTrigger:self];
    }
}

- (BOOL)activated {
	return activated;
}
- (void)setActivated:(BOOL)flag {
	if (![[info objectForKey:@"enabled"] boolValue])
		return;
    activated = flag;
    QSHotKeyEvent *hotKeyEvent = [QSHotKeyEvent hotKeyWithIdentifier:[[self info] objectForKey:kItemID]];
    
    // list of triggers with the same hotkey (i.e. the same ID)
    NSArray *triggersWithSameID = [[QSTriggerCenter sharedInstance] triggersWithIDs:[hotKeyEvent identifiers]];
    // get indexes of any triggers that are activated
    NSIndexSet *ind = [triggersWithSameID indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(QSTrigger *trig, NSUInteger idx, BOOL *stop) {
        return [trig activated];
    }];
    // set whether or not the hotkey is enabled (Quicksilver 'grabs' the hotkey) based on whether or not any triggers are active
    if (flag) {
        [hotKeyEvent setEnabled:([ind count] >= 1)];
    } else {
        [hotKeyEvent setEnabled:([ind count])];
    }
}

- (BOOL)enabled {
	return [[info objectForKey:@"enabled"] boolValue];
}

- (void)disable {
	[self setEnabled:NO];
}

- (void)setEnabled:(BOOL)enabled {
	[info setObject:[NSNumber numberWithBool:enabled] forKey:@"enabled"];
	[[QSTriggerCenter sharedInstance] triggerChanged:self];
}

// Fix for issue 47, http://github.com/tiennou/blacktree-alchemy/issues#issue/47
// Enable/Disable the trigger based on the enabled flag.
// Allows the flag to be changed without notifing the QSTriggerCenter, avoiding
// endless recursive calls and blowing out the stack.
- (void)setEnabledDoNotNotify:(BOOL)enabled {
	[info setObject:[NSNumber numberWithBool:enabled] forKey:@"enabled"];
    activated = enabled ? [[self manager] enableTrigger:self] : [[self manager] disableTrigger:self];
}

- (id)objectForKey:(NSString *)key {
	return [info objectForKey:key];
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

- (NSComparisonResult) compare:(QSTrigger *)compareObject {
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
