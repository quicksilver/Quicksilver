

#import <Foundation/Foundation.h>
#define QSTriggerManagers @"QSTriggerManagers"
#define QSTriggerChangedNotification @"QSTriggerChanged"

@class QSCommand;
@class QSTrigger;

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
- (void)interfaceActivated;
- (void)interfaceDeactivated;
- (BOOL)executeTrigger:(QSTrigger *)trigger;
- (BOOL)executeTriggerID:(NSString *)triggerID;
- (QSTrigger *)triggerWithID:(NSString *)ident;
- (NSArray *)triggersWithIDs:(NSArray *)idents;
- (void)writeTriggers;
- (void)writeTriggersNow;
- (NSMutableDictionary *)triggersDict;
- (void)setTriggersDict:(NSMutableDictionary *)newTriggersDict;
- (NSMutableArray *)triggers;
- (NSArray *)triggersWithParentID:(NSString *)ident;
- (NSDictionary *)triggerManagers;
@end
