//
// QSProxyObjectSource.m
// Quicksilver
//
// Created by Alcor on 1/16/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "QSProxyObjectSource.h"
#import "QSRegistry.h"
#import "QSProxyObject.h"
#import "QSObject.h"
#import "QSResourceManager.h"

@implementation QSProxyObjectSource
- (id)objectForRepresentation:(NSDictionary*)dictionary {
    QSProxyObject *object = [[QSProxyObject alloc] init];
    [object setObject:dictionary forType:QSProxyType];
    [object setPrimaryType:QSProxyType];
    return [object autorelease];
}

- (NSDictionary*)representationForObject:(QSObject*)object {
    return [object objectForType:QSProxyType];
}

- (BOOL)entryCanBeIndexed:(NSDictionary *)theEntry {return NO;}
- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry {
	return NO;
}

- (NSString *)identifierForObject:(QSObject*)object {
    return [[object objectForType:QSProxyType] objectForKey:kQSProxyIdentifier];
}

- (NSImage *)iconForEntry:(NSDictionary *)dict {
	return [QSResourceManager imageNamed:@"Object"];
}

- (NSString *)detailsOfObject:(QSObject *)object {
	return @"Proxy Object";
}

- (NSArray *)objectsForEntry:(NSDictionary *)theEntry {
	if (VERBOSE) NSLog(@"rescanning proxies");
	NSDictionary *messages = [QSReg tableNamed:@"QSProxies"];
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[messages count]];
	NSEnumerator *ke = [messages keyEnumerator];
	NSString *key;
	QSObject *proxyObject;
	NSDictionary *info;
	NSString *name;
	while (key = [ke nextObject]) {
		info = [messages objectForKey:key];
        proxyObject = [QSProxyObject proxyWithDictionary:info];
        [proxyObject setIdentifier:key];
		if (name = [info objectForKey:@"name"])
			[proxyObject setName:name];
		if (name = [info objectForKey:@"icon"])
			[proxyObject setObject:name forMeta:kQSObjectIconName];
		[proxyObject setPrimaryType:QSProxyType];

		if (proxyObject && [proxyObject enabled])
			[array addObject:proxyObject];
	}
	return array;
}

- (BOOL)loadChildrenForObject:(QSObject *)object {
	id proxyTarget = [(QSProxyObject*)object proxyObject];
	if (proxyTarget) {
		[object setChildren:[NSArray arrayWithObject:proxyTarget]];
		return YES;
	}
	return NO;
}

@end
