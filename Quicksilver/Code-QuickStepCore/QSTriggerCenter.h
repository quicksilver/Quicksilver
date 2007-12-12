

#import <Foundation/Foundation.h>
#define QSTriggerManagers @"QSTriggerManagers"
#define QSTriggerChangedNotification @"QSTriggerChanged"

@class QSCommand;
@class QSTrigger;

@interface NSObject (QSTriggerManagerInformal)
- (void)initializeTrigger;
@end

@interface QSTriggerCenter : NSObject {
	NSMutableArray *triggers;
	NSMutableDictionary *triggersDict;
	NSMutableDictionary *commands;


}
+ (id)sharedInstance;
- (id)init;
//+ (QSCommand *)commandForTrigger:(QSTrigger *)trigger;
- (void)addTrigger:(QSTrigger *)trigger;
- (void)removeTrigger:(QSTrigger *)trigger;
//- (void)addTriggerForCommand:(QSCommand *)command;
//-(BOOL)enableTrigger:(QSTrigger *)entry;
//-(BOOL)disableTrigger:(QSTrigger *)entry;
- (void)triggerChanged:(QSTrigger *)trigger;
- (void)activateTriggers;
- (BOOL)executeTrigger:(QSTrigger *)trigger;
- (BOOL)executeTriggerID:(NSString *)triggerID;
- (QSTrigger *)triggerWithID:(NSString *)ident;
- (void)writeTriggers;
- (NSMutableDictionary *)triggersDict;
- (void)setTriggersDict:(NSMutableDictionary *)newTriggersDict;
- (NSMutableArray *)triggers;
//+ (NSString *)nameForTrigger:(QSTrigger *)trigger;
//- (void)setName:(NSString *)name forTrigger:(QSTrigger *)trigger;

- (NSArray *)triggersWithParentID:(NSString *)ident;
@end
