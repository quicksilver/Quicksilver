//
//  QSAgreementController.h
//  Quicksilver
//
//  Created by Alcor on 10/13/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface QSAgreementController : NSWindowController {
	IBOutlet id agreement;
}
-(IBAction)accept:(id)sender;
-(IBAction)quit:(id)sender;
+ (void)showAgreement:(id)sender;
@end
