//
//  QSObjectRanker.h
//  Quicksilver
//
//  Created by Alcor on 1/28/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QSCore/QSStringRanker.h>

@class QSBasicObject, QSRankedObject;

/* Ranking options */
extern NSString *QSRankingMnemonicsOnly;    // BOOL
extern NSString *QSRankingObjectsInSet;     // NSArray
extern NSString *QSRankingContext;          // NSString, unused ?
extern NSString *QSRankingUsePureString;    // BOOL
extern NSString *QSRankingIncludeOmitted;   // BOOL. Specifies whether the ranker should include omitted catalog items or not

@protocol QSObjectRanker
- (id)initWithObject:(QSBasicObject *)object;
//- (float)scoreForAbbreviation:(NSString*)anAbbreviation inContext:(NSString *)context;
//- (NSIndexSet*)maskForAbbreviation:(NSString*)anAbbreviation inContext:(NSString *)context;
- (QSRankedObject *)rankedObject:(QSBasicObject *)object forAbbreviation:(NSString*)anAbbreviation options:(NSDictionary *)options;
- (NSString*)matchedStringForAbbreviation:(NSString*)anAbbreviation hitmask:(NSIndexSet **)hitmask inContext:(NSString *)context;

@optional
- (QSRankedObject *)rankedObject:(QSBasicObject *)object forAbbreviation:(NSString*)anAbbreviation inContext:(NSString *)context withMnemonics:(NSArray *)mnemonics mnemonicsOnly:(BOOL)mnemonicsOnly DEPRECATED_ATTRIBUTE;
@end


@interface QSDefaultObjectRanker : NSObject <QSObjectRanker> {
	NSDictionary *usageMnemonics;
	NSObject <QSStringRanker> *nameRanker;
	NSObject <QSStringRanker> *labelRanker;
}
+ (NSMutableArray *)rankedObjectsForAbbreviation:(NSString *)anAbbreviation options:(NSDictionary *)options;
@end
