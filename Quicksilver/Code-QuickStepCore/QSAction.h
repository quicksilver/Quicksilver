#import <Foundation/Foundation.h>
#import <QSCore/QSObject.h>
#import <QSCore/QSObjectRanker.h>

@interface QSAction : QSObject {
	NSInteger rank;
}
#if 0
+ (void)setModifiersAreIgnored:(BOOL)flag;
+ (BOOL)modifiersAreIgnored;
#endif

+ (id)actionWithDictionary:(NSDictionary *)dict;
+ (id)actionWithDictionary:(NSDictionary *)dict identifier:(NSString *)ident;
+ (id)actionWithIdentifier:(NSString *)newIdentifier;
+ (id)actionWithDictionary:(NSDictionary *)dict identifier:(NSString *)ident bundle:(NSBundle *)bundle;
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

/**
 * Use a predefined block as an action method. Useful for programatically creating many similar actions.
 *
 * @param actionBlock A block that does the action's work
 * @param selectorName A selector name like "openThing:"
 *
 * @return YES if the action method was added to the provider, otherwise NO
 *
 * Example action block with no indirect object:
 * QSObject *(^actionBlock)(id, QSObject *) = ^ QSObject *(id _self, QSObject *dObject) {
 * 	   // action code
 * 	   return nil;
 * };
 */
- (BOOL)setActionUisngBlock:(QSObject *(^)(id, QSObject *))actionBlock  selectorName:(NSString *)selName;

/**
 * Use a predefined block as an action method. Useful for programatically creating many similar actions.
 *
 * @param actionBlock A block that does the action's work
 * @param selectorName A selector name like "openThing:usingOtherThing:"
 *
 * @return YES if the action method was added to the provider, otherwise NO
 *
 * Example action block with an indirect object:
 * QSObject *(^actionBlock)(id, QSObject *, QSObject *) = ^ QSObject *(id _self, QSObject *dObject, QSObject *iObject) {
 * 	   // action code
 * 	   return nil;
 * };
 */
- (BOOL)setActionWithIndirectUisngBlock:(QSObject *(^)(id, QSObject *, QSObject *))actionBlock  selectorName:(NSString *)selName;

- (NSInteger)rank;
- (void)setRank:(NSInteger)newRank;
- (CGFloat)precedence;
- (void)setPrecedence:(CGFloat)precedence;
- (BOOL)enabled;
- (void)setEnabled:(BOOL)flag;
- (BOOL)menuEnabled;
- (void)setMenuEnabled:(BOOL)flag;
- (BOOL)defaultEnabled;

- (NSInteger)argumentCount;
- (void)setArgumentCount:(NSInteger)newArgumentCount;
- (BOOL)reverse;
- (void)setReverse:(BOOL)flag;
- (BOOL)canThread;
- (BOOL)indirectOptional;
- (void)setIndirectOptional:(BOOL)flag;
- (BOOL)validatesObjects;
- (void)setValidatesObjects:(BOOL)flag;

// resolveProxy is a BOOL set in an action's dict to specify whether an object should be resolved
// before being sent to an action. Action's like 'assign abbreviation...' should not resolve the proxy
- (BOOL)resolvesProxy;
- (void)setResolvesProxy:(BOOL)flag;

- (BOOL)displaysResult;
- (void)setDisplaysResult:(BOOL)flag;

- (NSArray*)directTypes;
- (void)setDirectTypes:(NSArray*)types;
- (NSArray*)directFileTypes;
- (void)setDirectFileTypes:(NSArray *)types;
- (NSArray*)indirectTypes;
- (void)setIndirectTypes:(NSArray *)types;
/*- (NSArray*)resultTypes;
- (void)setResultTypes:(NSArray*)types;*/

- (id)objectForKey:(NSString*)key;

- (NSString *)commandFormat;
- (void)setCommandFormat:(NSString *)commandFormat;
@end

@interface QSActionHandler : NSObject
@end
