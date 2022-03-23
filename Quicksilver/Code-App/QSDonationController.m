//
//  QSDonationController.m
//  Quicksilver
//
//  Created by Patrick Robertson on 05/03/2022.
//

#import "QSDonationController.h"
#import "QSPaths.h"

#define kQSDonateReminderSuppressForever @"donate.reminder.suppress.forever"
#define kQSDonateReminderSuppressUntilNextVersion @"donate.reminder.suppress.next"
#define kQSDonateReminderLast @"donate.reminder.last"
#define kQSDonateReminderInterval (60 * 60 * 24 * 7 ) // 1 week


static QSDonationController *_controller;

@implementation QSDonationController

+ (QSDonationController * )sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _controller = [[[self class] allocWithZone:nil] init];
    });
    return _controller;
}

- (BOOL)openDonationPage {
	return [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kDonatePageURL]];
}

- (void)showDonationAlert:(BOOL)allowHideUntilNextVersion {
	NSAlert *alert = [[NSAlert alloc] init];
	alert.accessoryView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 400, 0)];
	[alert setMessageText:NSLocalizedString(@"Thank you for using Quicksilver!", @"Donate")];
	NSString *message = NSLocalizedString(@"Quicksilver is free-to-use, but it costs money to write and support. If you find Quicksilver useful, please consider donating. It will help to make Quicksilver even better!", @"Donate");
	[alert setInformativeText:message];
	[alert addButtonWithTitle:NSLocalizedString(@"Donate", @"Donate")];
	[alert addButtonWithTitle:NSLocalizedString(@"Later", @"Donate")];
	[alert setAlertStyle:NSAlertStyleInformational];
	// don't show the suppress option on the first time.
	[alert setShowsSuppressionButton:allowHideUntilNextVersion];
	[[alert suppressionButton] setTitle:NSLocalizedString(@"Don't show again for this version", @"Donate")];
	NSInteger result = [alert runModal];
	if (result == NSAlertFirstButtonReturn) {
		[self openDonationPage];
	}
	if (alert.showsSuppressionButton) {
		[[NSUserDefaults standardUserDefaults] setBool:(alert.suppressionButton.state == NSControlStateValueOn) forKey:kQSDonateReminderSuppressUntilNextVersion];
	}
}

// Returns Boolean YES if the donation alert was displayed otherwise NO
- (BOOL)checkDonationStatus:(QSApplicationLaunchStatusFlags)launchStatus {
	if (launchStatus == QSApplicationFirstLaunch || launchStatus == QSApplicationDowngradedLaunch) {
		// don't show the donation alert if it's the first launch or a downgrade
		return NO;
	}
	NSUserDefaults *u = [NSUserDefaults standardUserDefaults];
	if ([u boolForKey:kQSDonateReminderSuppressForever]) {
		// suppress the notification if it's set in the prefs – for devs, or evil doers ;-)
		return NO;
	}

	// show alert if upgraded, or if time since last alert is greater than interval
	BOOL showAlert = (launchStatus == QSApplicationUpgradedLaunch);
	NSDate *lastReminderDate = [u objectForKey:kQSDonateReminderLast];
	if (!showAlert) {
		if ([u boolForKey:kQSDonateReminderSuppressUntilNextVersion]) {
			// don't show if the user chose the "Don't show again for this version" option
			showAlert = NO;
		} else {
			showAlert = (!lastReminderDate || (lastReminderDate.timeIntervalSinceNow*-1 > kQSDonateReminderInterval));
		}
	}
	if (showAlert) {
		// only show the "Don't show again for this version" option if it's not the first time they've seen this message.
		BOOL allowHideUntilNextVersion = (lastReminderDate != nil);
		[self showDonationAlert:allowHideUntilNextVersion];
		[u setObject:[NSDate date] forKey:kQSDonateReminderLast];
		return YES;
	}
	
	return NO;
}

@end
