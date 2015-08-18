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
	NSString *title = [attributes objectForKey:QSNotifierTitle];
	NSString *subtitle = [attributes objectForKey:QSNotifierText];
	NSString *details = [[attributes objectForKey:QSNotifierDetails] string];
    NSImage *icon = [attributes objectForKey:QSNotifierIcon];
	
	NSUserNotification *message = [[NSUserNotification alloc] init];
	[message setTitle:title];
	[message setSubtitle:subtitle];
	[message setInformativeText:details];
    [message setContentImage:icon];
	
	[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:message];
}

@end
