

#import <Foundation/Foundation.h>
#import "QSObject.h"

#define QSComputerProxyType @"QSComputerProxyType"


@interface QSComputerProxy : QSBasicObject{
    NSString *name;
}

+ (id)sharedInstance;
@end
