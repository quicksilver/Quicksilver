//
// NSWorkspace_BLTRExtensions.m
// Quicksilver
//
// Created by Alcor on Fri May 09 2003.
// Copyright (c) 2003 Blacktree, Inc. All rights reserved.
//

#import "NSWorkspace_BLTRExtensions.h"
#import "NSApplication_BLTRExtensions.h"
#include <signal.h>
#include <unistd.h>

OSStatus _LSCopyAllApplicationURLs(CFArrayRef *array);

@implementation NSWorkspace (Misc)

- (NSString *)commentForFile:(NSString *)path {
	if (!path) return nil;

	NSArray *finders = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.Finder"];
	if ([finders count] == 0) {
		NSBeep();
		return nil;
	}
	NSString *hfsPath = [path fileSystemPathHFSStyle];
	NSAppleScript *script;
	NSAppleEventDescriptor *aeDesc;

	script = [[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:@"tell application \"Finder\" to comment of item \"%@\"", hfsPath]];
	aeDesc = [script executeAndReturnError:nil];
	return [aeDesc stringValue];
}

- (BOOL)setComment:(NSString*)comment forFile:(NSString *)path {
	NSArray *finders = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.Finder"];
	if ([finders count] == 0) {
		NSBeep();
		return NO;
	}
	NSString *scriptText;
	NSString *hfsPath = [path fileSystemPathHFSStyle];;
	NSAppleScript *script;

	scriptText = [NSString stringWithFormat:@"tell application \"Finder\" to set comment of item \"%@\" to \"%@\"", hfsPath, comment];
	script = [[NSAppleScript alloc] initWithSource:scriptText];

	return ([[script executeAndReturnError:nil] stringValue] != nil);
}

- (NSArray *)allApplicationsURLs {
    CFArrayRef appURLs = NULL;
	_LSCopyAllApplicationURLs(&appURLs);
    return (__bridge_transfer NSArray *)appURLs;
}

- (NSArray *)allApplications {
    NSArray *appURLs = self.allApplicationsURLs;
    NSMutableArray *appPaths = [NSMutableArray arrayWithCapacity:appURLs.count];
    for (NSURL *appURL in appURLs) {
        [appPaths addObject:appURL.path];
    }
    return [appPaths copy];
}

@end

@implementation NSWorkspace (QSApplicationExtensions)

- (NSRunningApplication *)runningApplicationForOldStyleWorkspaceDictionary:(NSDictionary *)dict {
	if ([dict isKindOfClass:[NSRunningApplication class]]) return (NSRunningApplication *)dict;

	NSNumber *pidNumber = dict[@"NSApplicationProcessIdentifier"];
	if (!pidNumber) return nil;

	return [NSRunningApplication runningApplicationWithProcessIdentifier:[pidNumber intValue]];
}

- (void)hideOtherApplications:(NSArray *)theApps {
	NSMutableArray *keepApps = [NSMutableArray array];
	for (id obj in theApps) {
		NSRunningApplication *app = [self runningApplicationForOldStyleWorkspaceDictionary:obj];
		if (!app) continue;
		[keepApps addObject:app];
	}

	for (NSRunningApplication *runningApp in [self runningApplications]) {
		if ([keepApps containsObject:runningApp]) {
			[runningApp activateWithOptions:0];
		} else {
			[runningApp hide];
		}
	}
}

- (void)quitOtherApplications:(NSArray *)theApps {
	NSMutableArray *keepApps = [NSMutableArray array];
	for (id obj in theApps) {
		NSRunningApplication *app = [self runningApplicationForOldStyleWorkspaceDictionary:obj];
		if (!app) continue;
		[keepApps addObject:app];
	}

	for (NSRunningApplication *runningApp in [self runningApplications]) {
		if ([keepApps containsObject:runningApp]) {
			[runningApp activateWithOptions:0];
		} else if (!runningApp.isHidden
				   || ![runningApp.bundleIdentifier isEqualToString:@"com.apple.Finder"]) {
			[runningApp terminate];
		}
	}
}

- (BOOL)openFileInBackground:(NSString *)fullPath {
	struct LSLaunchURLSpec launchSpec = {
		.appURL = NULL,
		.itemURLs = (__bridge CFArrayRef) [NSArray arrayWithObject:[NSURL fileURLWithPath:fullPath]],
		.passThruParams = NULL,
		.launchFlags = kLSLaunchAsync | kLSLaunchDontSwitch | kLSLaunchNoParams,
		.asyncRefCon = NULL,
	};
	return !LSOpenFromURLSpec(&launchSpec, NULL);
}

- (void)relaunchApplication:(NSRunningApplication *)theApp {
	// In case someone passes us one of those dicts
	NSRunningApplication *app = [self runningApplicationForOldStyleWorkspaceDictionary:(NSDictionary *)theApp];

	if (!app) {
		NSBeep();
		NSLog(@"Unable to find application %@ to restart", theApp);
		return;
	}

	if (app.processIdentifier == [[NSProcessInfo processInfo] processIdentifier]) {
		[NSApp relaunch:nil];
		return;
	}

	NSURL *bundleURL = app.bundleURL;
	BOOL success = QSGCDWait(20, ^{
		[app terminate];
	}, ^{
		return app.isTerminated;
	});
	if (!success) {
		NSLog(@"Could not terminate %@, abandoning restart", [app localizedName]);
		return;
	}

	/* Wait a little more so the application is ready */
	usleep(500000);
	[self openURL:bundleURL];
}

