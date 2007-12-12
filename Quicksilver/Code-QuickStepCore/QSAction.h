#import <Foundation/Foundation.h>
#import "QSObject.h"

// strings:
#define kActionClass @"actionClass"
#define kActionProvider @"actionProvider"
#define kActionSelector @"actionSelector"
#define kActionSendMessageToClass @"actionSendToClass"
#define kActionAlternate @"alternateAction"
#define kActionScript @"actionScript"
#define kActionHandler @"actionHandler"
#define kActionEventClass @"actionEventClass"
#define kActionEventID @"actionEventID"

#define kActionArgumentCount @"argumentCount" // Number, if undefined, calculates from selector

// strings:
#define kActionIcon @"icon"
#define kActionName @"name"
#define kActionUserData @"userData"
#define kActionEnabled @"enabled"
//#define kActionIdentifier @"id"

// arrays:
#define kActionDirectTypes @"directTypes"
#define kActionIndirectTypes @"indirectTypes"
#define kActionResultType @"resultTypes"

// BOOLs:
#define kActionRunsInMainThread @"runInMainThread"
#define kActionDisplaysResult @"displaysResult"
#define kActionIndirectOptional @"indirectOptional"
#define kActionReverseArguments @"reverseArguments"
#define kActionSplitPluralArguments @"splitPlural"

// NSNumber (float) :
#define kActionPrecedence @"precedence"

#define kSourceBundleMeta @"sourceBundle"
#define kUserDataMeta @"userData"

@interface QSAction : QSObject {
	int rank;
	BOOL enabled;
	BOOL menuEnabled;
}
#if 0
+ (void)setModifiersAreIgnored:(BOOL)flag;
+ (BOOL)modifiersAreIgnored;
#endif

+ (void)initialize;
+ (id)actionWithIdentifier:(NSString *)newIdentifier;
+ (id)actionWithIdentifier:(NSString *)newIdentifier bundle:(NSBundle *)bundle; // Creates actions using Localization from this bundle
- (id)initWithIdentifier:(NSString *)newIdentifier bundle:(NSBundle *)bundle;
//- (float) rankModification;
//- (void)setRankModification:(float)aRankModification;
	//- (NSString *)identifier ;
- (id)provider ;
- (void)setProvider:(id)newProvider ;
- (void)setAction:(SEL)newAction ;
//- (void)setArgumentCount:(int)newArgumentCount ;
- (void)setReverse:(BOOL)flag ;
- (BOOL)canThread ;
- (void)setIndirectOptional:(BOOL)flag;
- (id)userData;
- (void)setUserData:(id)anUserData;
	//- (BOOL)displaysResult;
- (void)setDisplaysResult:(BOOL)flag;
- (QSAction *)alternate;
- (int) rank;
- (void)setRank:(int)newRank;
- (BOOL)enabled;
- (void)setEnabled:(BOOL)flag;

- (float) precedence;
- (NSNumber *)defaultEnabled;
- (void)_setEnabled:(BOOL)flag;
- (void)_setRank:(int)newRank;
- (void)_setMenuEnabled:(BOOL)flag;
@end


@interface QSObject (ActionHandling)
+ (QSAction *)actionWithDictionary:(NSDictionary *)dict identifier:(NSString *)ident bundle:(NSBundle *)bundle;
- (id)initWithActionDictionary:(NSDictionary *)dict identifier:(NSString *)ident bundle:(NSBundle *)bundle;

- (QSObject *)performOnDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject;
- (NSString *)commandDescriptionWithDirectObject:(QSBasicObject *)dObject indirectObject:(QSBasicObject *)iObject;
- (int) argumentCount;
- (NSMutableDictionary *)actionDict;

- (NSBundle *)bundle;
- (void)setBundle:(NSBundle *)aBundle;
@end

@interface QSActionHandler : NSObject
@end
