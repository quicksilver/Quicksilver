//
//  QSNotificationCenterHandler.h
//  Quicksilver
//
//  Created by Rob McBroom on 2015/08/17.
//
//

#define QSReleaseNotesUserNotification @"QSReleaseNotesUserNotification"
#define QSLocationChangedUserNotification @"QSLocationChangedUserNotification"
#define QSRelaunchRequestedUserNotification @"QSRelaunchRequestedUserNotification"

@interface QSNotificationCenterHandler : NSObject <NSUserNotificationCenterDelegate>

@end
