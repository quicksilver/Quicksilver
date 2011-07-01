//
//  QSPreferencePane.h
//  Quicksilver
//
//  Created by Alcor on 11/2/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QSPreferencePane.h"

@interface QSSearchPrefPane : QSPreferencePane {}
- (BOOL)showChildrenInSplitView;
- (void)setShowChildrenInSplitView:(BOOL)flag;
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
	IBOutlet NSMatrix *featureLevelMatrix;
	int newFeatureLevel;
}
- (IBAction)checkNow:(id)sender;
- (IBAction)resetQS:(id)sender;
- (IBAction)uninstallQS:(id)sender;
- (IBAction)runSetup:(id)sender;
@end
