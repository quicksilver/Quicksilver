//
//  QSObjectRanker.h
//  Quicksilver
//
//  Created by Alcor on 1/28/05.

//

#import <Cocoa/Cocoa.h>
#import "QSStringRanker.h"

@class QSBasicObject, QSRankedObject;

@protocol QSObjectRanker
+ (NSMutableArray *)rankedObjectsForObjects:(NSArray *)objects withAbbreviation:(NSString*)anAbbreviation inContext:(NSString *)context;
+ (id)rankerForObject:(QSBasicObject *)object;
- (id)initWithObject:(QSBasicObject *)object;
- (double)scoreForAbbreviation:(NSString*)anAbbreviation inContext:(NSString *)context;
- (NSString*)matchedStringForAbbreviation:(NSString*)anAbbreviation hitmask:(NSIndexSet **)hitmask inContext:(NSString *)context;
- (QSRankedObject *)rankedObject:(QSBasicObject *)object forAbbreviation:(NSString*)anAbbreviation inContext:(NSString *)context withMnemonics:(NSArray *)mnemonics mnemonicsOnly:(BOOL)mnemonicsOnly;
- (void)setOmitted:(BOOL)flag;
@end


@interface QSDefaultObjectRanker : NSObject {
	NSDictionary *usageMnemonics;
	NSObject <QSStringRanker> *nameRanker;
	NSObject <QSStringRanker> *labelRanker;
}
+ (NSMutableArray *)rankedObjectsForAbbreviation:(NSString*)anAbbreviation inSet:(NSArray *)set inContext:(NSString *)context mnemonicsOnly:(BOOL)mnemonicsOnly;
@end
