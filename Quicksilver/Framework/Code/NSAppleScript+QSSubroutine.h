//
//  NSAppleScript+QSSubroutine.h
//  Quicksilver
//
//  Created by Alcor on Thu Aug 28 2003.
//  Copyright (c) 2003 Blacktree. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSAppleScript (QSSubroutine)
- (NSAppleEventDescriptor *)executeSubroutine:(NSString *)name arguments:(id)arguments error:(NSDictionary **)errorInfo;
@end
