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
		return [(NSDictionary*)ProcessInformationCopyDictionary (&currPSN, kProcessDictionaryIncludeAllInformationMask) autorelease];
}
- (NSDictionary *)parentProcessInformation {
	// Get the PSN of the app that *launched* us. Its not really the parent app, in the unix sense.
	long long temp = [[[self processInformation] objectForKey:@"ParentPSN"] longLongValue];
	ProcessSerialNumber parentPSN = {(temp >> 32) & 0x00000000FFFFFFFFLL, (temp >> 0) & 0x00000000FFFFFFFFLL};

	// Get info on the launching process
	return [(NSDictionary*)ProcessInformationCopyDictionary(&parentPSN, kProcessDictionaryIncludeAllInformationMask) autorelease];
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

- (void)relaunchAfterMovingFromPath:(NSString *)newPath {
	[self relaunchAtPath:[[NSBundle mainBundle] bundlePath] movedFromPath:newPath];
}

- (NSInteger)moveToPath:(NSString *)launchPath fromPath:(NSString *)newPath {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *tempPath = [[launchPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.old.app",[[NSProcessInfo processInfo] processName]]];
	//NSLog(@"temp %@ new %@", tempPath, newPath);
	BOOL status;
	status = [manager moveItemAtPath:launchPath toPath:tempPath error:nil];
#ifdef DEBUG
	if (VERBOSE) NSLog(@"Move Old %@", status ? @"DONE" : @"FAILED");
#endif
	status = [manager copyItemAtPath:newPath toPath:launchPath error:nil];
#ifdef DEBUG
	if (VERBOSE) NSLog(@"Copy New %@", status ? @"DONE" : @"FAILED");
#endif
	status = [manager movePathToTrash:tempPath];
#ifdef DEBUG
	if (VERBOSE) NSLog(@"Trash Old %@", status? @"DONE" : @"FAILED");
#endif
	return status;
}

- (void)replaceWithUpdateFromPath:(NSString *)newPath {
	[self moveToPath:[[NSBundle mainBundle] bundlePath] fromPath:newPath];
}

- (void)relaunchAtPath:(NSString *)launchPath movedFromPath:(NSString *)newPath {
	[self moveToPath:launchPath fromPath:newPath];
	[self relaunchFromPath:launchPath];
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
	SInt32 versionMajor, versionMinor, versionBugfix;
	Gestalt (gestaltSystemVersionMajor, &versionMajor);
	Gestalt (gestaltSystemVersionMinor, &versionMinor);
	Gestalt (gestaltSystemVersionBugFix, &versionBugfix);
	
	return [NSString stringWithFormat:@"%i.%i.%i",versionMajor,versionMinor,versionBugfix];
}

+ (SInt32)macOSXSystemVersion {
	SInt32 version;
	Gestalt (gestaltSystemVersion, &version);
	return version;
}
+ (BOOL)isLeopard {
	return ([self macOSXSystemVersion] >= 0x1050);
}

+ (BOOL)isSnowLeopard {
	return ([self macOSXSystemVersion] >= 0x1060);
}

+ (BOOL)isLion {
	return ([self macOSXSystemVersion] >= 0x1070);
}

+ (BOOL)isMountainLion {
	return ([self macOSXSystemVersion] >= 0x1080);
}
@end
