//
//  QSAdvancedPrefPane.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 4/28/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "QSPreferencePane.h"

@interface QSAdvancedPrefPane : QSPreferencePane {
	IBOutlet NSTableView *prefSetsTable;
	IBOutlet NSArrayController *prefSetsController;
	IBOutlet NSBox *settingsBox;

	IBOutlet NSTextField * pretextField;
	IBOutlet NSSlider * valueSlider;
	IBOutlet NSPopUpButton * valuePopUp;
	IBOutlet NSButton * valueSwitch;
	IBOutlet NSTextField * valueField;
	IBOutlet NSTextField * posttextField;

	NSMutableDictionary *currentInfo;
}
- (IBAction)setValue:(id)sender;
- (NSMutableDictionary *)currentInfo;
- (void)setCurrentInfo:(NSMutableDictionary *)newCurrentInfo;
//- (void)refreshView;
@end
