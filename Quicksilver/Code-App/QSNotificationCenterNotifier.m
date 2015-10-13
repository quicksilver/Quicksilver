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
    [message setHasActionButton:NO];
	
	[[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:message];
}

#pragma mark NSUserNotificationCenter delegate methods

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    // there's no in-app equivalent for these notifications, so always show them
    return YES;
}

@end
