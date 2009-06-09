
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
#define kActionResultTypes @"resultTypes" //Array
#define kActionDirectFileTypes @"directFileTypes" // Array

#define kActionRunsInMainThread @"runInMainThread" //BOOL
#define kActionDisplaysResult @"displaysResult" // BOOL
#define kActionIndirectOptional @"indirectOptional" //BOOL
#define kActionReverseArguments @"reverseArguments" //BOOL
#define kActionSplitPluralArguments @"splitPlural" //BOOL
#define kActionValidatesObject @"validatesObjects" //BOOL
#define kActionPrecedence @"precedence" //NSNumber (float)

#define kSourceBundleMeta @"sourceBundle"
#define kUserDataMeta @"userData"

@interface QSAction : QSObject {
	int rank;
	BOOL enabled;
	BOOL menuEnabled;
}
+ (void)setModifiersAreIgnored:(BOOL)flag;
+ (BOOL)modifiersAreIgnored;

+ (id)actionWithDictionary:(NSDictionary *)dict;
+ (id)actionWithDictionary:(NSDictionary *)dict identifier:(NSString *)ident;
+ (id)actionWithIdentifier:(NSString *)newIdentifier;

- (id)initWithIdentifier:(NSString *)newIdentifier bundle:(NSBundle *)bundle;
- (id)init;

- (QSBasicObject *)performOnDirectObject:(QSBasicObject *)dObject indirectObject:(QSBasicObject *)iObject;

- (QSAction *)alternate;

- (id)provider;
- (void)setProvider:(id)newProvider;

- (NSString *)class;
- (void)setClass:(NSString *)class;
- (SEL)action;
- (void)setAction:(SEL)newAction;

- (int)rank;
- (void)setRank:(int)newRank;
- (float)precedence;

- (BOOL)defaultEnabled;
- (BOOL)enabled;
- (void)setEnabled:(BOOL)flag;
- (BOOL)menuEnabled;
- (void)setMenuEnabled:(BOOL)flag;

- (int)argumentCount;
- (void)setArgumentCount:(int)newArgumentCount;
- (BOOL)canThread;

- (BOOL)displaysResult;
- (void)setDisplaysResult:(BOOL)flag;
- (BOOL)indirectOptional;
- (void)setIndirectOptional:(BOOL)flag;
- (BOOL)validatesObject;
- (void)setValidatesObject:(BOOL)flag;

- (NSArray *)directTypes;
- (NSArray *)directFileTypes;
- (NSArray *)indirectTypes;
- (NSArray *)resultTypes;

- (NSString *)commandFormat;

/* Those will disappear */
- (void)_setEnabled:(BOOL)flag;
- (void)_setRank:(int)newRank;
- (void)_setMenuEnabled:(BOOL)flag;

+ (id)actionWithDictionary:(NSDictionary *)dict identifier:(NSString *)ident bundle:(NSBundle *)bundle;
+ (id)actionWithIdentifier:(NSString *)newIdentifier bundle:(NSBundle *)bundle;

- (NSString *)commandDescriptionWithDirectObject:(QSBasicObject *)dObject indirectObject:(QSBasicObject *)iObject;
- (id)initWithActionDictionary:(NSDictionary *)dict identifier:(NSString *)ident bundle:(NSBundle *)bundle;

- (NSBundle *)bundle;
- (void)setBundle:(NSBundle *)aBundle;
@end



