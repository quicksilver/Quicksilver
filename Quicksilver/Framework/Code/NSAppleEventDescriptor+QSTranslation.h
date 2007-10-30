//
//  NSAppleEventDescriptor+QSTranslation.h
//  Quicksilver
//
//  Created by Alcor on Thu Aug 28 2003.
//  Copyright (c) 2003 Blacktree. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSAppleEventDescriptor (QSTranslation)
+ (NSAppleEventDescriptor *)descriptorWithObjectAPPLE:(id)object;
- (id)objectValueAPPLE;
@end
