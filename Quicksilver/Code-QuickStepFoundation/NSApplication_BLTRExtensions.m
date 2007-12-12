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
#import "CPS.h"

@implementation NSApplication (Info)
- (BOOL)wasLaunchedAtLogin {
	return [[[NSApp parentProcessInformation] objectForKey:@"CFBundleIdentifier"] isEqualToString:@"com.apple.loginwindow"];
}

- (NSString *)buildVersion {
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

- (NSString *)versionString {
	NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
	return [NSString stringWithFormat:@"%@ %@(%@) ", [info objectForKey:@"CFBundleShortVersionString"] , PRERELEASEVERSION?@"PRERELEASE ":@"", [info objectForKey:@"CFBundleVersion"]];
}

- (int)featureLevel {return 0;}

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
	//if (defaultBool(@"QSRelaunchWithoutAsking") )
	//	[self relaunch:self];
	//else
		if (NSRunAlertPanel(@"Relaunch required", @"Quicksilver needs to be relaunched for some changes to take effect", @"Relaunch", @"Later", nil) )
		[self relaunch:self];
}


- (void)relaunchAfterMovingFromPath:(NSString *)newPath {
	[self relaunchAtPath:[[NSBundle mainBundle] bundlePath] movedFromPath:newPath];
}

- (int) moveToPath:(NSString *)launchPath fromPath:(NSString *)newPath {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *tempPath = [[launchPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Quicksilver.old.app"];
	//NSLog(@"temp %@ new %@", tempPath, newPath);
	BOOL status;
	status = [manager movePath:launchPath toPath:tempPath handler:nil];
	if (VERBOSE) NSLog(@"Move Old %d", status);
	status = [manager movePath:newPath toPath:launchPath handler:nil];
	if (VERBOSE) NSLog(@"Copy New %d", status);
	status = [manager movePathToTrash:tempPath];
	if (VERBOSE) NSLog(@"Trash Old %d", status);
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
	[NSTask launchedTaskWithLaunchPath:path arguments:[NSArray array]];

	[self terminate:self];
}

- (IBAction)relaunch:(id)sender { [self relaunchFromPath:nil]; }

@end

@implementation NSApplication (LSUIElementManipulation)

- (BOOL)shouldBeUIElement {
	return [[[NSDictionary dictionaryWithContentsOfFile:
		[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Info.plist"]]
		objectForKey:@"LSUIElement"] boolValue];
}

- (BOOL)setShouldBeUIElement:(BOOL)hidden {
	NSString * plistPath = nil;
	NSFileManager *manager = [NSFileManager defaultManager];
	if (plistPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Info.plist"]) {
		if ([manager isWritableFileAtPath:plistPath]) {
			NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
			[infoDict setObject:[NSNumber numberWithBool:hidden] forKey:@"LSUIElement"];
			[infoDict writeToFile:plistPath atomically:NO];
			[manager changeFileAttributes:[NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate] atPath: [[NSBundle mainBundle] bundlePath]];
			return YES;
		}
	}
	return NO;
}

@end

@implementation NSApplication (LaunchStatus)
- (int)checkLaunchStatus {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *lastLocation = [defaults objectForKey:kLastUsedLocation];

	NSString *lastVersionString = [defaults objectForKey:kLastUsedVersion];
	NSString *thisVersionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];

	if (! (lastLocation || lastVersionString) )
		return QSApplicationFirstLaunch;

	int lastVersion = [lastVersionString respondsToSelector:@selector(hexIntValue)] ? [lastVersionString hexIntValue] : 0;
	int thisVersion = [thisVersionString hexIntValue];

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
