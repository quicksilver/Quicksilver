/*
 *  QSLocalization.h
 *  Quicksilver
 *
 *  Created by Alcor on 7/22/04.
 *  Copyright 2004 Blacktree. All rights reserved.
 *
 */

#include <Carbon/Carbon.h>

BOOL QSGetLocalizationStatus();

extern NSMutableDictionary *localizationBundles;
@interface NSBundle (QSDistributedLocalization)
+ (void)registerLocalizationBundle:(NSBundle *)bundle forLanguage:(NSString *)lang;
+ (NSBundle *)localizationBundleForBundle:(NSBundle *)bundle;
- (NSString *)distributedLocalizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName;
@end
