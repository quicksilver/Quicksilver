#import <Foundation/Foundation.h>
#import <QSCore/QSClangAnalyzer.h>
#import <QSCore/QSObject.h>

NSArray *QSGetRecentDocumentsForBundle(NSString *bundleIdentifier);

@protocol QSFileObjectCreationProtocol
- (id)createFileObject:(QSObject *)object ofType:(NSString *)type;
@end

@protocol QSFileCreatingHandlingProtocol
- (NSData *)fileRepresentationForObject:(QSObject *)object;
- (NSString *)filenameForObject:(QSObject *)object;
@end
@interface QSFileSystemObjectHandler : NSObject <QSObjectHandler>

// Added by Patrick Robertson 30/06/11 in Pull #388. QSObject_FileHandling.h/.m are a mess and it's unclear as to wether
// this is required. Any developers working on tidying these files should check the necessity/requirement of this definition
- (NSArray *)actionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject;
@end

@interface QSBasicObject (FileHandling)
- (NSString *)singleFilePath;
- (NSString *)validSingleFilePath;
- (NSArray *)validPaths;
- (NSArray *)validPathsResolvingAliases:(BOOL)resolve;
- (NSInteger)fileCount;
@end

@interface NSObject (QSFilePreviewProvider)
- (NSImage *)iconForFile:(NSString *)path ofType:(NSString *)type;
@end

@interface QSObject (QSObjectFileHandling)
+ (QSObject *)fileObjectWithPath:(NSString *)path;
+ (QSObject *)fileObjectWithFileURL:(NSURL *)fileURL;
+ (QSObject *)fileObjectWithArray:(NSArray *)paths;
+ (NSArray *)fileObjectsWithPathArray:(NSArray *)pathArray;
+ (NSMutableArray *)fileObjectsWithURLArray:(NSArray *)URLArray;
- (id)initWithArray:(NSArray *)paths;
- (void)getNameFromFiles;
- (NSString *)kindOfFile:(NSString *)path;
- (NSString *)filesContainer;
- (NSString *)filesType;
- (QSObject *)resolvedAliasObject;
- (BOOL)isFileObject;
- (BOOL)isApplication;
- (BOOL)isExecutable;
- (BOOL)canBeExecutedByScript;
- (BOOL)isDirectory; // YES for all directories
- (BOOL)isFolder;    // YES for directories that aren't packages
- (BOOL)isPackage;
- (BOOL)isAlias;
- (BOOL)isOnLocalVolume;
- (BOOL)isIcloudFile;
- (BOOL)isClipping;
- (NSString *)fileExtension;
- (NSString *)fileUTI;
@end

