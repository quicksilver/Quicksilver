//
//  QSDonationManager.m
//  Quicksilver
//
//  Created by Alcor on 9/1/04.

//

#import "QSDonationManager.h"


@implementation QSDonationManager

+ (id)sharedInstance {
	static NSWindowController *_sharedInstance = nil;
    if (!_sharedInstance)
        _sharedInstance = [[[self class] allocWithZone:[self zone]] init];
    return _sharedInstance;
}

+ (void)showSharedWindow:(id)sender {
	[[QSDonationManager sharedInstance] showWindow:sender]; 	
}
	
- (int) donationAmount {
	int amount = [[donationAmountMatrix selectedCell] tag]; 	
	if (amount == -1) amount = [donationCustomField intValue];
	return amount; 	
}

- (IBAction)donateOther:(id)sender {
	NSString *urlString = [NSString stringWithFormat:@"http://www.blacktree.com/donate.php?method = Mail&for = Quicksilver&amount = %d", [self donationAmount]];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}

- (IBAction)donatePayPal:(id)sender {
	
	NSString *urlString = [NSString stringWithFormat:@"http://www.blacktree.com/donate.php?method = PayPal&for = Quicksilver&amount = %d", [self donationAmount]];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}
- (id)init {
    self = [super initWithWindowNibName:@"Donate"];
    if (self) {

    }
    return self;
}
- (IBAction)setValueForSender:(id)sender {
}

@end
