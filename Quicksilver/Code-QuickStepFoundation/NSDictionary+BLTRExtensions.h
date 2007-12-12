//
//  NSDictionary+BLTRExtensions.h
//  Quicksilver
//
//  Created by Alcor on 3/27/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSDictionary (ExistingKeys)
- (NSArray *)keysSortedByValueUsingDescriptors:(NSArray *)descriptors;
@end
