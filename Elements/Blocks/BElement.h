//
//  BElement.h
//  Blocks
//
//  Copyright 2007 Blocks. All rights reserved.
//

#import <Cocoa/Cocoa.h>


#import "BPlugin.h"
#import "BExtension.h"

// This class is equivalent to IConfigurationElement
@interface BElement : BExtension {
    Class elementClass;
    id elementInstance;	
}
- (NSString *)elementClassName;
- (Class)elementClass;
- (id)elementInstance;
- (id)elementNewInstance;
@end

@protocol BExecutableExtension // equivalent to IExecutableExtension
+ (id) instanceWithElement:(BElement *)element;
@end