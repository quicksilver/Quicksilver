

#import <Foundation/Foundation.h>

@class QSBasicObject;

@class QSAction;
@class QSTaskController;

@protocol QSFileActionProvider
- (NSArray *) fileActionsFromPaths:(NSArray *)paths;
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

- (void)loadFileActions;
- (void)addActions:(NSArray *)actions;
- (void)addAction:(QSAction *)action;
- (NSArray *)rankedActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject;
- (NSArray *)rankedActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject shouldBypass:(BOOL)bypass;
- (QSAction *)actionForIdentifier:(NSString *)identifier;
- (QSObject *)performAction:(NSString *)action directObject:(QSObject *)dObject indirectObject:(QSObject *)iObject;
- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject;
- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject;
- (void)addActionsFromDictionary:(NSDictionary *)actionsDictionary bundle:(NSBundle *)bundle;
- (NSArray *)actions;
- (NSMutableArray *)actionsArrayForType:(NSString *)type;
- (void) noteNewName:(NSString *)name forAction:(QSObject *)aObject;
- (void) setAction:(QSAction *)action isEnabled:(BOOL)flag;
- (void) setAction:(QSAction *)action isMenuEnabled:(BOOL)flag;
- (void) orderActions:(NSArray *)actions aboveActions:(NSArray *)lowerActions;
- (void) orderActions:(NSArray *)actions belowActions:(NSArray *)higherActions;
- (void) updateRanks;
- (void) writeActionsInfo;
- (void) noteIndirect:(QSObject *)iObject forAction:(QSObject *)aObject;
- (NSMutableArray *)getArrayForSource:(NSString *)sourceid;
- (NSMutableArray *)makeArrayForSource:(NSString *)sourceid;
@end

extern QSExecutor *QSExec;