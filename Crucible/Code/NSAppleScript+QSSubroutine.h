//
//  NSAppleScript+QSSubroutine.h
//  Quicksilver
//
//  Created by Alcor on Thu Aug 28 2003.

//

#import <Foundation/Foundation.h>


@interface NSAppleScript (QSSubroutine)
- (NSAppleEventDescriptor *)executeSubroutine:(NSString *)name arguments:(id)arguments error:(NSDictionary **)errorInfo;
@end
