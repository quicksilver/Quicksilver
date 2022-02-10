//
//  QSPreferencePane.h
//  Quicksilver
//
//  Created by Alcor on 11/2/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QSPreferencePane.h"
#import "QSUpdateController.h"

@interface QSSearchPrefPane : QSPreferencePane {
    IBOutlet NSPopUpButton *keyboardPopUp;
}
- (BOOL)showChildrenInSplitView;
- (void)setShowChildrenInSplitView:(BOOL)flag;
- (void)updateKeyboardPopUp;
@end

@interface QSAppearancePrefPane : QSPreferencePane {
	IBOutlet NSPopUpButton *interfacePopUp;
	IBOutlet NSButton *customizeButton;
}
- (IBAction)setCommandInterface:(id)sender;
- (IBAction)resetColors:(id)sender;
- (IBAction)customize:(id)sender;
- (IBAction)preview:(id)sender;
- (void)updateInterfacePopUp;
- (BOOL)setValue:(NSString *)newMediator forMediator:(NSString *)mediatorType;
@end


@interface QSApplicationPrefPane : QSPreferencePane {
	
}
- (QSUpdateController *)updateController;
- (IBAction)checkNow:(id)sender;
- (IBAction)resetQS:(id)sender;
- (IBAction)uninstallQS:(id)sender;
- (IBAction)runSetup:(id)sender;
@end

@interface QSActionsPrefPane : QSPreferencePane {
	NSMutableArray *actions;
	NSMutableArray *groups;
	NSInteger displayMode;
	IBOutlet NSArrayController *groupController;
	IBOutlet NSArrayController *actionController;
}
- (NSMutableArray *)actions;
- (void)setActions:(NSMutableArray *)newActions;
- (NSMutableArray *)groups;
- (void)setGroups:(NSMutableArray *)newGroups;
- (NSInteger) displayMode;
- (void)setDisplayMode:(NSInteger)newDisplayMode;
- (IBAction)setFilterText:(id)sender;
- (void)updateGroups;
- (void)selectCategories:(NSArray *)categories;
@end

