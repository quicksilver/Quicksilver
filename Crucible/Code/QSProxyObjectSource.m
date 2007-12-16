//
//  QSProxyObjectSource.m
//  Quicksilver
//
//  Created by Alcor on 1/16/05.

//

#import "QSProxyObjectSource.h"

#import "QSProxyObject.h"
#import "QSObject.h"
#import "QSResourceManager.h"


@implementation QSProxyObjectSource


- (BOOL)entryCanBeIndexed:(NSDictionary *)theEntry{return NO;}
- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry{
	return NO;
}

- (NSImage *) iconForEntry:(NSDictionary *)dict{
    return [QSResourceManager imageNamed:@"Object"];
	
}
- (NSString *)detailsOfObject:(QSObject *)object{
	return @"Proxy Object";
}
- (NSArray *) objectsForEntry:(NSDictionary *)theEntry{
	//if (VERBOSE)QSLog(@"rescanning proxies");
	NSDictionary *messages=[QSReg elementsByIDForPointID:@"QSProxies"];
	NSMutableArray *array=[NSMutableArray arrayWithCapacity:[messages count]];
	NSEnumerator *ke=[messages keyEnumerator];
	NSString *key;
	QSObject *proxyObject;
	NSDictionary *info;
	NSString *name;
	while ((key=[ke nextObject])){
		info=[[messages objectForKey:key] plistContent];
		if ([info objectForKey:@"enabled"] && ![[info objectForKey:@"enabled"]boolValue])continue;
		proxyObject=[QSProxyObject makeObjectWithIdentifier:key];
		[proxyObject setObject:info forType:QSProxyType];
		if ((name=[info objectForKey:@"name"]))
			[proxyObject setName:name];
		if ((name=[info objectForKey:@"icon"]))
			[proxyObject setObject:name forMeta:kQSObjectIconName];
		[proxyObject setPrimaryType:QSProxyType];
		
	//	QSLog(@"key %@ %@",key,NSStproxyObject);
		if (proxyObject)
			[array addObject:proxyObject];
	}
	return array;
}
- (BOOL)loadChildrenForObject:(QSObject *)object{

	id proxyTarget=[object proxyObject];
	if (proxyTarget){
		[object setChildren:[NSArray arrayWithObject:proxyTarget]];
		return YES;
	}
	return NO;
}

@end