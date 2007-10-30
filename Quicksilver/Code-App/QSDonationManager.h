/* QSDonationManager */

#import <Cocoa/Cocoa.h>

@interface QSDonationManager : NSWindowController
{
    IBOutlet id donationAmountMatrix;
    IBOutlet id donationCustomField;
    IBOutlet id donationCustomStepper;
    IBOutlet id donationTypePopUp;
}
- (IBAction)donateOther:(id)sender;
- (IBAction)donatePayPal:(id)sender;
- (IBAction)setValueForSender:(id)sender;
@end
