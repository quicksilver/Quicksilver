//
//  QSTriggerManager.h
//  Quicksilver
//
//  Created by Alcor on 11/9/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "QSTrigger.h"

@interface QSTriggerManager : NSObject {
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
