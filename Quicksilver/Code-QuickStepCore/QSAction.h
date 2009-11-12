#import <Foundation/Foundation.h>
#import <QSCore/QSObject.h>
#import <QSCore/QSObjectRanker.h>

/* TODO : Split this in QSAppleScript action ? */

// strings:
#define kActionClass                @"actionClass"
#define kActionProvider             @"actionProvider"
#define kActionSelector             @"actionSelector"
#define kActionSendMessageToClass   @"actionSendToClass"
#define kActionAlternate            @"alternateAction"
#define kActionScript               @"actionScript"
#define kActionHandler              @"actionHandler"
#define kActionEventClass           @"actionEventClass"
#define kActionEventID              @"actionEventID"

#define kActionArgumentCount        @"argumentCount" // Number, if undefined, calculates from selector

// strings:
#define kActionIcon                 @"icon"
#define kActionName                 @"name"
#define kActionUserData             @"userData"
#define kActionIdentifier           @"id"

// arrays:
#define kActionDirectTypes          @"directTypes"
#define kActionIndirectTypes        @"indirectTypes"
#define kActionResultType           @"resultTypes" // Unused ?

// BOOLs:
#define kActionRunsInMainThread     @"runInMainThread"
#define kActionDisplaysResult       @"displaysResult"
#define kActionIndirectOptional     @"indirectOptional"
#define kActionReverseArguments     @"reverseArguments"
#define kActionSplitPluralArguments @"splitPlural"
#define kActionValidatesObjects     @"validatesObjects"
#define kActionInitialize           @"initialize"
#define kActionEnabled              @"enabled"

// NSNumber (float) :
#define kActionPrecedence @"precedence"

@interface QSAction : QSObject {
	int rank;
}
#if 0
+ (void)setModifiersAreIgnored:(BOOL)flag;
+ (BOOL)modifiersAreIgnored;
#endif

+ (id)actionWithDictionary:(NSDictionary *)dict;
+ (id)actionWithDictionary:(NSDictionary *)dict identifier:(NSString *)ident;
+ (id)actionWithIdentifier:(NSString *)newIdentifier;
+ (id)actionWithIdentifier:(NSString *)newIdentifier bundle:(NSBundle *)newBundle;

- (id)initWithDictionary:(NSDictionary *)dict identifier:(NSString *)ident bundle:(NSBundle *)bundle;
- (id)initWithIdentifier:(NSString *)newIdentifier bundle:(NSBundle *)newBundle;

- (QSObject *)performOnDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject;

- (QSAction *)alternate;

- (NSMutableDictionary *)actionDict;

- (id)provider;
- (void)setProvider:(id)newProvider;

- (SEL)action;
- (void)setAction:(SEL)newAction;

- (int)rank;
- (void)setRank:(int)newRank;
- (float)precedence;
- (BOOL)enabled;
- (void)setEnabled:(BOOL)flag;
- (BOOL)menuEnabled;
- (void)setMenuEnabled:(BOOL)flag;
- (BOOL)defaultEnabled;

- (int)argumentCount;
- (void)setArgumentCount:(int)newArgumentCount;
- (BOOL)reverse;
- (void)setReverse:(BOOL)flag;
- (BOOL)canThread;
- (BOOL)indirectOptional;
- (void)setIndirectOptional:(BOOL)flag;
- (BOOL)displaysResult;
- (void)setDisplaysResult:(BOOL)flag;

- (NSArray*)directTypes;
- (void)setDirectTypes:(NSArray*)types;
- (NSArray*)indirectTypes;
- (void)setIndirectTypes:(NSArray*)types;
/*- (NSArray*)resultTypes;
- (void)setResultTypes:(NSArray*)types;*/

- (id)objectForKey:(NSString*)key;

- (NSString *)commandFormat;
@end

@interface QSActionHandler : NSObject
@end
