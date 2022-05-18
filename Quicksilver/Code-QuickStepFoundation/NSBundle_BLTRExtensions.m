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
	__autoreleasing NSImage *image = [NSImage imageNamed:compositeName];
	if (!image) { 
        image = [[NSImage alloc] initWithContentsOfFile:[self pathForImageResource:name]];
        [image setName:compositeName];
    }
	return image;
}

#if DEBUG
+ (NSMutableDictionary *)missingLocalizedValuesForAllBundles {
	static NSMutableDictionary *missingKeysDict = nil;
	if (!missingKeysDict) {
		missingKeysDict = [[NSMutableDictionary alloc] initWithCapacity:1];
	}
	return missingKeysDict;
}

+ (NSMutableDictionary *)missingLocalizedValuesForBundle:(NSString *)bundleId {
	if (!bundleId)
		bundleId = @"missing";
	NSMutableDictionary *missingBundles = [self missingLocalizedValuesForAllBundles];
	NSMutableDictionary *missingBundleLocales = [missingBundles objectForKey:bundleId];
	if (!missingBundleLocales) {
		[missingBundles setObject:(missingBundleLocales = [NSMutableDictionary dictionary]) forKey:bundleId];
	}
	return missingBundleLocales;
}


- (NSMutableDictionary *)missingLocalizedValuesForTablesInLocale:(NSString *)locale {
	if (!locale)
		locale = @"en";
	NSMutableDictionary *missingTables = [[self class] missingLocalizedValuesForBundle:[self bundleIdentifier]];
	NSMutableDictionary *missingKeysDict = [missingTables objectForKey:locale];
	if (!missingKeysDict)
		[missingTables setObject:(missingKeysDict = [NSMutableDictionary dictionary]) forKey:locale];
	return missingKeysDict;
}

- (NSMutableDictionary *)missingLocalizedValuesForKeysInTable:(NSString *)tableName inLocale:(NSString *)locale {
	if (!tableName)
		tableName = @"Localizable";
	NSMutableDictionary *missingTables = [self missingLocalizedValuesForTablesInLocale:locale];
	NSMutableDictionary *missingValues = [missingTables objectForKey:tableName];
	if (!missingValues) {
		[missingTables setObject:(missingValues = [NSMutableDictionary dictionary]) forKey:tableName];
	}
	return missingValues;
}

- (NSMutableDictionary *)missingLocalizedValuesForKey:(NSString *)key inTable:(NSString *)tableName inLocale:(NSString *)locale {
	return [[self missingLocalizedValuesForKeysInTable:tableName inLocale:locale] objectForKey:key];
}

- (void)setValue:(NSString *)value forLocalizedKey:(NSString *)key inTable:(NSString *)tableName inLocale:(NSString *)locale {
	if (value)
		[[self missingLocalizedValuesForKeysInTable:tableName inLocale:locale] setObject:value forKey:key];
}
#endif

- (NSString *)safeLocalizedStringForKey:(NSString *)key value:(NSString *)defaultValue table:(NSString *)tableName {
	NSString *locString;
	
	// Skip if default table
	if ([tableName isEqualToString:@"Localizable"])
		tableName = nil;
	
	// 1. look up in tableName for current localization
	if (tableName) {
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
	
#ifdef DEBUG
	if(DEBUG_LOCALIZATION) {
		NSString *preferred = [[self preferredLocalizations] objectAtIndex:0];
		[self setValue:defaultValue forLocalizedKey:key inTable:tableName inLocale:preferred];
		NSLog(@"Localization: Missing localized key \"%@\" in table \"%@\" for localization \"%@\", falling back",
			  key,
			  tableName,
			  preferred);
	}
#endif
	NSArray *defaultLocalizations = [NSArray arrayWithObjects:@"English", @"en", nil];
	
	for (NSString *locale in defaultLocalizations) {
		// 3. look up in tableName for default localizations
		NSDictionary *dictionary;
		if (tableName) {
			dictionary = [NSDictionary dictionaryWithContentsOfFile:
						  [self pathForResource:tableName ofType:@"strings" inDirectory:nil forLocalization:locale]];
			locString = [dictionary objectForKey:key];
			if (locString) {
				return locString;
			}
		}
		
		// 4. look up in Localizable.strings for default (English) localization
		dictionary = [NSDictionary dictionaryWithContentsOfFile:
					  [self pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:locale]];
		locString = [dictionary objectForKey:key];
		if (locString) {
			return locString;
		}
	}
	
#ifdef DEBUG
	if(DEBUG_LOCALIZATION) {
		[self setValue:defaultValue forLocalizedKey:key inTable:tableName inLocale:@"en"];
		NSLog(@"Localization: Missing localized key \"%@\" in table \"%@\" for localizations \"%@\"",
			  key,
			  tableName,
			  defaultLocalizations);
	}
#endif
	
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
		if (path) {
            script = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil];
        }
	}
    if (script) {
        [[NSBundle scriptsDictionary] setObject:script forKey:compositeName];
    }
	return script;
}

-(NSArray *)executableArchitecturesPretty {
	NSMutableArray *archs = [[NSMutableArray alloc] init];
	for (NSNumber *arch in [self executableArchitectures]) {
		NSString *archstr;
		switch ([arch intValue]) {
			case NSBundleExecutableArchitectureARM64:
				archstr = @"arm64";
				break;
			case NSBundleExecutableArchitectureI386:
				archstr = @"i386";
				break;
			case NSBundleExecutableArchitectureX86_64:
				archstr = @"x86_64";
				break;
			case NSBundleExecutableArchitecturePPC:
				archstr = @"ppc32";
				break;
			case NSBundleExecutableArchitecturePPC64:
				archstr = @"ppc64";
				break;
		}
		[archs addObject:archstr];
	}
	return archs;
}

@end
