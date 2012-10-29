//
//  NSApplication_Extensions.h
//  Daedalus
//
//  Created by Alcor on Thu May 01 2003.
//  Copyright (c) 2003 Blacktree, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define QSApplicationWillRelaunchNotification @"QSApplicationWillRelaunchNotification"
@interface NSApplication (Info)
- (BOOL)wasLaunchedAtLogin;
- (NSString *)versionString;
- (NSDictionary *)processInformation;
- (NSDictionary *)parentProcessInformation;
@end

@interface NSApplication (Focus)
- (BOOL)stealKeyFocus;
- (BOOL)releaseKeyFocus;
@end


@interface NSApplication (Relaunching)
- (IBAction)relaunch:(id)sender;
- (BOOL)moveToPath:(NSString *)launchPath fromPath:(NSString *)newPath;
- (void)requestRelaunch:(id)sender;
- (void)relaunchFromPath:(NSString *)path;
- (void)relaunchAtPath:(NSString *)launchPath movedFromPath:(NSString *)newPath;
@end

enum {
	QSApplicationNormalLaunch = 0,
	QSApplicationUpgradedLaunch = 1,
	QSApplicationDowngradedLaunch = -1,
	QSApplicationFirstLaunch = 2
};

typedef NSInteger QSApplicationLaunchStatusFlags;

#define kLastUsedVersion @"Last Used Version"
#define kLastUsedLocation @"Last Used Location"

@interface NSApplication (LaunchStatus)
- (QSApplicationLaunchStatusFlags)checkLaunchStatus;
- (void)updateLaunchStatusInfo;
@end


/**
 Category for checking system version
 
 This category of NSApplication provides class methods to check which Mac OS X 
 version Quicksilver is running on.
 Uses Gestalt API. See http://www.cocoadev.com/index.pl?DeterminingOSVersion for 
 reasons this is the best choice for determining the system version.
 For future methods similar to these ones, keep the limitations of gestaltSystemVersion 
 in mind. Maybe use gestaltSystemVersionMajor/gestaltSystemVersionMinor instead.
 */
@interface NSApplication (VersionCheck)
/**
 Returns the version as provided by Gestalt(gestaltSystemVersion,...)
 @returns SInt32 Mac OS X version number as a hex number (eg: 0x1013 = 10.1.3)
*/
+ (SInt32)macOSXSystemVersion;
/**
 Returns the major release of Mac OS X, for example 10.7
 */
+ (NSString *)macOSXReleaseVersion;
/**
  Returns the full Mac OS X version of the current system as a string
 
 @returns an NSString of the user's current Mac OS X version, for example 10.6.7
 */
+ (NSString *)macOSXFullVersion;

/**
 DEPRECATED METHOD
 This should be removed (along with all corresponding isLeopard code) when we've got over the Lion upgrade hurdle
 Checks, if system is at least Mac OS X 10.5 (Leopard)
  
 @returns YES, if 10.5+. NO otherwise
 */
+ (BOOL)isLeopard;

/**
 Checks, if system is at least Mac OS X 10.6 (SnowLeopard)
 
 @returns YES, if 10.6+. NO otherwise
 */
+ (BOOL)isSnowLeopard;

/**
 Checks, if system is at least Mac OS X 10.7 (Lion)
 
 @returns YES, if 10.7+. NO otherwise
 */
+ (BOOL)isLion;

/**
 Checks, if system is at least Mac OS X 10.8 (Mountain Lion)
 
 @returns YES, if 10.8+. NO otherwise
 */
+ (BOOL)isMountainLion;
@end
