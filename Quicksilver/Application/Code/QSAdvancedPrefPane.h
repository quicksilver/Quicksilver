//
//  QSAdvancedPrefPane.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 4/28/06.

//

@interface QSAdvancedPrefPane : QSPreferencePane {
	IBOutlet NSTableView *prefSetsTable;
	IBOutlet NSArrayController *prefSetsController;
	IBOutlet NSBox *settingsBox;
	
	
	IBOutlet NSTextField * titleField;
	IBOutlet NSTextField * pretextField;
	IBOutlet NSSlider * valueSlider;
	IBOutlet NSPopUpButton * valuePopUp;
	IBOutlet NSButton * valueSwitch;
	IBOutlet NSTextField * valueField;
	IBOutlet NSTextField * posttextField;
	IBOutlet NSTextField * descriptionField;
	
	NSMutableDictionary *currentInfo;
}
- (IBAction)setValue:(id)sender;
- (NSMutableDictionary *)currentInfo;
- (void)setCurrentInfo:(NSMutableDictionary *)newCurrentInfo;
- (void)refreshView;
@end
