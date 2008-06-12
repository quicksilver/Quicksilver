//
//  NSApplication_Extensions.h
//  Daedalus
//
//  Created by Alcor on Thu May 01 2003.

//

#import <Cocoa/Cocoa.h>

#define QSApplicationWillRelaunchNotification @"QSApplicationWillRelaunchNotification"

@interface NSApplication (Info)
- (BOOL)wasLaunchedAtLogin;
- (NSString *)versionString;
- (int)featureLevel;
- (NSDictionary *)processInformation;
- (NSDictionary *)parentProcessInformation;
@end

@interface NSApplication (Focus)
- (BOOL)stealKeyFocus;
- (BOOL)releaseKeyFocus;
@end


@interface NSApplication (Relaunching)
- (IBAction)relaunch:(id)sender;
- (void)requestRelaunch:(id)sender;
- (void)relaunchFromPath:(NSString *)path;
- (void)relaunchAfterMovingFromPath:(NSString *)newPath;
- (void)relaunchAtPath:(NSString *)launchPath movedFromPath:(NSString *)newPath;
- (void)replaceWithUpdateFromPath:(NSString *)newPath;
@end

@interface NSApplication (LSUIElementManipulation)
- (BOOL)shouldBeUIElement;
- (BOOL)setShouldBeUIElement:(BOOL)hidden;
@end

typedef enum {
	QSApplicationNormalLaunch = 0,
	QSApplicationUpgradedLaunch = 1,
	QSApplicationDowngradedLaunch = -1,
	QSApplicationFirstLaunch = 2
} QSApplicationLaunchStatusFlags;

#define kLastUsedVersion @"Last Used Version"
#define kLastUsedLocation @"Last Used Location"

@interface NSApplication (LaunchStatus)
- (QSApplicationLaunchStatusFlags)checkLaunchStatus;
- (void)updateLaunchStatusInfo;
@end