@end

@implementation NSWorkspace (QSDeprecatedProcessManagment)

- (NSInteger) pidForApplication:(NSDictionary *)theApp {
	return [[theApp objectForKey: @"NSApplicationProcessIdentifier"] integerValue];
}

- (BOOL)applicationIsRunning:(NSString *)pathOrID {
	NSArray *apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:pathOrID];
	if (apps.count >= 1) return YES;

	apps = [NSRunningApplication runningApplicationsWithPath:pathOrID];
	if (apps.count >= 1) return YES;

	return NO;
}

- (void)killApplication:(NSString *)path {
	NSArray *apps = [NSRunningApplication runningApplicationsWithPath:path];
	for (NSRunningApplication *app in apps) {
		[app forceTerminate];
	}
}

- (BOOL)applicationIsHidden:(NSDictionary *)theApp {
	NSRunningApplication *app = [self runningApplicationForOldStyleWorkspaceDictionary:theApp];
	return app.isHidden;
}

- (BOOL)applicationIsFrontmost:(NSDictionary *)theApp {
	NSRunningApplication *app = [self runningApplicationForOldStyleWorkspaceDictionary:theApp];
	return (app == [self frontmostApplication]);
}

- (void)switchToApplication:(NSDictionary *)theApp frontWindowOnly:(BOOL)frontOnly {
	NSRunningApplication *app = [self runningApplicationForOldStyleWorkspaceDictionary:theApp];
	[app activateWithOptions:frontOnly ? 0 : NSApplicationActivateAllWindows];
}

- (void)activateFrontWindowOfApplication:(NSDictionary *)theApp {
	NSRunningApplication *app = [self runningApplicationForOldStyleWorkspaceDictionary:theApp];
	[app activateWithOptions:0];
}

- (void)hideApplication:(NSDictionary *)theApp {
	NSRunningApplication *app = [self runningApplicationForOldStyleWorkspaceDictionary:theApp];
	[app hide];
}

- (void)showApplication:(NSDictionary *)theApp {
	NSRunningApplication *app = [self runningApplicationForOldStyleWorkspaceDictionary:theApp];
	[app unhide];
}

- (void)activateApplication:(NSDictionary *)theApp {
	NSRunningApplication *app = [self runningApplicationForOldStyleWorkspaceDictionary:theApp];
	ProcessSerialNumber psn;
	if (![app processSerialNumber:&psn]) return;

	AppleEvent event = {typeNull, 0};
	AEBuildError error;
	OSStatus err = AEBuildAppleEvent('misc', 'actv', typeProcessSerialNumber, &psn, sizeof(ProcessSerialNumber), kAutoGenerateReturnID, kAnyTransactionID, &event, &error, "");
	if (err)
		NSLog(@"%lu:%lu at \"%@\"", (unsigned long)error.fError, (unsigned long)error.fErrorPos, @"");
	else {
		AppleEvent reply;
		AESend(&event, &reply, kAEWaitReply, kAENormalPriority, 100, NULL, NULL);
		AEDisposeDesc(&event); // we must dispose of this and the reply.
	}
}

- (void)reopenApplication:(NSDictionary *)theApp {
	NSRunningApplication *app = [self runningApplicationForOldStyleWorkspaceDictionary:theApp];
	if (!app) return;
	NSURL *applicationURL = app.bundleURL;
	if (!applicationURL)
		applicationURL = app.executableURL;

	[self launchApplication:applicationURL.path];
}

- (void)quitApplication:(NSDictionary *)theApp {
	NSRunningApplication *app = [self runningApplicationForOldStyleWorkspaceDictionary:theApp];
	[app terminate];
}

- (BOOL)quitApplicationAndWait:(NSDictionary *)theApp {
	NSRunningApplication *app = [self runningApplicationForOldStyleWorkspaceDictionary:theApp];
	if (!app) return NO;

	return QSGCDWait(20, ^{
		[app terminate];
	}, ^{
		return app.isTerminated;
	});
}


- (void)launchACopyOfApplication:(NSDictionary *)theApp {
	NSRunningApplication *app = [self runningApplicationForOldStyleWorkspaceDictionary:theApp];

	OSStatus err;
	LSLaunchURLSpec spec;
	spec.appURL = (__bridge CFURLRef)[app executableURL];
	spec.itemURLs = NULL;
	spec.passThruParams  = NULL;
	spec.launchFlags	 = kLSLaunchNewInstance;
	spec.asyncRefCon	 = NULL;
	err = LSOpenFromURLSpec( &spec, NULL );
	NSLog(@"err %ld", (long)err);
}

- (NSString *)nameForPID:(pid_t)pid {
	return [NSRunningApplication runningApplicationWithProcessIdentifier:pid].localizedName;
}

- (NSString *)pathForPID:(pid_t)pid {
	NSURL *appURL = nil;
	NSRunningApplication *app = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
	appURL = app.bundleURL;
	if (!appURL) {
		appURL = app.executableURL;
	}
	return appURL.path;
}

@end
