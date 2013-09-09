//
//  QSObject+FileTags.m
//
//  Created by Rob McBroom on 2013/02/13.
//

#import "QSObject+FileTags.h"
#import "FileTaggingHandler.h"

@implementation QSObject (FileTags)

+ (QSObject *)fileTagWithName:(NSString *)tagName
{
    NSString *tagID = [NSString stringWithFormat:@"%@:%@", kQSFileTag, tagName];
    // try to get an existing tag from the catalog
    QSObject *tag = [self objectWithIdentifier:tagID];
    if (!tag) {
        // create a new tag object from scratch
        tag = [self objectWithName:tagName];
        [tag setIdentifier:tagID];
        [tag setObject:tagName forType:kQSFileTag];
        [tag setPrimaryType:kQSFileTag];
    }
    return tag;
}

@end
