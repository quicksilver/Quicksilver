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

/**
 Look up localized version of string.
 
 You should not use this method. Use 
 NSString *NSLocalizedStringWithDefaultValue(NSString *key, NSString *tableName, NSBundle *bundle, NSString *value, NSString *comment)
 instead. That can be extracted automatically.
 
 This method tries to look up the best possible localized version of a string. It starts looking 
 in the most specific place and if it can't find the string there, it falls back to the next, less 
 specific place. The look-up order is as follows:
 1. Check in the user's preferred language (e.g. "de" for German), in the .strings file specified in 
	tableName (skip this step if tableName is nil or "Localizable")
 2. Check in the user's preferred language ("de"), in the Localizable.strings file.
 3. Check in the default language ("English"), in the .strings file specified in tableName 
	(skip this step if tableName is nil or "Localizable")
 4. Check in the default language ("English"), in the Localizable.strings file.
 5. use defaultValue
 6. use key
 
 @param key unique identifer for the string
 @param defaultValue will be used, if no localized and no english version of the string is found. 
		If it is nil, the key will be used as default value.
 @param tableName name of the .strings file to be used (without the .strings extrension). If this 
		is nil, or the key could not be found in this file, it falls back to Localizable.strings
 @returns the best possible localized version of key.
 */
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
	locString = defaultValue;
	if (locString && ![locString isEqualToString:@""]) {
		return locString;
	}
	
	// 6. use key
	return key;
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
