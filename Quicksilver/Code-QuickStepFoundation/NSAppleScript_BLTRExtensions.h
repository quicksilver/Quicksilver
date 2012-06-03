//
//  NSAppleScript_BLTRExtensions.h
//  Quicksilver
//
//  Created by Alcor on Thu Aug 28 2003.
//  Copyright (c) 2003 Blacktree. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSAppleScript (Subroutine)
- (NSAppleEventDescriptor *)executeSubroutine:(NSString *)name arguments:(id)arguments error:(NSDictionary **)errorInfo;
- (BOOL)storeInFile:(NSString *)path;
@end

@interface NSAppleScript (Constructors)
+ (NSAppleScript *)scriptWithContentsOfFile:(NSString *)path;
+ (NSAppleScript *)scriptWithContentsOfResource:(NSString *)path inBundle:(NSBundle *)bundle;
@end


@interface NSAppleEventDescriptor (CocoaConversion)
+ (NSAppleEventDescriptor *)descriptorWithObjectAPPLE:(id)object;
- (id)objectValueAPPLE;
@end

@interface NSAppleScript (FilePeeking)
+ (NSArray *)validHandlersFromArray:(NSArray *)array inScriptFile:(NSString *)path;
@end
