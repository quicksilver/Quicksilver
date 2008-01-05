#import "QSTrigger.h"

#define QSTriggerManagers @"QSTriggerManagers"
#define QSTriggerChangedNotification @"QSTriggerChanged"

@interface NSObject (QSTriggerManagerInformal)
- (void)initializeTrigger;
@end

@interface QSTriggerCenter : NSObject {
    NSMutableArray *triggers;
    NSMutableDictionary *triggersDict;
    NSMutableDictionary *commands;
}
+ (id) sharedInstance;
- (id) init;
//+ (QSCommand *) commandForTrigger:(QSTrigger *)trigger;
- (void) addTrigger:(QSTrigger *)trigger;
- (void) removeTrigger:(QSTrigger *)trigger;
//- (void) addTriggerForCommand:(QSCommand *)command;
//- (BOOL) enableTrigger:(QSTrigger *)entry;
//- (BOOL) disableTrigger:(QSTrigger *)entry;
- (void) triggerChanged:(QSTrigger *)trigger;
- (void) activateTriggers;
- (BOOL) executeTrigger:(QSTrigger *)trigger;
- (BOOL) executeTriggerID:(NSString *)triggerID;
- (QSTrigger *) triggerWithID:(NSString *)ident;
- (NSArray *) triggersWithParentID:(NSString *)ident;
- (void) writeTriggers;
- (NSDictionary *) triggersDict;
- (void) setTriggersDict:(NSDictionary *)newTriggersDict;
- (NSArray *) triggers;
//+ (NSString *) nameForTrigger:(QSTrigger *)trigger;
//- (void) setName:(NSString *)name forTrigger:(QSTrigger *)trigger;

@end
