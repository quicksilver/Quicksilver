//
//  NSDictionary+BLTRExtensions.h
//  Quicksilver
//
//  Created by Alcor on 3/27/05.

//

#import <Cocoa/Cocoa.h>


@interface NSDictionary (ExistingKeys)
- (NSArray *)keysSortedByValueUsingDescriptors:(NSArray *)descriptors;
@end