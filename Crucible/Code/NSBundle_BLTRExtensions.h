//
//  NSBundle_BLTRExtensions.h
//  Quicksilver
//
//  Created by Alcor on Sun Jun 13 2004.

//

#import <Foundation/Foundation.h>

@interface NSBundle (BLTRExtensions)
- (id)imageNamed:(NSString *)name;

- (NSString *)safeLocalizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName;
//Localized string lookup that falls back on English.

@end
