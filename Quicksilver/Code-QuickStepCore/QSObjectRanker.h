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

@protocol QSObjectRanker
- (id)initWithObject:(QSBasicObject *)object;
//- (float)scoreForAbbreviation:(NSString*)anAbbreviation inContext:(NSString *)context;
//- (NSIndexSet*)maskForAbbreviation:(NSString*)anAbbreviation inContext:(NSString *)context;
- (NSString*)matchedStringForAbbreviation:(NSString*)anAbbreviation hitmask:(NSIndexSet **)hitmask inContext:(NSString *)context;
- (QSRankedObject *)rankedObject:(QSBasicObject *)object forAbbreviation:(NSString*)anAbbreviation inContext:(NSString *)context withMnemonics:(NSArray *)mnemonics mnemonicsOnly:(BOOL)mnemonicsOnly;
@end


@interface QSDefaultObjectRanker : NSObject <QSObjectRanker> {
	NSDictionary *usageMnemonics;
	NSObject <QSStringRanker> *nameRanker;
	NSObject <QSStringRanker> *labelRanker;
}
+ (NSMutableArray *)rankedObjectsForAbbreviation:(NSString*)anAbbreviation inSet:(NSArray *)set inContext:(NSString *)context mnemonicsOnly:(BOOL)mnemonicsOnly;
@end
