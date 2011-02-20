//
// NSWorkspace_BLTRExtensions.m
// Quicksilver
//
// Created by Alcor on Fri May 09 2003.
// Copyright (c) 2003 Blacktree, Inc. All rights reserved.
//

#import "NSString+CarbonUtilities.h"
#import "NSWorkspace_BLTRExtensions.h"
#import "NSApplication_BLTRExtensions.h"
#include <signal.h>
#include <unistd.h>
#import "Carbon/Carbon.h"

bool _LSCopyAllApplicationURLs(NSArray **array);

@implementation NSWorkspace (Misc)

- (NSString *)commentForFile:(NSString *)path; {
	if(path){
		if ([self applicationIsRunning:@"com.apple.finder"]) {
			NSString *hfsPath;
			NSAppleScript *script;
			NSAppleEventDescriptor *aeDesc;

			CFURLRef fileURL = CFURLCreateWithFileSystemPath(NULL, (CFStringRef)path, kCFURLPOSIXPathStyle, NO);
			hfsPath = (NSString *)CFURLCopyFileSystemPath(fileURL, kCFURLHFSPathStyle);
			CFRelease(fileURL);

			script = [[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:@"tell application \"Finder\" to comment of item \"%@\"", hfsPath]];
			[hfsPath release];
			aeDesc = [script executeAndReturnError:nil];
			[script release];
			return [aeDesc stringValue];
		} else {
			NSBeep();
		}
	}
	return nil;
}

- (BOOL)setComment:(NSString*)comment forFile:(NSString *)path; {
	BOOL result = NO;

	// only call if Finder is running
	// finderProcess = [NTPM processWithName:@"Finder"];
	if ([self applicationIsRunning:@"com.apple.finder"]) {
		NSString* scriptText, *hfsPath;
		NSAppleScript *script;

		CFURLRef fileURL = CFURLCreateWithFileSystemPath(NULL, (CFStringRef) path, kCFURLPOSIXPathStyle, NO);
		hfsPath = (NSString *)CFURLCopyFileSystemPath(fileURL, kCFURLHFSPathStyle);
		CFRelease(fileURL);

		scriptText = [NSString stringWithFormat:@"tell application \"Finder\" to set comment of item \"%@\" to \"%@\"", hfsPath, comment];
        [hfsPath release];
		script = [[NSAppleScript alloc] initWithSource:scriptText];
		result = ([[script executeAndReturnError:nil] stringValue] != nil);
		[script release];
	} else {
		NSBeep();
	}
	return result;
}

- (NSArray *)allApplications {
	NSArray *appURLs = nil;
	_LSCopyAllApplicationURLs(&appURLs);
	NSMutableArray *apps = [NSMutableArray arrayWithCapacity:[appURLs count]];
	for (id loopItem in appURLs) {
		[apps addObject:[loopItem path]];
	}
	[appURLs release];
	return apps;
}

- (int) pidForApplication:(NSDictionary *)theApp {
	return [[theApp objectForKey: @"NSApplicationProcessIdentifier"] intValue];
}
- (BOOL)applicationIsRunning:(NSString *)pathOrID {
	return ([self dictForApplicationName:pathOrID] || [self dictForApplicationIdentifier:pathOrID]);
}
- (NSDictionary *)dictForApplicationName:(NSString *)path {
	NSDictionary * theApp;
	NSEnumerator *appEnumerator = [[self launchedApplications] objectEnumerator];
	for(theApp in appEnumerator) {
		if ([[theApp objectForKey:@"NSApplicationPath"] isEqualToString:path] || [[theApp objectForKey:@"NSApplicationName"] isEqualToString:path])
			return theApp;
	}
	return nil;
}

