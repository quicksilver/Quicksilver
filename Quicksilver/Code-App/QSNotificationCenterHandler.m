//
//  QSNotificationCenterHandler.m
//  Quicksilver
//
//  Created by Rob McBroom on 2015/08/17.
//
//

#import "QSNotificationCenterHandler.h"
#import "QSController.h"

@implementation QSNotificationCenterHandler

#pragma mark NSUserNotificationCenter delegate methods

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    if ([[notification identifier] isEqualToString:QSReleaseNotesUserNotification]) {
        [[QSController sharedInstance] showReleaseNotes:self];
        return;
    }
    if ([[notification identifier] isEqualToString:QSLocationChangedUserNotification]) {
        NSString *lastLocation = notification.userInfo[@"destination"];
        NSString *bundlePath = notification.userInfo[@"source"];
        [NSApp relaunchAtPath:lastLocation movedFromPath:bundlePath];
        return;
    }
    if ([[notification identifier] isEqualToString:QSRelaunchRequestedUserNotification]) {
        [NSApp relaunch:nil];
    }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    // there's no in-app equivalent for these notifications, so always show them
    return YES;
}

@end
