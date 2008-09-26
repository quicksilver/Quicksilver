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
- (id)providerSelector:(SEL)selector forObject:(QSObject*)object {
    id provider = ( [object isKindOfClass:[QSProxyObject class]] ? [(QSProxyObject*)object proxyProvider] : nil );
    if (provider && [provider respondsToSelector:selector]) {
        return [provider performSelector:selector withObject:object];
    }
    return nil;
}

- (NSString *)detailsOfObject:(QSObject *)object {
    NSString *details = [self providerSelector:_cmd forObject:object];
    if (!details)
        details = @"Proxy Object";
    return details;
}

- (NSString *)identifierForObject:(QSObject*)object {
    NSString *identifier = [self providerSelector:_cmd forObject:object];
    if (!identifier)
        identifier = [[object objectForType:QSProxyType] objectForKey:kQSProxyIdentifier];
    return identifier;
}

- (BOOL)loadChildrenForObject:(QSObject *)object {
    BOOL loaded = (BOOL)[self providerSelector:_cmd forObject:object];
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
- (BOOL)entryCanBeIndexed:(NSDictionary *)theEntry {return NO;}
- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry {
	return NO;
}

- (NSImage *)iconForEntry:(NSDictionary *)dict {
	return [QSResourceManager imageNamed:@"Object"];
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

@end
