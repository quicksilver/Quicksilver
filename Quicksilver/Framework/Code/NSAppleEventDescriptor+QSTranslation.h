//
//  NSAppleEventDescriptor+QSTranslation.h
//  Quicksilver
//
//  Created by Alcor on Thu Aug 28 2003.

//

#import <Foundation/Foundation.h>


@interface NSAppleEventDescriptor (QSTranslation)
+ (NSAppleEventDescriptor *)descriptorWithObjectAPPLE:(id)object;
- (id)objectValueAPPLE;
@end
