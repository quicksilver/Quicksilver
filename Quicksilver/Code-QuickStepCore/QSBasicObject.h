//
//  QSBasicObject.h
//  Quicksilver
//
//  Created by Etienne on 13/09/08.
//  Copyright 2008 Etienne Samson. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QSCore/QSObjectRanker.h>

@protocol QSObject
- (id)initWithDictionary:(NSDictionary*)dictionary;
- (NSMutableDictionary *)dictionaryRepresentation;
- (NSString *)label;
- (NSString *)name;
- (NSString *)primaryType;
- (id)primaryObject;
- (NSBundle*)bundle;
- (void)setBundle:(NSBundle*)bundle;
- (id)objectForType:(id)aType;
- (NSArray *)arrayForType:(id)aKey;
- (NSArray *)types;
- (id)primaryObject;
- (BOOL)loadIcon;
- (BOOL)iconLoaded;
@end

@class QSBasicObject;
@protocol QSObjectHierarchy
- (QSBasicObject *)parent;
- (BOOL)hasChildren;
- (NSArray *)children;
- (NSArray *)altChildren;
- (NSArray *)siblings;
- (NSArray *)altSiblings;
@end

@interface QSBasicObject : NSObject <QSObject, QSObjectHierarchy> {
@public
	NSObject <QSObjectRanker> *ranker;
}
+ (id)objectWithDictionary:(NSDictionary*)dictionary;
- (int)primaryCount;
- (BOOL)loadIcon;
- (NSImage *)icon;
- (NSString *)displayName;
- (NSString *)details;
- (NSString *)toolTip;
- (float)score;
- (int)order;
- (NSString *)description;
//- (float) rankModification;
- (NSString *)identifier;
- (NSEnumerator *)enumeratorForType:(NSString *)aKey;
- (NSComparisonResult)nameCompare:(QSBasicObject *)object;
- (BOOL)putOnPasteboard:(NSPasteboard *)pboard;
- (BOOL)putOnPasteboard:(NSPasteboard *)pboard includeDataForTypes:(NSArray *)includeTypes;
- (BOOL)putOnPasteboard:(NSPasteboard *)pboard declareTypes:(NSArray *)types includeDataForTypes:(NSArray *)includeTypes;
- (id <QSObjectRanker>) getRanker;
- (id <QSObjectRanker>) ranker;
- (void)setOmitted:(BOOL)flag;
- (void)updateMnemonics;
- (BOOL)drawIconInRect:(NSRect)rect flipped:(BOOL)flipped;
- (NSString *)kind;
- (void)setOmitted:(BOOL)flag ;
- (BOOL)containsType:(NSString *)aType;
- (QSBasicObject *)resolvedObject;
- (void)becameSelected;
@end