- (NSDictionary *)dictForApplicationIdentifier:(NSString *)ident {
	NSDictionary * theApp;
	NSEnumerator *appEnumerator = [[self launchedApplications] objectEnumerator];
	for(theApp in appEnumerator) {
		if ([[theApp objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:ident])
			return theApp;
	}
	return nil;
}

- (void)killApplication:(NSString *)path {
	NSDictionary *theApp = [self dictForApplicationName:path];
	if (theApp)
		kill((pid_t)[[theApp objectForKey:@"NSApplicationProcessIdentifier"] intValue], SIGKILL);
}

- (BOOL)applicationIsHidden:(NSDictionary *)theApp {
	ProcessSerialNumber psn;
	if ([self PSN:&psn forApplication:theApp])
		return !(IsProcessVisible(&psn));
	return YES;
}

- (BOOL)applicationIsFrontmost:(NSDictionary *)theApp {
	return [self pidForApplication:theApp] == [self pidForApplication:[self activeApplication]];
}

- (BOOL)PSN:(ProcessSerialNumber *)psn forApplication:(NSDictionary *)theApp {
	if (theApp){
		(*psn).highLongOfPSN = [[theApp objectForKey:@"NSApplicationProcessSerialNumberHigh"] longValue];
		(*psn).lowLongOfPSN = [[theApp objectForKey:@"NSApplicationProcessSerialNumberLow"] longValue];
		return YES;
	}
	return NO;
}

- (void)switchToApplication:(NSDictionary *)theApp frontWindowOnly:(BOOL)frontOnly {
	ProcessSerialNumber psn;
	if ([self PSN:&psn forApplication:theApp])
		SetFrontProcessWithOptions (&psn, frontOnly?kSetFrontProcessFrontWindowOnly:0);
	else
		[self activateApplication:theApp];
}

- (void)activateFrontWindowOfApplication:(NSDictionary *)theApp {
	ProcessSerialNumber psn;
	if ([self PSN:&psn forApplication:theApp])
		SetFrontProcessWithOptions (&psn, kSetFrontProcessFrontWindowOnly);
	else
		[self activateApplication:theApp];
}

- (void)hideApplication:(NSDictionary *)theApp {
	ProcessSerialNumber psn;
	if ([self PSN:&psn forApplication:theApp])
		ShowHideProcess(&psn, FALSE);
}

- (void)hideOtherApplications:(NSArray *)theApps {
	NSDictionary *theApp = [theApps lastObject];
	int count = [theApps count];
	int i;
	ProcessSerialNumber psn[count];
	for (i = 0; i<count; i++)
		[self PSN:psn+i forApplication:[theApps objectAtIndex:i]];
	[self switchToApplication:theApp frontWindowOnly:YES];

	ProcessSerialNumber thisPSN;
	thisPSN.highLongOfPSN = kNoProcess;
	thisPSN.lowLongOfPSN = 0;
	Boolean show = 0;
	while(GetNextProcess ( &thisPSN ) == noErr) {
		for (i = 0; i<[theApps count]; i++) {
			SameProcess(&thisPSN, psn+i, &show);
			if (show) break;
		}
		ShowHideProcess(&thisPSN, show);
	}
}

- (void)quitOtherApplications:(NSArray *)theApps {
	NSDictionary *theApp = [theApps lastObject];
	int count = [theApps count];
	int i;
	ProcessSerialNumber psn[count];
	for (i = 0; i<count; i++)
		[self PSN:psn+i forApplication:[theApps objectAtIndex:i]];
	[self reopenApplication:theApp];
	ProcessSerialNumber thisPSN;
	thisPSN.highLongOfPSN = kNoProcess;
	thisPSN.lowLongOfPSN = 0;
	Boolean show = NO;
	ProcessSerialNumber myPSN;
	MacGetCurrentProcess(&myPSN);

	while(GetNextProcess ( &thisPSN ) == noErr) {
		BOOL getout;
		NSDictionary *dict = (NSDictionary *)ProcessInformationCopyDictionary(&thisPSN, kProcessDictionaryIncludeAllInformationMask);
		getout = [[dict objectForKey:@"LSUIElement"] boolValue] || [[dict objectForKey:@"LSBackgroundOnly"] boolValue];
		[dict release];
		if (getout) continue;
		NSString *name;
		CopyProcessName(&thisPSN, (CFStringRef *)&name);
		getout = [name isEqualToString:@"Finder"];
		[name release];
		if (getout) continue;

		SameProcess(&thisPSN, &myPSN, &show);
		if (show) continue;

		for (i = 0; i<[theApps count]; i++) {
			SameProcess(&thisPSN, psn+i, &show);
			if (show) break;
		}
		if (!show)
			[self quitPSN:thisPSN];
		//		ShowHideProcess(&thisPSN, show);
	}
}

- (void)showApplication:(NSDictionary *)theApp {
	ProcessSerialNumber psn;
	if ([self PSN:&psn forApplication:theApp])
		ShowHideProcess(&psn, TRUE);
}

- (void)activateApplication:(NSDictionary *)theApp {
	ProcessSerialNumber psn;
	if ([self PSN:&psn forApplication:theApp]){
		AppleEvent event = {typeNull, 0};
		AEBuildError error;
		OSStatus err = AEBuildAppleEvent('misc', 'actv', typeProcessSerialNumber, &psn, sizeof(ProcessSerialNumber), kAutoGenerateReturnID, kAnyTransactionID, &event, &error, "");
		if (err)
			NSLog(@"%ld:%ld at \"%@\"", error.fError, error.fErrorPos, @"");
		else {
			AppleEvent reply;
			AESend(&event, &reply, kAEWaitReply, kAENormalPriority, 100, NULL, NULL);
			AEDisposeDesc(&event); // we must dispose of this and the reply.
		}
	}
}

- (void)reopenApplication:(NSDictionary *)theApp {
	[self launchApplication:[theApp objectForKey:@"NSApplicationPath"]];
	// ***warning  * should learn to use reopen aevnt
#if 0
	ProcessSerialNumber psn;
	if (![self PSN:&psn forApplication:theApp]) return;
	AppleEvent event = {typeNull, 0} ;
	AEBuildError error;

	OSStatus err = AEBuildAppleEvent(kCoreEventClass, kAEQuitApplication, typeProcessSerialNumber, &psn, sizeof(ProcessSerialNumber), kAutoGenerateReturnID, kAnyTransactionID, &event, &error, "");

	if (err) NSLog(@"%d:%d at \"%@\"", error.fError, error.fErrorPos, @"");
	else {
		err = AESend(&event, NULL, kAENoReply, kAENormalPriority, kAEDefaultTimeout, NULL, NULL);
		AEDisposeDesc(&event); // we must dispose of this and the reply.
	}
	if (err) NSLog(@"error");
#endif
}

- (void)quitApplication:(NSDictionary *)theApp {
	ProcessSerialNumber psn;
	if ([self PSN:&psn forApplication:theApp])
		[self quitPSN:psn];
}

- (void)quitPSN:(ProcessSerialNumber)psn {
	AppleEvent event = {typeNull, 0};
	AEBuildError error;

	OSStatus err = AEBuildAppleEvent(kCoreEventClass, kAEQuitApplication, typeProcessSerialNumber, &psn, sizeof(ProcessSerialNumber), kAutoGenerateReturnID, kAnyTransactionID, &event, &error, "");
	if (err)
		NSLog(@"%ld:%ld at \"%@\"", error.fError, error.fErrorPos, @"");
	else {
		err = AESend(&event, NULL, kAENoReply, kAENormalPriority, kAEDefaultTimeout, NULL, NULL);
		AEDisposeDesc(&event); // we must dispose of this and the reply.
	}
	if (err) NSLog(@"error");
}

- (BOOL)quitApplicationAndWait:(NSDictionary *)theApp {
	ProcessSerialNumber psn;
	if ([self PSN:&psn forApplication:theApp]){
		AppleEvent event = {typeNull, 0};
		AEBuildError error;
		OSStatus err = AEBuildAppleEvent(kCoreEventClass, kAEQuitApplication, typeProcessSerialNumber, &psn, sizeof(ProcessSerialNumber), kAutoGenerateReturnID, kAnyTransactionID, &event, &error, "");
		if (err)
			NSLog(@"%ld:%ld at \"%@\"", error.fError, error.fErrorPos, @"");
		else {
			err = AESend(&event, NULL, kAEWaitReply, kAENormalPriority, kAEDefaultTimeout, NULL, NULL);
			AEDisposeDesc(&event); // we must dispose of this and the reply.
		}
		if (err) NSLog(@"error");
		return err;
	} else
		return NO;
}


- (void)launchACopyOfApplication:(NSDictionary *)theApp {
	OSStatus err;
	LSLaunchURLSpec spec;
	spec.appURL = (CFURLRef) [NSURL fileURLWithPath:[theApp objectForKey:@"NSApplicationPath"]];
	spec.itemURLs = NULL;
	spec.passThruParams  = NULL;
	spec.launchFlags	 = kLSLaunchNewInstance;
	spec.asyncRefCon	 = NULL;
	err = LSOpenFromURLSpec( &spec, NULL );
	NSLog(@"err %ld", err);
	//CFRelease( spec.appURL );
}
- (BOOL)openFileInBackground:(NSString *)fullPath {
	struct LSLaunchURLSpec launchSpec = {
		.appURL = NULL,
		.itemURLs = (CFArrayRef) [NSArray arrayWithObject:[NSURL fileURLWithPath:fullPath]],
		.passThruParams = NULL,
		.launchFlags = kLSLaunchAsync | kLSLaunchDontSwitch | kLSLaunchNoParams,
		.asyncRefCon = NULL,
	};
	return !LSOpenFromURLSpec(&launchSpec, NULL);
}
- (void)relaunchApplication:(NSDictionary *)theApp {
	if ([[theApp objectForKey:@"NSApplicationProcessIdentifier"] intValue] == [[NSProcessInfo processInfo] processIdentifier])
		[NSApp relaunch:nil];

	ProcessSerialNumber psn;
	if ([self PSN:&psn forApplication:theApp]){
		[self quitApplicationAndWait:theApp];
		int pid;
		NSString *bundlePath = [[theApp objectForKey:@"NSApplicationPath"] stringByDeletingLastPathComponent];
		if ([[bundlePath lastPathComponent] isEqualToString:@"MacOS"] || [[bundlePath lastPathComponent] isEqualToString:@"MacOSClassic"]) {
			bundlePath = [bundlePath stringByDeletingLastPathComponent];
			if ([[bundlePath lastPathComponent] isEqualToString:@"Contents"])
				bundlePath = [bundlePath stringByDeletingLastPathComponent];
		} else {
			bundlePath = [theApp objectForKey:@"NSApplicationPath"];
		}
		while(1) {
			int status = GetProcessPID(&psn, &pid);
			NSLog(@"waiting for %@ to quit, current status :%d for PID %d", bundlePath, status, pid);
			// wait for half a second
			usleep(500000);
			// Status -600 means process not found. 
			// Fix to 'relaunch' action bug done by removing if(status == 0).
			if (status == -600) break;
		}
		usleep(500000);
		[self openFile:bundlePath];
	}
}

- (NSString *)nameForPID:(int)pid {
	ProcessSerialNumber psn;
	if (!GetProcessForPID(pid, &psn) ) {
		NSString *name = nil;
		if (!CopyProcessName(&psn, (CFStringRef *)&name))
			return [name autorelease];
	}
	return nil;
}

- (NSString *)pathForPID:(int)pid {
	ProcessSerialNumber psn;
	FSRef ref;
	if (!GetProcessForPID(pid, &psn) && !GetProcessBundleLocation(&psn, &ref))
		return [NSString stringWithFSRef:&ref];
	return nil;
}

@end
