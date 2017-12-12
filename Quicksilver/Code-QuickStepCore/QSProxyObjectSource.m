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

@implementation QSProxyObjectHandler

- (NSString *)detailsOfObject:(QSObject *)object {
    NSString *details = nil;
    id provider = ( [object isProxyObject] ? [(QSProxyObject*)object proxyProvider] : nil );
    if (provider && [provider respondsToSelector:@selector(detailsOfObject:)]) {
        details = [provider detailsOfObject:object];
    }
    if (!details)
        details = @"Proxy Object";
    return details;
}

- (NSString *)identifierForObject:(QSObject*)object {
    NSString *identifier = nil;
    id provider = ( [object isProxyObject] ? [(QSProxyObject*)object proxyProvider] : nil );
    if (provider && [provider respondsToSelector:@selector(identifierForObject:)]) {
        identifier = [provider identifierForObject:object];
    }
    if (!identifier)
        identifier = [[object objectForType:QSProxyType] objectForKey:kQSProxyIdentifier];
    return identifier;
}

- (BOOL)loadChildrenForObject:(QSObject *)object {
    BOOL loaded = NO;
    id provider = ( [object isProxyObject] ? [(QSProxyObject*)object proxyProvider] : nil );
    if (provider && [provider respondsToSelector:@selector(loadChildrenForObject:)]) {
        loaded = [provider loadChildrenForObject:object];
    }
    if (!loaded) {
        id proxyTarget = [(QSProxyObject*)object proxyObject];
        if (proxyTarget) {
            [object setChildren:[NSArray arrayWithObject:proxyTarget]];
            return YES;
        }
    }
	return loaded;
}

@end

@implementation QSProxyObjectSource
- (BOOL)entryCanBeIndexed:(QSCatalogEntry *)theEntry {return NO;}
- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(QSCatalogEntry *)theEntry {
	return NO;
}

- (NSImage *)iconForEntry:(QSCatalogEntry *)theEntry {
	return [QSResourceManager imageNamed:@"Object"];
}

- (NSArray *)objectsForEntry:(QSCatalogEntry *)theEntry {
#ifdef DEBUG
	if (VERBOSE) NSLog(@"rescanning proxies");
#endif
	NSDictionary *messages = [QSReg tableNamed:@"QSProxies"];
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[messages count]];
	QSObject *proxyObject;
	NSDictionary *info;
	NSString *name;
	for (NSString *key in messages) {
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

@end
