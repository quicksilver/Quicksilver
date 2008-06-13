//
//  QSTrigger.m
//  Quicksilver
//
//  Created by Alcor on 6/19/05.
//  Copyright 2005 Blacktree, Inc. All rights reserved.
//

#import "QSTrigger.h"
#import "QSTriggerCenter.h"
#import "QSTriggersPrefPane.h"

@implementation QSTrigger

+ (void)initialize {
	[self setKeys:[NSArray arrayWithObject:@"command"] triggerChangeNotificationsForDependentKey:@"name"];
	[self setKeys:[NSArray arrayWithObjects:@"name", @"icon",nil] triggerChangeNotificationsForDependentKey:@"imageAndText"];
}

+ (id)triggerWithInfo:(NSDictionary *)dict {
	return [[[self alloc] initWithInfo:dict] autorelease];
}

- (NSString *)identifier {
	return [info objectForKey:kItemID];	
}

- (id)initWithInfo:(NSDictionary *)dict {
	self = [super init];
	if (self != nil) {
		info = [dict mutableCopy];
	}
	return self;
}

- (id) init {
	self = [super init];
	if (self != nil) {
		info = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc {
	QSLog(@"dealloc %@",self);
	[info release];
	info = nil;
	[children release];
	children = nil;
	[super dealloc];	
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
    return nil;
}

- (NSString *)name {
	NSString *name = [info objectForKey:@"name"];
	if (!name) {
		name = [[self command] description];
	}
	return name;	
}

- (BOOL)hasCustomName {
	if ([self isPreset])
        return NO;
	return ([info objectForKey:@"name"] != nil);
}

- (void)setName:(NSString *)name {
	//QSLog(@"setName %@",name);
	if (![name length]) {
		[info removeObjectForKey:@"name"];
	} else if (name) {
		[info setObject:name forKey:@"name"];
	}
}

- (NSString *)type{
	return [info objectForKey:@"type"];	
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

- (void)initializeTrigger{
//	id manager=[QSReg instanceForKey:type inTable:QSTriggerManagers];
	[[self manager] initializeTrigger:self];
}

- (BOOL)rescope:(NSString *)ident {
	int scoped = [[info objectForKey:@"applicationScopeType"] intValue];
	if (!scoped) return NO;
	NSArray *apps = [info objectForKey:@"applicationScope"];
	BOOL shouldActivate = [apps containsObject:ident];	
	if(scoped < 0) shouldActivate = !shouldActivate;	

	[self setActivated:shouldActivate];
    return YES;
}

- (BOOL)execute {	
    [[self command] executeIgnoringModifiers];	
	if ([info objectForKey:@"oneshot"]) {
		//if (VERBOSE) QSLog(@"disabling one shot trigger");
		[self disable];
	}
	return YES;
}

- (QSCommand *)command {
	//	QSLog(@"command %@",command);
    id command = [info objectForKey:@"command"];
    if ([command isKindOfClass:[NSDictionary class]]) {
		command = [QSCommand commandWithDictionary:command];
		[info setObject:command forKey:@"command"];
	} else if ([command isKindOfClass:[NSString class]]) {
		NSDictionary *commandInfo = [QSReg valueForKey:command inTable:@"QSCommands"];
		
		//QSLog(@"looking up command %@ %@",command, commandInfo );
		command = [QSCommand commandWithDictionary:[commandInfo objectForKey:@"command"]];
	}
	return command;
}

- (NSArray *)commands {
	return [NSArray arrayWithObject:[self command]];	
}
- (BOOL)isPreset {
	return [[info objectForKey:kItemID]hasPrefix:@"QS"];	
}

- (BOOL)usesPresetCommand {
	return ([[info objectForKey:@"command"] isKindOfClass:[NSString class]]);
}

- (NSDictionary *)dictionaryRepresentation {
	id command=[info objectForKey:@"command"];
	if ([command isKindOfClass:[QSCommand class]]) {
		NSMutableDictionary *dict = [[info mutableCopy]autorelease];
		[dict setObject:[command dictionaryRepresentation]forKey:@"command"];
		return dict;
	}
	return info;
}

- (NSString *)triggerDescription {
//	QSLog(@"descript");
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

- (BOOL) activated { return activated; }
- (void) setActivated: (BOOL) flag
{
	if (activated == flag) return;
	if (![[info objectForKey:@"enabled"] boolValue])
		return;
    //QSLog(@"%@ %d",self,flag);
		
	if (flag) {
		[[self manager] enableTrigger:(QSTrigger *)self];
	} else {
		[[self manager] disableTrigger:(QSTrigger *)self];
	}
    
    activated = flag;
}

- (BOOL)enabled {
	return [[info objectForKey:@"enabled"]boolValue];
}

- (void)disable {
	[self setEnabled:NO];
	//[info setObject:[NSNumber numberWithBool:NO] forKey:@"enabled"];
	[[QSTriggerCenter sharedInstance] writeTriggers];
}

- (void)reactivate {
	//QSLog(@"reactivating %@",self);
	[self setActivated:NO];
	[self setActivated:YES];
}

- (void)setEnabled:(BOOL)enabled{
	//	QSLog(@"Set Enabled %d %@",enabled,self);
	
	[info setObject:[NSNumber numberWithBool:enabled] forKey:@"enabled"];
	[self setActivated:enabled];	
	[[QSTriggerCenter sharedInstance] triggerChanged:self];
}

- (id)objectForKey:(NSString *)key{
	return 	[info objectForKey:key];
}
- (void)setObject:(id)object forKey:(NSString *)key{
	[info setObject:object forKey:key];
}
- (id)valueForUndefinedKey:(NSString *)key{
	return [info objectForKey:key];
}
//- (void)triggerChanged{
//    [self disableTrigger:trigger];
//    [self enableTrigger:trigger];
//    [self writeTriggers];    
//	[[NSNotificationCenter defaultCenter]postNotificationName:QSTriggerChangedNotification object:trigger];
//}

- (NSMutableDictionary *)info{
	return info;
}

//- (QSCommand *)command {
//    return [[command retain] autorelease];
//}

//- (void)setCommand:(QSCommand *)value {
//    if (command != value) {
//        [command release];
//        command = [value retain];
//    }
//}


- (NSString *)triggerSet{
	return [info valueForKey:@"set"];	
}



// Tree methods

-(NSString *)parentID{
	return [info valueForKey:@"parent"];	
}
- (void)setParentID:(NSString *)ident{
	if (!ident)
		[info removeObjectForKey:@"parent"];
	else
		[info setObject:ident forKey:@"parent"];
}

- (NSArray *) paths {
#warning DEBUG: Should remove assert if no problems arise.
    NSArray * array = [[[self parents] arrayByPerformingSelector:@selector(paths)]
                       arrayByPerformingSelector:@selector(stringByAppendingPathComponent:) withObject:[self identifier]];
    assert( array != nil );
    return array;
}

- (NSArray *) parents {
	return 	[[QSTriggerCenter sharedInstance] triggersWithParentID:[self parentID]];
}


- (NSComparisonResult)compare:(id)compareObject{
    return [[self name] compare:[compareObject name]];
}

- (BOOL) isLeaf {
    return ![[self type] isEqualToString:@"QSGroupTrigger"];
}

- (NSArray *)children {
	if (![[self type]isEqualToString:@"QSGroupTrigger"]) return nil;
	return 	[[QSTriggerCenter sharedInstance] triggersWithParentID:[self identifier]];
}



// Image and text cell methods
- (id)imageAndText{return self;}
- (void)setImageAndText:(id)value{
	[self setName:value];	
}
- (NSString *)text{return [self name];}
- (NSImage *)image{return [self smallIcon];}

@end
