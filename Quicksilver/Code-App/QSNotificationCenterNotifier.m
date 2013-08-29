//
//  QSNotificationCenterNotifier.m
//  Quicksilver
//
//  Created by Rob McBroom on 2012/09/20.
//
//

#import "QSNotificationCenterNotifier.h"

@implementation QSNotificationCenterNotifier

- (void)displayNotificationWithAttributes:(NSDictionary *)attributes
{
#ifdef MAC_OS_X_VERSION_10_8
	NSString *title = [attributes objectForKey:QSNotifierTitle];
	NSString *subtitle = [attributes objectForKey:QSNotifierText];
	NSString *details = [[attributes objectForKey:QSNotifierDetails] string];
	
	NSUserNotification *message = [[NSUserNotification alloc] init];
	[message setTitle:title];
	[message setSubtitle:subtitle];
	[message setInformativeText:details];
	
	[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:message];
#endif
}

@end
