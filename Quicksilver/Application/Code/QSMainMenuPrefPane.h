//
//  QSMainMenuPrefPane.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 6/11/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "QSPreferencePane.h"
#import <WebKit/WebKit.h>
@interface QSMainMenuPrefPane : QSPreferencePane {
	IBOutlet WebView *guideView;
	IBOutlet NSProgressIndicator *progressIndicator;
	IBOutlet NSTextField *progressField;
	
}
- (IBAction)goHome:(id)sender;
- (IBAction)showInBrowser:(id)sender;
- (IBAction)search:(id)sender;
@end
