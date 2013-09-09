//
//  QSFinderAction.m
//
//  Created by Jordan Kay on 2/5/12.
//  Adapted for File Tagging by Rob McBroom on 2013/09/09
//

#import "FileTaggingHandler.h"
#import "QSFinderAction.h"
#import "QSObject+FileTags.h"

#define ADD_TAGS_ACTION @"AddFileTags"
#define REMOVE_TAGS_ACTION @"RemoveFileTags"
#define SET_TAGS_ACTION @"SetFileTags"
#define kQSFileTagsPreset @"QSPresetFileTags"

@implementation QSFinderAction

- (NSArray *)sharedTagNamesForFiles:(QSObject *)files
{
    NSMutableSet *tagNames = [NSMutableSet set];
    for(QSObject *object in [files splitObjects]) {
        NSSet *nextTags = [NSSet setWithArray:[[FileTaggingHandler sharedHandler] tagNamesForFile:[object objectForType:NSFilenamesPboardType]]];
        if([tagNames count]) {
            [tagNames intersectSet:nextTags];
        } else {
            [tagNames addObjectsFromArray:[nextTags allObjects]];
        }
    }
    return [tagNames allObjects];
}

- (NSArray *)tagsForFiles:(QSObject *)files
{
    NSMutableArray *tags = [NSMutableArray array];
    NSArray *tagNames = [self sharedTagNamesForFiles:files];
    for(NSString *tagName in tagNames) {
        QSObject *tag = [QSObject fileTagWithName:tagName];
        [tags addObject:tag];
    }
    return tags;
}

- (QSObject *)showTagsForFiles:(QSObject *)files
{
    NSArray *tags = [self tagsForFiles:files];
    [[QSReg preferredCommandInterface] showArray:[NSMutableArray arrayWithArray:tags]];
    return nil;
}

- (QSObject *)addToFiles:(QSObject *)files tagList:(QSObject *)tagList
{
    QSObject *tagsToAdd = [self tagObjectFromMixedObject:tagList];
    NSArray *tagNames = [tagsToAdd arrayForType:kQSFileTag];
    for(QSObject *file in [files splitObjects]) {
        [[FileTaggingHandler sharedHandler] addTags:tagNames toFile:[file objectForType:NSFilenamesPboardType]];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"QSEventNotification" object:@"QSFileTagged" userInfo:@{@"object": files}];
    [self addCatalogTags:tagsToAdd];
    return nil;
}

- (QSObject *)removeFromFiles:(QSObject *)files tags:(QSObject *)tags
{
    NSMutableArray *tagNames = [NSMutableArray array];
    for(QSObject *tag in [tags splitObjects]) {
        [tagNames addObject:[tag objectForType:kQSFileTag]];
    }
    for(QSObject *file in [files splitObjects]) {
        [[FileTaggingHandler sharedHandler] removeTags:tagNames fromFile:[file objectForType:NSFilenamesPboardType]];
    }
    [self updateTagsOnDisk];
    return nil;
}

- (QSObject *)setToFiles:(QSObject *)files tagList:(QSObject *)tagList
{
    QSObject *tagsToSet = [self tagObjectFromMixedObject:tagList];
    NSArray *tagNames = [tagsToSet arrayForType:kQSFileTag];
    FileTaggingHandler *OMHandler = [FileTaggingHandler sharedHandler];
    for(QSObject *file in [files splitObjects]) {
        [OMHandler setTags:tagNames forFile:[file objectForType:NSFilenamesPboardType]];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"QSEventNotification" object:@"QSFileTagged" userInfo:@{@"object": files}];
    [self addCatalogTags:tagsToSet];
    return nil;
}

- (QSObject *)clearTagsFromFiles:(QSObject *)files
{
    [self setToFiles:files tagList:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"QSEventNotification" object:@"QSFileTagsCleared" userInfo:@{@"object": files}];
    [self updateTagsOnDisk];
    return nil;
}

- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)files 
{ 
    if([action isEqualToString:REMOVE_TAGS_ACTION]) {
        // offer to remove tags common to all selected files
        NSMutableArray *tagsInCommon = [NSMutableArray array];
        for (NSString *tagName in [self sharedTagNamesForFiles:files]) {
            QSObject *tag = [QSObject fileTagWithName:tagName];
            [tagsInCommon addObject:tag];
        }
        return tagsInCommon;
    } else {
        NSArray *allTags = [QSLib scoredArrayForType:kQSFileTag];
        if (![allTags count]) {
            // no existing tags - text entry mode
            return [NSArray arrayWithObject:[QSObject textProxyObjectWithDefaultValue:@"tag name"]];
        }
        if([action isEqualToString:SET_TAGS_ACTION]) {
            // offer to set any known tag
            return allTags;
        } else if ([action isEqualToString:ADD_TAGS_ACTION]) {
            // offer to add tags not already assigned to the selected files
            NSMutableSet *allTagNames = [NSMutableSet setWithArray:[allTags arrayByPerformingSelector:@selector(objectForType:) withObject:kQSFileTag]];
            NSSet *tagsInCommon = [NSSet setWithArray:[self sharedTagNamesForFiles:files]];
            [allTagNames minusSet:tagsInCommon];
            NSMutableArray *newTags = [NSMutableArray array];
            for (NSString *tagName in allTagNames) {
                QSObject *tag = [QSObject fileTagWithName:tagName];
                [newTags addObject:tag];
            }
            return newTags;
        }
    }
    return nil;
} 

- (void)addCatalogTags:(QSObject *)tags
{
    // only rescan the catalog if the action created a new tag
    NSMutableArray *tagNames = [[tags arrayForType:kQSFileTag] mutableCopy];
    NSArray *allTags = [QSLib arrayForType:kQSFileTag];
    NSArray *allTagNames = [allTags arrayByPerformingSelector:@selector(objectForType:) withObject:kQSFileTag];
    [tagNames removeObjectsInArray:allTagNames];
    if ([tagNames count]) {
        // at least one new tag - rescan
        [self updateTagsOnDisk];
    }
    [tagNames release];
}

- (void)updateTagsOnDisk
{
    // wait a few seconds for changes to appear in the filesystem
    sleep(4);
    // rescan the catalog entry
    [[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryInvalidated object:kQSFileTagsPreset];
}

- (QSObject *)tagObjectFromMixedObject:(QSObject *)inputTags
{
    // we could get tags from the catalog, or tags typed by hand
    // so turn them all into tag objects and combine them
    NSMutableSet *tagObjects = [NSMutableSet set];
    for (QSObject *tag in [inputTags splitObjects]) {
        if ([[tag primaryType] isEqualToString:kQSFileTag]) {
            [tagObjects addObject:tag];
        } else {
            // tags typed by hand
            // could be one tag per string, or several in one comma-delimited string
            NSArray *tagNames = [[FileTaggingHandler sharedHandler] tagsFromString:[tag stringValue]];
            for (NSString *tagName in tagNames) {
                QSObject *manualTag = [QSObject fileTagWithName:tagName];
                [tagObjects addObject:manualTag];
            }
        }
    }
    return [QSObject objectByMergingObjects:[tagObjects allObjects]];
}

@end
