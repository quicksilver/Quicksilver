//
//  QSFinderSource.m
//
//  Created by Jordan Kay on 2/5/12.
//  Adapted for File Tagging by Rob McBroom on 2013/09/09
//

#import "FileTaggingHandler.h"
#import "QSFinderSource.h"
#import "QSObject+FileTags.h"

@implementation QSFinderSource

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry
{
    // always rescan to pick up recent changes
    return NO;
}

- (NSArray *)objectsForEntry:(NSDictionary *)entry
{
    NSSet *tagNames = [[FileTaggingHandler sharedHandler] allTagNames];
    NSMutableArray *tags = [NSMutableArray array];
    for(NSString *tagName in tagNames) {
        QSObject *tag = [QSObject fileTagWithName:tagName];
        [tags addObject:tag];
    }
    return tags;
}

- (BOOL)loadChildrenForObject:(QSObject *)object
{
    NSMutableArray *children = [NSMutableArray array];
    // check for transient tag when navigating
    NSString *tagListString = [object objectForCache:kQSFileTagList];
    if (!tagListString) {
        // a normal tag from the catalog
        tagListString = [object objectForType:kQSFileTag];
    }
    [children addObjectsFromArray:[[FileTaggingHandler sharedHandler] filesAndRelatedTagsForTagList:tagListString]];
    [object setChildren:children];
    return YES;
}

- (BOOL)objectHasChildren:(QSObject *)object
{
    return YES;
}

- (NSImage *)iconForEntry:(NSDictionary *)entry
{
    return kQSFileTagIcon;
}

- (void)setQuickIconForObject:(QSObject *)object
{
    [object setIcon:kQSFileTagIcon];
}

- (BOOL)loadIconForObject:(QSObject *)object
{
    [self setQuickIconForObject:object];
    return YES;
}

@end
