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
