

#import <Foundation/Foundation.h>
#define QSTextProxyType @"QSTextProxyType"
#import "QSObject.h"

@interface QSObject (TextProxy)
+ (id)textProxyObjectWithDefaultValue:(NSString *)string;
@end

