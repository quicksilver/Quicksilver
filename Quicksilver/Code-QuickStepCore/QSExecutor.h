#import <Foundation/Foundation.h>

@class QSBasicObject;

@class QSObject;
@class QSActions;
@class QSAction;
@class QSTaskController;

@class QSExecutor;
extern QSExecutor *QSExec; // Shared Instance

@protocol QSFileActionProvider
- (NSArray *)fileActionsFromPaths:(NSArray *)paths;
@end

@interface QSExecutor : NSObject {
	NSMutableArray *oldActionObjects;
	NSMutableDictionary *actionIdentifiers;
	NSMutableDictionary *directObjectTypes;
	NSMutableDictionary *directObjectFileTypes;

	NSMutableDictionary *actionSources;

	NSMutableArray *actionRanking;
	NSMutableDictionary *actionPrecedence;
	NSMutableDictionary *actionActivation;
	NSMutableDictionary *actionMenuActivation;
	NSMutableDictionary *actionIndirects;
	NSMutableDictionary *actionNames;
 }
+ (id)sharedInstance;

- (QSAction *)actionForIdentifier:(NSString *)identifier;
- (void)addActions:(NSArray *)actions;
- (void)addAction:(QSAction *)action;
- (NSArray *)actions;

- (NSArray *)rankedActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject;
- (NSArray *)rankedActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject shouldBypass:(BOOL)bypass;
- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject;
- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject;
- (QSObject *)performAction:(NSString *)action directObject:(QSObject *)dObject indirectObject:(QSObject *)iObject;

- (NSMutableArray *)actionsArrayForType:(NSString *)type;
- (NSMutableArray *)getArrayForSource:(NSString *)sourceid;
- (NSMutableArray *)makeArrayForSource:(NSString *)sourceid;

- (BOOL)actionIsEnabled:(QSAction*)action;
- (void)setAction:(QSAction *)action isEnabled:(BOOL)flag;
- (BOOL)actionIsMenuEnabled:(QSAction*)action;
- (void)setAction:(QSAction *)action isMenuEnabled:(BOOL)flag;

- (void)orderActions:(NSArray *)actions aboveActions:(NSArray *)lowerActions;
- (void)orderActions:(NSArray *)actions belowActions:(NSArray *)higherActions;
- (void)updateRanks;

- (void)noteNewName:(NSString *)name forAction:(QSObject *)aObject;
- (void)noteIndirect:(QSObject *)iObject forAction:(QSObject *)aObject;

- (void)loadFileActions;
- (void)writeActionsInfo;
@end

extern QSExecutor *QSExec; // Shared Instance
