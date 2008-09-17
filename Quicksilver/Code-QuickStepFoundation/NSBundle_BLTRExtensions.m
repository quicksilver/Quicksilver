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

// Falls back on english localization when needed
- (NSString *)safeLocalizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName {
    /* Look up in tableName for current localization */
	NSString *locString = [self localizedStringForKey:key value:nil table:tableName];
	if ([locString isEqual:key]) {
        locString = nil;
    }
    
    if (!locString && tableName != nil) {
        /* Look up in default table (Localizable.strings) for current localization */
		locString = [self localizedStringForKey:key value:nil table:nil];
        if ([locString isEqual:key]) {
            locString = nil;
        }
	}
    
	if (!locString) {
        /* Look up in tableName in en.lproj */
        if(DEBUG_LOCALIZATION)
            NSLog(@"Localization: Missing localized key %@ in table %@, fallback on en", key, tableName);
		NSDictionary *dictionary;
        if (tableName) {
            dictionary = [NSDictionary dictionaryWithContentsOfFile:
                          [self pathForResource:tableName ofType:@"strings" inDirectory:nil forLocalization:@"en"]];
            locString = [dictionary objectForKey:key];
        }
        if (!locString) {
            dictionary = [NSDictionary dictionaryWithContentsOfFile:
                          [self pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:@"en"]];
            locString = [dictionary objectForKey:key];
        }
	}
    
	if (!locString) {
        /* Failed, return value if specified and report */
        if(DEBUG_LOCALIZATION)
            NSLog(@"Localization: Missing localized key %@ in table %@, returning value %@", key, tableName, value);
        locString = value;
    }
	return locString;
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
