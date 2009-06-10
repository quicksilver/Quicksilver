


#import <Foundation/Foundation.h>
#import "QSObject.h"
@interface QSObject (QSFileObjectCreationProtocol)
- (id)initFileObject:(QSObject *)object ofType:(NSString *)type;
@end

@interface NSObject (QSFileCreatingHandlingProtocol)
- (NSData *)fileRepresentationForObject:(QSObject *)object;
- (NSString *)filenameForObject:(QSObject *)object;
@end

@interface QSBasicObject (FileHandling)
- (NSString *)singleFilePath;
- (NSString *)validSingleFilePath;
- (NSArray *)validPaths;
- (NSArray *)validPathsResolvingAliases:(BOOL)resolve;
- (int)fileCount;
@end

@interface NSObject (QSFilePreviewProvider)
- (NSImage *)iconForFile:(NSString *)path ofType:(NSString *)type;
@end

@interface QSObject (QSObjectFileHandling)
+ (QSObject *)fileObjectWithPath:(NSString *)path;
+ (QSObject *)fileObjectWithArray:(NSArray *)paths;
+ (NSArray *)fileObjectsWithPathArray:(NSArray *)pathArray;
+ (NSMutableArray *)fileObjectsWithURLArray:(NSArray *)pathArray;
- (id)initWithArray:(NSArray *)paths;
- (void)getNameFromFiles;
- (NSString *)kindOfFile:(NSString *)path;
- (NSString *)filesContainer;
- (NSString *)filesType;
- (QSObject *)fileObjectByMergingWith:(QSObject *)mergeObject;
- (BOOL)isApplication;
- (BOOL)isFolder;
- (NSString *)singleFileType;
- (NSArray *)validPaths;
- (NSArray *)validPathsResolvingAliases:(BOOL)resolve;
@end

