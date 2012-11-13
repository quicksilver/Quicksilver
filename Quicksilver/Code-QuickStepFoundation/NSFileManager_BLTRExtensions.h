//
//  NSFileManager_CarbonExtensions.h
//  Quicksilver
//
//  Created by Alcor on Thu Apr 03 2003.
//  Copyright (c) 2003 Blacktree, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (Carbon)
- (BOOL)isVisible:(NSString *)chem;
- (BOOL)movePathToTrash:(NSString *)filepath;

@end

@interface NSFileManager (Scanning)
- (NSString *)resolveAliasAtPath:(NSString *)aliasFullPath;
- (NSString *)resolveAliasAtPathWithUI:(NSString *)aliasFullPath;
- (NSString *)typeOfFile:(NSString *)path;
- (NSArray *)itemsForPath:(NSString *)path depth:(NSInteger)depth types:(NSArray *)types;
- (NSDate *)modifiedDate:(NSString *)path depth:(NSInteger)depth;
- (NSDate *)pastOnlyModifiedDate:(NSString *)path;
- (NSDate *)path:(NSString *)path wasModifiedAfter:(NSDate *)date depth:(NSInteger)depth;
- (NSString *)fullyResolvedPathForPath:(NSString *)sourcePath;
- (NSString *)UTIOfFile:(NSString *)path;
- (NSString *)UTIOfURL:(NSURL *)fileURL;
@end

@interface NSFileManager (BLTRExtensions)
- (NSInteger) defaultDragOperationForMovingPaths:(NSArray *)sources toDestination:(NSString *)destination;

- (BOOL)createDirectoriesForPath:(NSString *)path;
- (BOOL)filesExistAtPaths:(NSArray *)paths;
- (NSDictionary *)conflictsForFiles:(NSArray *)files inDestination:(NSString *)destination;
@end
