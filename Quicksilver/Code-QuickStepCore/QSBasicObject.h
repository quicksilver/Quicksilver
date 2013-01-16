//
//  QSBasicObject.h
//  Quicksilver
//
//  Created by Etienne on 13/09/08.
//  Copyright 2008 Etienne Samson. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QSCore/QSObjectRanker.h>

@class QSBasicObject;

// QSObject Protocols -  right now these aren't sufficient. QSBasicObject must be subclassed
@protocol QSObject
- (NSString *)identifier;
- (NSString *)label;
- (NSString *)name;
- (BOOL)enabled;
- (void)setEnabled:(BOOL)flag;
- (id)primaryObject;
- (NSBundle*)bundle;
- (void)setBundle:(NSBundle*)bundle;
- (BOOL)loadIcon;
- (BOOL)iconLoaded;
@end

@protocol QSObjectHierarchy
- (QSBasicObject *)parent;
- (BOOL)hasChildren;
- (NSArray *)children;
- (NSArray *)altChildren;
- (NSArray *)siblings;
- (NSArray *)altSiblings;
@end

@protocol QSObjectTyping
- (NSString *)primaryType;
- (NSArray *)types;
- (id)objectForType:(id)aType;
- (NSArray *)arrayForType:(id)aKey;
- (NSEnumerator *)enumeratorForType:(NSString *)aKey;
- (BOOL)containsType:(NSString *)aType;
@end

@interface QSBasicObject : NSObject <QSObject, QSObjectHierarchy, QSObjectTyping> {
@private
	NSObject <QSObjectRanker> *ranker;
    NSBundle                  *bundle;
}
- (NSUInteger)primaryCount;
- (NSImage *)icon;
- (NSString *)displayName;
- (NSString *)details;
- (NSString *)toolTip;
- (BOOL)drawIconInRect:(NSRect)rect flipped:(BOOL)flipped;
- (NSString *)kind;
- (void)becameSelected;
@end

@interface QSBasicObject (QSPasteboard)
- (BOOL)putOnPasteboard:(NSPasteboard *)pboard;
- (BOOL)putOnPasteboard:(NSPasteboard *)pboard includeDataForTypes:(NSArray *)includeTypes;
- (BOOL)putOnPasteboard:(NSPasteboard *)pboard declareTypes:(NSArray *)types includeDataForTypes:(NSArray *)includeTypes;
@end

@interface QSBasicObject (QSRanking)
- (Class)getRanker;
- (NSObject <QSObjectRanker> *)ranker;
- (void)updateMnemonics;
@end
