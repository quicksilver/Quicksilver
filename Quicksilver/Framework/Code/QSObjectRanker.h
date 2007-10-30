//
//  QSObjectRanker.h
//  Quicksilver
//
//  Created by Alcor on 1/28/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QSStringRanker.h"

@class QSBasicObject,QSRankedObject;

@protocol QSObjectRanker
- (id)initWithObject:(QSBasicObject *)object;
- (double)scoreForAbbreviation:(NSString*)anAbbreviation inContext:(NSString *)context;
//- (NSIndexSet*)maskForAbbreviation:(NSString*)anAbbreviation inContext:(NSString *)context;
- (int)matchedStringForAbbreviation:(NSString*)anAbbreviation hitmask:(NSIndexSet **)hitmask inContext:(NSString *)context;
+ (NSMutableArray *)rankedObjectsForObjects:(NSArray *)objects withAbbreviation:(NSString*)anAbbreviation inContext:(NSString *)context;
- (QSRankedObject *)rankedObject:(QSBasicObject *)object forAbbreviation:(NSString*)anAbbreviation inContext:(NSString *)context withMnemonics:(NSDictionary *)mnemonics;
- (void)setOmitted:(BOOL)flag;
@end


@interface QSDefaultObjectRanker : NSObject {
	NSDictionary *usageMnemonics;
	NSObject <QSStringRanker> *nameRanker;
	NSObject <QSStringRanker> *labelRanker;
	BOOL omitted;
}

- (void)setOmitted:(BOOL)flag;
+ (NSMutableArray *)rankedObjectsForAbbreviation:(NSString*)anAbbreviation inSet:(NSArray *)set inContext:(NSString *)context mnemonicsOnly:(BOOL)mnemonicsOnly;
@end
