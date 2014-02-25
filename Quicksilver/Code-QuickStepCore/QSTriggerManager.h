//
//  QSTriggerManager.h
//  Quicksilver
//
//  Created by Alcor on 11/9/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "QSTrigger.h"

@protocol QSTriggerManager
- (NSString *)name;
- (NSImage *)image;
- (void)initializeTrigger:(QSTrigger *)trigger;
- (BOOL)enableTrigger:(QSTrigger *)trigger;
- (BOOL)disableTrigger:(QSTrigger *)trigger;
- (NSString *)descriptionForTrigger:(QSTrigger *)thisTrigger;
@optional;
- (NSCell *)descriptionCellForTrigger:(QSTrigger *)trigger;
- (void)triggerDoubleClicked:(QSTrigger *)trigger;
- (void)trigger:(QSTrigger *)trigger setTriggerDescription:(NSString *)description;
@end

/**
 *  QSEventTriggerProvider Protocol
 *
 *  Optional methods to define behavior when Event Triggers are enabled and disabled.
 */
@protocol QSEventTriggerProvider
@optional;
/**
 *  If multiple events from this provider share common prerequisites, set them up here. This will be called before the first trigger using an event from this provider is enabled.
 */
- (void)enableEventProvider;
/**
 *  If multiple events from this provider share common prerequisites, tear them down here. This is called after the last trigger using an event from this provider is disabled.
 */
- (void)disableEventProvider;
/**
 *  Set up prerequisites for a specific event. This will be called *once* before the first trigger using the event is enabled.
 *
 *  @param event The identifier for an event, as defined under QSTriggerEvents in a plug-in's property list.
 */
- (void)enableEventObserving:(NSString *)event;
/**
 *  Tear down prerequisites for a specific event. This will be called *once* after the last trigger using the event is disabled.
 *
 *  @param event The identifier for an event, as defined under QSTriggerEvents in a plug-in's property list.
 */
- (void)disableEventObserving:(NSString *)event;
/**
 *  Set up observation for an event. This will be called for every trigger that uses the event when the trigger is enabled.
 *
 *  @param event   The identifier for an event, as defined under QSTriggerEvents in a plug-in's property list.
 *  @param trigger The trigger being enabled.
 */
- (void)addObserverForEvent:(NSString *)event trigger:(QSTrigger *)trigger;
/**
 *  Tear down observation for an event. This will be called for every trigger that uses the event when the trigger is disabled.
 *
 *  @param event   The identifier for an event, as defined under QSTriggerEvents in a plug-in's property list.
 *  @param trigger The trigger being disabled.
 */
- (void)removeObserverForEvent:(NSString *)event trigger:(QSTrigger *)trigger;
@end

//@interface NSObject (QSTriggerManager)
//- (NSView *)settingsView;
//- (void)setSettingsSelection:(QSTrigger *)aSettingsSelection;
//
//- (void)trigger:(QSTrigger *)trigger setTriggerDescription:(NSString *)string;
//@end


@interface QSTriggerManager : NSObject <QSTriggerManager> {
	IBOutlet NSView *settingsView;
	QSTrigger *currentTrigger;
}
- (void)populateInfoFields;
- (QSTrigger *)currentTrigger;
- (void)setCurrentTrigger:(QSTrigger *)value;

- (QSTrigger *)settingsSelection;
- (NSWindow *)triggerDisplayWindowWithTrigger:(QSTrigger *)trigger;
@end

@interface QSGroupTriggerManager : QSTriggerManager
@end
