//
//  NSBundle_BLTRExtensions.m
//  Quicksilver
//
//  Created by Alcor on Sun Jun 13 2004.

//

#import "NSBundle_BLTRExtensions.h"


@implementation NSBundle (BLTRExtensions)

- (id)imageNamed:(NSString *)name{
	NSString *compositeName=[NSString stringWithFormat:@"%@:%@",[self bundleIdentifier],name];
	NSImage *image=[NSImage imageNamed:compositeName];
	if (!image) image= [[[NSImage alloc]initWithContentsOfFile:[self pathForImageResource:name]]autorelease];
	[image setName:compositeName];
	return image;
}


// Falls back on english localization when needed
- (NSString *)safeLocalizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName{
//	QSLog(@"string %@ %@",key,tableName);
	NSString *dummyString = @"<missing>";
	NSString *locString = [self localizedStringForKey:key value:dummyString table:tableName];
	if ([locString isEqual:dummyString]) locString=nil;
	
	if (!locString){
		NSMutableDictionary *dictionary=[NSDictionary dictionaryWithContentsOfFile:
			[self pathForResource:(tableName?tableName:@"Localizable") ofType:@"strings" inDirectory:nil forLocalization:@"English"]];
		locString=[dictionary objectForKey:key];
	}
	
	if (!locString) locString=value;
	if (!locString) locString=key;
	
	return locString;
}

NSMutableDictionary *scriptsDictionary=nil;
+ (NSMutableDictionary *)scriptsDictionary{
	if (!scriptsDictionary)
		scriptsDictionary=[[NSMutableDictionary alloc]init];
	return scriptsDictionary;
}


- (id)scriptNamed:(NSString *)name{
	NSString *compositeName=[NSString stringWithFormat:@"%@:%@",[self bundleIdentifier],name];
	NSAppleScript *script=[[NSBundle scriptsDictionary]objectForKey:compositeName];
	if (!script){
		NSString *path=[self pathForResource:name ofType:@"scpt"];
		if (path) script=[[[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil]autorelease];
		[[NSBundle scriptsDictionary]setObject:script forKey:compositeName];
	}
	return script;
}


@end