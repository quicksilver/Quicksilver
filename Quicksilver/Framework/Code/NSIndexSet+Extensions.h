//
//  NSIndexSet+Extensions.h
//  Quicksilver
//
//  Created by Alcor on 3/16/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSIndexSet (ArrayInit)
+ (NSIndexSet *)indexSetFromArray:(NSArray *)indexes;
@end
