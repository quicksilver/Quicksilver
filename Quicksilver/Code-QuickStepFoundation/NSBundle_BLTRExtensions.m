//
// NSBundle_BLTRExtensions.m
// Quicksilver
//
// Created by Alcor on Sun Jun 13 2004.
// Copyright (c) 2004 Blacktree. All rights reserved.
//

#import "NSBundle_BLTRExtensions.h"

@implementation NSBundle (BLTRExtensions)

- (id)imageNamed:(NSString *)name {
	NSString *compositeName = [NSString stringWithFormat:@"%@:%@", [self bundleIdentifier], name];
	NSImage *image = [NSImage imageNamed:compositeName];
	if (!image) { 
        image = [[[NSImage alloc] initWithContentsOfFile:[self pathForImageResource:name]] autorelease];
        [image setName:compositeName];
    }
	return image;
}

- (NSString *)safeLocalizedStringForKey:(NSString *)key value:(NSString *)defaultValue table:(NSString *)tableName {
	NSString *locString;
	
	// 1. look up in tableName for current localization (skip, if default table)
	if (tableName && ![tableName isEqualToString:@"Localizable"]) {
		locString = [self localizedStringForKey:key value:missingString table:tableName];
		if (locString && ![locString isEqualToString:missingString]) { 
			return locString; 
		}
	}
	
	// 2. look up in Localizable.strings for current localization
	locString = [self localizedStringForKey:key value:missingString table:nil];
	if (locString && ![locString isEqualToString:missingString]) { 
		return locString; 
	}
	if(DEBUG_LOCALIZATION) { 
		NSLog(@"Localization: Missing localized key %@ in table %@ for localization \"%@\", trying for English",
			  key,
			  tableName,
			  [[self preferredLocalizations] objectAtIndex:0]);
	}
	
	// 3. look up in tableName for default (English) localization (skip, if default table)
	NSDictionary *dictionary;
	if (tableName && ![tableName isEqualToString:@"Localizable"]) {
		dictionary = [NSDictionary dictionaryWithContentsOfFile:
					  [self pathForResource:tableName ofType:@"strings" inDirectory:nil forLocalization:@"English"]];
		locString = [dictionary objectForKey:key];
		if (locString) {
			return locString;
		}
	}
	
	// 4. look up in Localizable.strings for default (English) localization
	dictionary = [NSDictionary dictionaryWithContentsOfFile:
				  [self pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:@"English"]];
	locString = [dictionary objectForKey:key];
	if (locString) {
		return locString;
	}
	if(DEBUG_LOCALIZATION) {
		NSLog(@"Localization: Missing localized key %@ in table %@ for localization English",
			  key,
			  tableName);
	}
	
	// 5. use defaultValue
	return defaultValue;
}

NSMutableDictionary *scriptsDictionary = nil;
+ (NSMutableDictionary *)scriptsDictionary {
	if (!scriptsDictionary)
		scriptsDictionary = [[NSMutableDictionary alloc] init];
	return scriptsDictionary;
}

- (id)scriptNamed:(NSString *)name {
	NSString *compositeName = [NSString stringWithFormat:@"%@:%@", [self bundleIdentifier] , name];
	NSAppleScript *script = [[NSBundle scriptsDictionary] objectForKey:compositeName];
	if (!script) {
		NSString *path = [self pathForResource:name ofType:@"scpt"];
		if (path) script = [[[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil] autorelease];
		[[NSBundle scriptsDictionary] setObject:script forKey:compositeName];
	}
	return script;
}

@end
