//
//  NSApplication+ServicesModification.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 12/16/05.

//

#import "NSApplication+ServicesModification.h"


@implementation NSApplication (ServicesModification)


- (NSDictionary *)servicesDictionaryForService:(NSString *)serviceName{
	NSArray *array=[[NSBundle mainBundle]objectForInfoDictionaryKey:@"NSServices"];
	foreach(dict,array){
		//QSLog([dict valueForKeyPath:(@"NSMenuItem.default")]);
		//QSLog(serviceName);
		if ([[dict valueForKeyPath:(@"NSMenuItem.default")]isEqualToString:serviceName])
			return dict;
	}
	return nil;
}
- (void)setServicesDictionary:(NSDictionary *)dict forService:(NSString *)serviceName{
	NSString *plistPath=[[[NSBundle mainBundle]bundlePath]stringByAppendingPathComponent:@"Contents/Info.plist"];
	NSMutableDictionary *plistDict=[NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
	
	NSMutableArray *array=[[[plistDict objectForKey:@"NSServices"]mutableCopy]autorelease];
	NSDictionary *oldDict=nil;
	foreach(aDict,array){
		if ([[aDict valueForKeyPath:(@"NSMenuItem.default")]isEqualToString:serviceName]){
			oldDict=aDict;
			break;
		}
	}
	
	[array replaceObjectAtIndex:[array indexOfObject:oldDict] withObject:dict];
	[plistDict setObject:array forKey:@"NSServices"];
	[plistDict writeToFile:plistPath atomically:NO];
	
	NSUpdateDynamicServices();
//	QSLog(@"dict %@",plistDict);
}

- (NSString *)keyEquivalentForService:(NSString *)serviceName{
	return [[self servicesDictionaryForService:serviceName]valueForKeyPath:@"NSKeyEquivalent.default"];
}


- (void)setKeyEquivalent:(NSString *)equiv forService:(NSString *)serviceName{
	NSDictionary *dict=[[[self servicesDictionaryForService:serviceName]mutableCopy]autorelease];
	[dict setValue:equiv forKeyPath:@"NSKeyEquivalent.default"];
	[self setServicesDictionary:dict forService:serviceName];
//	QSLog(@"x %@ ",dict);
}
@end
