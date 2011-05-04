/*
 * QSLocalization.m
 * Quicksilver
 *
 * Created by Alcor on 7/22/04.
 * Copyright 2004 Blacktree. All rights reserved.
 *
 */

#include "QSLocalization.h"

BOOL QSIsLocalized;

BOOL QSGetLocalizationStatus() {
    QSIsLocalized = (BOOL)[[[NSBundle mainBundle] preferredLocalizations] indexOfObject:@"en"];
	return QSIsLocalized;
}

NSMutableDictionary *localizationBundles;

@implementation NSBundle (QSDistributedLocalization)
+ (void)initialize {
	localizationBundles = [[NSMutableDictionary alloc] init];
}
+ (void)registerLocalizationBundle:(NSBundle *)bundle forLanguage:(NSString *)lang {
	NSArray *locs = [bundle pathsForResourcesOfType:@"qsloc" inDirectory:nil];
	for(NSString * loc in locs) {
		[localizationBundles setObject:bundle forKey:[[loc lastPathComponent] stringByDeletingPathExtension]];
	}

}

+ (NSBundle *)localizationBundleForBundle:(NSBundle *)bundle {
//	NSLog(@"dict %@ %@", [bundle bundleIdentifier] , localizationBundles);
	return [localizationBundles objectForKey:[bundle bundleIdentifier]];
}

- (NSString *)distributedLocalizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName {
	return [self safeLocalizedStringForKey:key value:value table:tableName];
}


@end
