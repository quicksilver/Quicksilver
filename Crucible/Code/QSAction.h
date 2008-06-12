
#import "QSObject.h"

#define kActionClass @"actionClass" // String
#define kActionProvider @"actionProvider" // String
#define kActionSelector @"actionSelector" // String

#define kActionSendMessageToClass @"actionSendToClass" // String
#define kActionAlternate @"alternateAction" // String


#define kActionScript @"actionScript" // String
#define kActionHandler @"actionHandler" // String

#define kActionEventClass @"actionEventClass" // String
#define kActionEventID @"actionEventID" // String


#define kActionArgumentCount @"argumentCount" // Number, if undefined, calculates from selector

#define kActionIcon @"icon" // NSString
#define kActionName @"name" // NSString
#define kActionUserData @"userData" //String

#define kActionEnabled @"enabled" //String
//#define kActionIdentifier @"id" //String

#define kActionDirectTypes @"directTypes" // Array
#define kActionIndirectTypes @"indirectTypes" // Array
#define kActionResultType @"resultTypes" //Array

#define kActionRunsInMainThread @"runInMainThread" //BOOL
#define kActionDisplaysResult @"displaysResult" // BOOL
#define kActionIndirectOptional @"indirectOptional" //BOOL
#define kActionReverseArguments @"reverseArguments" //BOOL
#define kActionSplitPluralArguments @"splitPlural" //BOOL
#define kActionPrecedence @"precedence" //NSNumber (float)

#define kSourceBundleMeta @"sourceBundle"
#define kUserDataMeta @"userData"

@interface QSAction : QSObject {
	int rank;
	BOOL enabled;
	BOOL menuEnabled;
}
+ (void) setModifiersAreIgnored:(BOOL)flag;
+ (BOOL) modifiersAreIgnored;

+ (void) initialize;
+ (id)actionWithIdentifier:(NSString *)newIdentifier;
+ (id)actionWithIdentifier:(NSString *)newIdentifier bundle:(NSBundle *)bundle; // Creates actions using Localization from this bundle
- (id)initWithIdentifier:(NSString *)newIdentifier bundle:(NSBundle *)bundle;
- (float)rankModification;
- (void)setRankModification:(float)aRankModification;
	//- (NSString *)identifier ;
- (id)provider ;
- (void)setProvider:(id)newProvider ;
- (void)setAction:(SEL)newAction ;
- (void)setArgumentCount:(int)newArgumentCount ;
- (void)setReverse:(BOOL)flag ;
- (BOOL)canThread ;
- (void)setIndirectOptional:(BOOL)flag;
- (id)userData;
- (void)setUserData:(id)anUserData;
	//- (BOOL)displaysResult;
- (void)setDisplaysResult:(BOOL)flag;
- (QSAction *)alternate;
- (int)rank;
- (void)setRank:(int)newRank;
- (BOOL)enabled;
- (void)setEnabled:(BOOL)flag;

- (float)precedence;
- (NSNumber *)defaultEnabled;
- (void)_setEnabled:(BOOL)flag;
- (void)_setRank:(int)newRank;
- (void)_setMenuEnabled:(BOOL)flag;
@end


@interface QSObject (ActionHandling)
+ (QSAction *)actionWithDictionary:(NSDictionary *)dict identifier:(NSString *)ident bundle:(NSBundle *)bundle;
- (id)initWithActionDictionary:(NSDictionary *)dict identifier:(NSString *)ident bundle:(NSBundle *)bundle;

- (QSObject *) performOnDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject;
- (NSString *) commandDescriptionWithDirectObject:(QSBasicObject *)dObject indirectObject:(QSBasicObject *)iObject;
- (int)argumentCount;
- (NSMutableDictionary *)actionDict;

- (NSBundle *)bundle;
- (void)setBundle:(NSBundle *)aBundle;
@end





@interface QSActionHandler : NSObject 
@end



