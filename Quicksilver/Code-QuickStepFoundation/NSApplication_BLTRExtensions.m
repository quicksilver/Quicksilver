//
// NSApplication_Extensions.m
// Quicksilver
//
// Created by Alcor on Thu May 01 2003.
// Copyright (c) 2003 Blacktree, Inc. All rights reserved.
//

#import "NSApplication_BLTRExtensions.h"
#import "NSFileManager_BLTRExtensions.h"
#import "NSString_BLTRExtensions.h"
#import "SUPlainInstallerInternals.h"

#import <unistd.h>

@implementation NSApplication (Info)
- (BOOL)wasLaunchedAtLogin {
	NSRunningApplication *parentApplication = [[NSRunningApplication currentApplication] parentApplication];
	return ([parentApplication.bundleIdentifier isEqualToString:@"com.apple.loginwindow"]
			|| [parentApplication.executableURL.path isEqualToString:@"/sbin/launchd"]);
}

- (NSString *)buildVersion {
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

- (NSString *)versionString {
	NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
	return [NSString stringWithFormat:@"%@ (%@) ", [info objectForKey:@"CFBundleShortVersionString"], [info objectForKey:@"CFBundleVersion"]];
}

@end

@implementation NSApplication (Focus)

- (BOOL)stealKeyFocus {
	CPSProcessSerNum psn;
	if ((CPSGetCurrentProcess(&psn) == noErr) && (CPSStealKeyFocus(&psn) == noErr))
		return YES;
	return NO;
}

- (BOOL)releaseKeyFocus {
	CPSProcessSerNum psn;
	if ((CPSGetCurrentProcess(&psn) == noErr) && (CPSReleaseKeyFocus(&psn) == noErr))
		return YES;
	return NO;
}

@end

@implementation NSApplication (Relaunching)

- (void)requestRelaunch:(id)sender {
    if (NSRunAlertPanel(@"Relaunch required", @"Quicksilver needs to be relaunched for some changes to take effect", @"Relaunch", @"Later", nil))
		[self relaunch:self];
}

// Use a method taken from Sparkle that deals with: Authentication, Quarantine and more
- (BOOL)moveToPath:(NSString *)launchPath fromPath:(NSString *)newPath {
    return [SUPlainInstaller copyPathWithAuthentication:newPath overPath:launchPath temporaryName:nil error:nil];
}

- (void)relaunchAtPath:(NSString *)launchPath movedFromPath:(NSString *)newPath {
	if([self moveToPath:launchPath fromPath:newPath]) {
        [self relaunchFromPath:launchPath];
    }
}

- (void)relaunchFromPath:(NSString *)path {
	if (path)
		path = [[NSBundle bundleWithPath:path] executablePath];
	else
		path = [[NSBundle mainBundle] executablePath];
	NSLog(@"Relaunch from path %@", path);
	char pidstr[10];
	sprintf(pidstr, "%d", getpid() );
	setenv("relaunchFromPid", pidstr, YES);
	[[NSNotificationCenter defaultCenter] postNotificationName:QSApplicationWillRelaunchNotification object:self userInfo:nil];
    NSString *arch = @"/usr/bin/arch";
    NSRunningApplication *Quicksilver = [NSRunningApplication currentApplication];
    NSString *currentArchitecture = ([Quicksilver executableArchitecture] == NSBundleExecutableArchitectureX86_64) ? @"-x86_64" : @"-i386";
	[NSTask launchedTaskWithLaunchPath:arch arguments:[NSArray arrayWithObjects:currentArchitecture, path,nil]];

	[self terminate:self];
}

- (IBAction)relaunch:(id)sender { [self relaunchFromPath:nil]; }

@end

@implementation NSApplication (LaunchStatus)
- (QSApplicationLaunchStatusFlags)checkLaunchStatus {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *lastLocation = [defaults objectForKey:kLastUsedLocation];
	NSString *lastVersionString = [defaults objectForKey:kLastUsedVersion];
	NSString *thisVersionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];

	if (! (lastLocation || lastVersionString) )
		return QSApplicationFirstLaunch;

	NSInteger lastVersion = [lastVersionString respondsToSelector:@selector(hexIntValue)] ? [lastVersionString hexIntValue] : 0;
	NSInteger thisVersion = [thisVersionString hexIntValue];

	if (thisVersion>lastVersion) return QSApplicationUpgradedLaunch;
	if (thisVersion<lastVersion) return QSApplicationDowngradedLaunch;
	return QSApplicationNormalLaunch;
}

