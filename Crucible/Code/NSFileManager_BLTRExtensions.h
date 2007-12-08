//
//  NSFileManager_CarbonExtensions.h
//  Quicksilver
//
//  Created by Alcor on Thu Apr 03 2003.

//

#import <Foundation/Foundation.h>
NSString *QSUTIOfFile(NSString *path);
NSString *QSUTIWithLSInfoRec(NSString *path,LSItemInfoRecord *infoRec);

@interface NSFileManager (Carbon)
- (bool) isVisible:(NSString *)chem;
- (BOOL)movePathToTrash:(NSString *)filepath;

@end

@interface NSFileManager (Scanning)
- (NSString *)resolveAliasAtPath:(NSString *)aliasFullPath;
- (NSString *)resolveAliasAtPathWithUI:(NSString *)aliasFullPath;
- (NSString *)typeOfFile:(NSString *)path;
- (NSArray *) itemsForPath:(NSString *)path depth:(int)depth types:(NSArray *)types;
- (NSDate *) modifiedDate:(NSString *)path depth:(int)depth;
- (NSDate *)pastOnlyModifiedDate:(NSString *)path;
- (NSDate *)path:(NSString *)path wasModifiedAfter:(NSDate *)date depth:(int)depth;
- (NSString *)fullyResolvedPathForPath:(NSString *)sourcePath;
- (NSString *)UTIOfFile:(NSString *)path;
@end

@interface NSFileManager (BLTRExtensions)
- (int)defaultDragOperationForMovingPaths:(NSArray *)sources toDestination:(NSString *)destination;
    
- (BOOL)createDirectoriesForPath:(NSString *)path;
- (BOOL)filesExistAtPaths:(NSArray *)paths;
- (NSDictionary *)conflictsForFiles:(NSArray *)files inDestination:(NSString *)destination;
@end