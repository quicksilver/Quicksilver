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
   NSDictionary * parentProcessInfoDict = [NSApp parentProcessInformation];
/* removed to stop the console from cluttering up. If yo want to know this just remove the comment tags :)
26/01/2010 - pjrobertson
   if (parentProcessInfoDict) {
      NSLog(@"[Quicksilver %s]: parentProcessInfoDict = '%@'", __PRETTY_FUNCTION__, [parentProcessInfoDict descriptionInStringsFileFormat]);
   }
*/
    // !!! Andre Berg 20091017: some people like to start QS by means of launchd plist which can also keep it alive when it crashes 
	return ([(NSString *)([parentProcessInfoDict objectForKey:(id)kCFBundleIdentifierKey]) isEqualToString:@"com.apple.loginwindow"] 
            || [(NSString *)([parentProcessInfoDict objectForKey:(id)kCFBundleExecutableKey]) isEqualToString:@"/sbin/launchd"]);
}

- (NSString *)buildVersion {
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

- (NSString *)versionString {
	NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
	return [NSString stringWithFormat:@"%@ (%@) ", [info objectForKey:@"CFBundleShortVersionString"], [info objectForKey:@"CFBundleVersion"]];
}

- (NSDictionary *)processInformation {
	ProcessSerialNumber currPSN;
	OSStatus err = GetCurrentProcess (&currPSN);
	if (err)
		return nil;
	else
		return (NSDictionary*)CFBridgingRelease(ProcessInformationCopyDictionary (&currPSN, kProcessDictionaryIncludeAllInformationMask));
}
- (NSDictionary *)parentProcessInformation {
	// Get the PSN of the app that *launched* us. Its not really the parent app, in the unix sense.
	long long temp = [[[self processInformation] objectForKey:@"ParentPSN"] longLongValue];
	ProcessSerialNumber parentPSN = {(temp >> 32) & 0x00000000FFFFFFFFLL, (temp >> 0) & 0x00000000FFFFFFFFLL};

	// Get info on the launching process
	return (NSDictionary*)CFBridgingRelease(ProcessInformationCopyDictionary(&parentPSN, kProcessDictionaryIncludeAllInformationMask));
}
@end

@implementation NSApplication (Focus)

- (BOOL)stealKeyFocus {
	return NO;
}

- (BOOL)releaseKeyFocus {
	return NO;
}

@end

@implementation NSApplication (Relaunching)

- (void)requestRelaunch:(id)sender {
	QSAlertResponse response = [NSAlert runAlertWithTitle:NSLocalizedString(@"Relaunch required", "Request relaunch alert title")
											   message:NSLocalizedString(@"Quicksilver needs to be relaunched for some changes to take effect", @"Request relaunch alert message")
											   buttons:@[
														 NSLocalizedString(@"Relaunch", @"Request relaunch alert accept button"),
														 NSLocalizedString(@"Later", @"Request relaunch alert cancel button"),
														 ]
													style:NSAlertStyleWarning];
	if (response == QSAlertResponseOK) {
		[self relaunch:self];
	}
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

	NSString *currentArchitecture = ([Quicksilver executableArchitecture] == NSBundleExecutableArchitectureARM64) ? @"-arm64" : @"-x86_64";
	[NSTask launchedTaskWithLaunchPath:arch arguments:[NSArray arrayWithObjects:currentArchitecture, path, nil]];

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
	return [NSApplication macOSXMajorVersion] > 10 || ([NSApplication macOSXMajorVersion] == 10 && [NSApplication macOSXMinorVersion] >= 5);
}

+ (BOOL)isSnowLeopard {
    return [NSApplication macOSXMajorVersion] > 10 || ([NSApplication macOSXMajorVersion] == 10 && [NSApplication macOSXMinorVersion] >= 6);
}

+ (BOOL)isLion {
    return [NSApplication macOSXMajorVersion] > 10 || ([NSApplication macOSXMajorVersion] == 10 && [NSApplication macOSXMinorVersion] >= 7);
}

+ (BOOL)isMountainLion {
    return [NSApplication macOSXMajorVersion] > 10 || ([NSApplication macOSXMajorVersion] == 10 && [NSApplication macOSXMinorVersion] >= 8);
}

+ (BOOL) isMavericks {
    return [NSApplication macOSXMajorVersion] > 10 || ([NSApplication macOSXMajorVersion] == 10 && [NSApplication macOSXMinorVersion] >= 9);
}

+ (BOOL)isYosemite {
    return [NSApplication macOSXMajorVersion] > 10 || ([NSApplication macOSXMajorVersion] == 10 && [NSApplication macOSXMinorVersion] >= 10);
}

+ (BOOL)isElCapitan {
    return [NSApplication macOSXMajorVersion] > 10 || ([NSApplication macOSXMajorVersion] == 10 && [NSApplication macOSXMinorVersion] >= 11);
}

+ (BOOL)isSierra {
	return [NSApplication macOSXMajorVersion] > 10 || ([NSApplication macOSXMajorVersion] == 10 && [NSApplication macOSXMinorVersion] >= 12);
}

+ (BOOL)isHighSierra {
	return [NSApplication macOSXMajorVersion] > 10 || ([NSApplication macOSXMajorVersion] == 10 && [NSApplication macOSXMinorVersion] >= 13);
}

+ (BOOL)isMojave {
	return [NSApplication macOSXMajorVersion] > 10 || ([NSApplication macOSXMajorVersion] == 10 && [NSApplication macOSXMinorVersion] >= 14);
}

+ (BOOL)isCatalina {
	return [NSApplication macOSXMajorVersion] > 10 || ([NSApplication macOSXMajorVersion] == 10 && [NSApplication macOSXMinorVersion] >= 15);
}

+ (BOOL)isBigSur {
	return [NSApplication macOSXMajorVersion] >= 11;
}

+ (BOOL)isSonoma {
	return [NSApplication macOSXMajorVersion] >= 14;
}

+ (BOOL)isSequoia {
	return [NSApplication macOSXMajorVersion] >= 14;
}
@end