- (void)updateLaunchStatusInfo {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSBundle *appBundle = [NSBundle mainBundle];
	NSString *bundlePath = [appBundle bundlePath];
	NSString *thisVersionString = [[appBundle infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
	[defaults setObject:thisVersionString forKey:kLastUsedVersion];
	[defaults setObject:[bundlePath stringByAbbreviatingWithTildeInPath] forKey:kLastUsedLocation];
	[defaults synchronize];
}

@end

@implementation NSApplication (VersionCheck)
+ (NSString *)macOSXFullVersion {
	return [NSString stringWithFormat:@"%ld.%ld.%ld",(long)[self macOSXMajorVersion],(long)[self macOSXMinorVersion],(long)[self macOSXBugfixVersion]];
}
+ (NSInteger)macOSXMajorVersion {
	NSOperatingSystemVersion osv = [[NSProcessInfo processInfo] operatingSystemVersion];
    return osv.majorVersion;
}

+ (NSInteger)macOSXMinorVersion {
	NSOperatingSystemVersion osv = [[NSProcessInfo processInfo] operatingSystemVersion];
	return osv.minorVersion;
}

+ (NSInteger)macOSXBugfixVersion {
	NSOperatingSystemVersion osv = [[NSProcessInfo processInfo] operatingSystemVersion];
	return osv.patchVersion;
}

+ (NSOperatingSystemVersion)macOSXSystemVersion {
	return [[NSProcessInfo processInfo] operatingSystemVersion];
}

+ (NSString *)macOSXReleaseVersion {
    return [NSString stringWithFormat:@"%ld.%ld", (long)[self macOSXMajorVersion], (long)[self macOSXMinorVersion]];
}


+ (BOOL)isLeopard {
	return ([NSApplication macOSXMajorVersion] >= 10 && [NSApplication macOSXMinorVersion] >= 5);
}

+ (BOOL)isSnowLeopard {
    return ([NSApplication macOSXMajorVersion] >= 10 && [NSApplication macOSXMinorVersion] >= 6);
}

+ (BOOL)isLion {
    return ([NSApplication macOSXMajorVersion] >= 10 && [NSApplication macOSXMinorVersion] >= 7);
}

+ (BOOL)isMountainLion {
    return ([NSApplication macOSXMajorVersion] >= 10 && [NSApplication macOSXMinorVersion] >= 8);
}

+ (BOOL)isMavericks {
    return ([NSApplication macOSXMajorVersion] >= 10 && [NSApplication macOSXMinorVersion] >= 9);
}

+ (BOOL)isYosemite {
    return ([NSApplication macOSXMajorVersion] >= 10 && [NSApplication macOSXMinorVersion] >= 10);
}

+ (BOOL)isElCapitan {
    return ([NSApplication macOSXMajorVersion] >= 10 && [NSApplication macOSXMinorVersion] >= 11);
}

+ (BOOL)isSierra {
	return ([NSApplication macOSXMajorVersion] >= 10 && [NSApplication macOSXMinorVersion] >= 12);
}

+ (BOOL)isHighSierra {
	return ([NSApplication macOSXMajorVersion] >= 10 && [NSApplication macOSXMinorVersion] >= 13);
}

+ (BOOL)isMojave {
	return ([NSApplication macOSXMajorVersion] >= 10 && [NSApplication macOSXMinorVersion] >= 14);
}
@end
