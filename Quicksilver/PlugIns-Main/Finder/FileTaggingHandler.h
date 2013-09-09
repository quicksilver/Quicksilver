//
//  FileTaggingHandler.h
//
//  Created by Jordan Kay on 2/7/12.
//  Adapted for File Tagging by Rob McBroom on 2013/09/09
//

#import <Foundation/Foundation.h>

#define kQSFileTag @"QSFileTag"
#define kQSFileTagTransient @"QSFileTagTransient"
#define kQSFileTagList @"QSFileTagList"
#define kQSFileTagIcon [QSResourceManager imageNamed:@"TagIcon"]

typedef void(^ QSFileTagQueryBlock)(MDQueryRef query, CFIndex i);

@interface FileTaggingHandler : NSObject

+ (FileTaggingHandler *)sharedHandler;
- (NSSet *)allTagNames;
- (NSArray *)filesWithTagList:(NSString *)tagList;
- (NSArray *)relatedTagNamesForTagList:(NSString *)tagList;
- (NSArray *)filesAndRelatedTagsForTagList:(NSString *)tagList;
- (NSArray *)tagNamesForFile:(NSString *)filePath;
- (void)addTags:(NSArray *)tags toFile:(NSString *)filePath;
- (void)removeTags:(NSArray *)tags fromFile:(NSString *)filePath;
- (void)setTags:(NSArray *)tags forFile:(NSString *)filePath;
- (NSArray *)tagsFromString:(NSString *)tagList;

@end
