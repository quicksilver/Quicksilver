/*
 *  QSLocalization.m
 *  Quicksilver
 *
 *  Created by Alcor on 7/22/04.
 *  Copyright 2004 Blacktree. All rights reserved.
 *
 */

#include "QSLocalization.h"
BOOL QSIsLocalized;

BOOL QSGetLocalizationStatus() {
	QSIsLocalized = [[[NSBundle mainBundle] preferredLocalizations] indexOfObject:@"en"];
	
	//QSLog(@"local %@",[[NSBundle mainBundle]preferredLocalizations]);	
	return QSIsLocalized;
}


NSMutableDictionary *localizationBundles;
@implementation NSBundle (QSDistributedLocalization)
+ (void) initialize {
	localizationBundles = [[NSMutableDictionary alloc] init];
}

+ (void) registerLocalizationBundle:(NSBundle *)bundle forLanguage:(NSString *)lang {
	NSArray *locs = [bundle pathsForResourcesOfType:@"qsloc" inDirectory:nil];
	foreach( loc, locs ) {
		[localizationBundles setObject:bundle forKey:[[loc lastPathComponent] stringByDeletingPathExtension]];
	}
	
}

+ (NSBundle *) localizationBundleForBundle:(NSBundle *)bundle {
//	QSLog(@"dict %@ %@",[bundle bundleIdentifier],localizationBundles);
	return [localizationBundles objectForKey:[bundle bundleIdentifier]];
}

- (NSString *) distributedLocalizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName {
	NSString *dummyString = @"<missing>";
	NSString *locString = [self localizedStringForKey:key value:dummyString table:tableName];
    
	if ([locString isEqual:dummyString])
        locString = nil;
    
	if (!tableName)
        tableName = @"Localizable";
    
	if (!locString && QSIsLocalized) {
		NSBundle *locBundle = [NSBundle localizationBundleForBundle:self];
		NSString *tablePath = [locBundle pathForResource:[self bundleIdentifier] ofType:@"qsloc"];
		
		//QSLog(@"dict %@ %@",locBundle,tablePath);
		tablePath = [[tablePath stringByAppendingPathComponent:tableName] stringByAppendingPathExtension:@"strings"];		
		NSMutableDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:tablePath];
		locString = [dictionary objectForKey:key];
	}
    
    if (!locString) {
		NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:
			[self pathForResource:tableName ofType:@"strings" inDirectory:nil forLocalization:@"English"]];
            
		locString = [dictionary objectForKey:key];
	}
	
	if (!locString)
        locString = value;
    
	if (!locString)
        locString = key;
    
	return locString;
}


@end