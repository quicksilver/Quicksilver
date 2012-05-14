//
//  NSBundle_BLTRExtensions.h
//  Quicksilver
//
//  Created by Alcor on Sun Jun 13 2004.
//  Copyright (c) 2004 Blacktree. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Constant for comparing against when lookin for localized strings.
 Only used safeLocalizedStringForKey:
 */
#define missingString @"<missingString>"

#undef NSLocalizedString
#define NSLocalizedString(key, comment) \
[[NSBundle mainBundle] safeLocalizedStringForKey:(key) value:(key) table:nil]

#undef NSLocalizedStringFromTable
#define NSLocalizedStringFromTable(key, tbl, comment) \
[[NSBundle mainBundle] safeLocalizedStringForKey:(key) value:(key) table:(tbl)]

#undef NSLocalizedStringFromTableInBundle
#define NSLocalizedStringFromTableInBundle(key, tbl, bundle, comment) \
[bundle safeLocalizedStringForKey:(key) value:(key) table:(tbl)]

#undef NSLocalizedStringWithDefaultValue
#define NSLocalizedStringWithDefaultValue(key, tbl, bundle, val, comment) \
[bundle safeLocalizedStringForKey:(key) value:(val) table:(tbl)]



@interface NSBundle (BLTRExtensions)
- (id)imageNamed:(NSString *)name;

/**
 Look up localized version of string.
 
 You should not use this method. Use 
 NSString *NSLocalizedStringWithDefaultValue(NSString *key, NSString *tableName, NSBundle *bundle, NSString *value, NSString *comment)
 or it's relatives instead. That can be extracted automatically.
 
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
 
 @param key unique identifer for the string
 @param defaultValue will be used, if no localized and no english version of the string is found. 
 @param tableName name of the .strings file to be used (without the .strings extrension). If this 
 is nil, or the key could not be found in this file, it falls back to Localizable.strings
 @returns the best possible localized version of key.
 */
- (NSString *)safeLocalizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName;

@end
