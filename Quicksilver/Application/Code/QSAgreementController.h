//
//  QSAgreementController.h
//  Quicksilver
//
//  Created by Alcor on 10/13/04.

//

#import <Cocoa/Cocoa.h>


@interface QSAgreementController : NSWindowController {
	IBOutlet id agreement;
}
-(IBAction)accept:(id)sender;
-(IBAction)quit:(id)sender;
+ (void)showAgreement:(id)sender;
@end
