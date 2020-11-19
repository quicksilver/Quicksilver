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


# pragma mark TO DEPRECATE / REMOVE
// The following methods in this section should be removed once we fully switch to using NSRunningApplication (instead of app dicts)


// compatibility method to convert from NSWorkspace 'old' app dicts to NSRunning application
- (NSDictionary *)appDictFromNSRunningApplication:(NSRunningApplication *)app {
	return @{
			 @"NSApplicationBundleIdentifier" : app.bundleIdentifier,
			 @"NSApplicationName" : app.localizedName,
			 @"NSApplicationProcessIdentifier" : [NSNumber numberWithInt:app.processIdentifier],
			 @"NSWorkspaceApplicationKey" : app
			 };
}

- (NSRunningApplication *)runningApplicationFromAppDict:(NSDictionary *)appDict {
	return [NSRunningApplication runningApplicationWithProcessIdentifier:((NSNumber *)[appDict objectForKey:@"NSApplicationProcessIdentifier"]).intValue];
}

// used in QSPathFinderPlugin, can be removed once that's updated
- (NSDictionary *)dictForApplicationIdentifier:(NSString *)ident {
	for(NSRunningApplication *theApp in [self runningApplications]) {
		if ([theApp.bundleIdentifier isEqualToString:ident])
			return [self appDictFromNSRunningApplication:theApp];
	}
	return nil;
}

- (NSInteger) pidForApplication:(NSDictionary *)theApp {
	return [[theApp objectForKey: @"NSApplicationProcessIdentifier"] integerValue];
}

#pragma mark METHODS


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

- (BOOL)applicationIsRunning:(NSString *)pathOrID {
	return [[self runningApplications] indexesOfObjectsPassingTest:^BOOL(NSRunningApplication * _Nonnull theApp, NSUInteger idx, BOOL * _Nonnull stop) {
		if ([theApp.bundleIdentifier isEqualToString:pathOrID] || [theApp.bundleURL.path isEqualToString:pathOrID]) {
			*stop = YES;
			return YES;
		}
		return NO;
	}].count;
}

- (NSRunningApplication *)appForApplicationNameOrPath:(NSString *)nameOrPath {
	for(NSRunningApplication *theApp in [self runningApplications]) {
		if ([theApp.bundleURL.path  isEqualToString:nameOrPath] || [theApp.localizedName isEqualToString:nameOrPath])
			return theApp;
	}
	return nil;
}

- (BOOL)applicationIsFrontmost:(NSDictionary *)theApp {
	return [self pidForApplication:theApp] == [self frontmostApplication].processIdentifier;
}

- (void)switchToApplication:(NSDictionary *)theApp frontWindowOnly:(BOOL)frontOnly {
	NSRunningApplication *app = [self runningApplicationFromAppDict:theApp];
	if (app) {
		if (frontOnly) {
			[app activateWithOptions:NSApplicationActivateIgnoringOtherApps];
		} else {
			[app activateWithOptions:NSApplicationActivateAllWindows];
		}
	} else {
		[self activateApplication:theApp];
	}
}

- (void)activateFrontWindowOfApplication:(NSDictionary *)theApp {
	NSRunningApplication *app = [self runningApplicationFromAppDict:theApp];
	if (app) {
		[app activateWithOptions:NSApplicationActivateIgnoringOtherApps];
	} else {
		[self activateApplication:theApp];
	}
}

- (void)hideApplication:(NSDictionary *)theApp {
	NSRunningApplication *app = [self runningApplicationFromAppDict:theApp];
	if (app) {
		[app hide];
	}
	
}

- (void)hideOtherApplications:(NSArray *)theApps {
	NSUInteger count = [theApps count];
	pid_t pidsToShow[count];
	NSUInteger i;
	for (i = 0; i<count; i++) {
		pidsToShow[i] = (pid_t)[self pidForApplication:[theApps objectAtIndex:i]];
	}
	
	BOOL shouldShow;
	for (NSRunningApplication *app in [self runningApplications]) {
		shouldShow = NO;
		for (i = 0; i< count; i++) {
			if (app.processIdentifier == pidsToShow[i]) {
				shouldShow = YES;
				break;
			}
		}
		if (shouldShow) {
			[app unhide];
		} else {
			[app hide];
		}
	}
}

- (BOOL)appIsBackground:(NSRunningApplication *)app {
	// Ideally, this should go under NSRunningApplication class extension, and used as follows:
	// BOOL isBackground = [runningApp isBackgroundApp]
	
	NSDictionary *bundleInfo = [[NSBundle bundleWithURL:app.bundleURL] infoDictionary];
	if (![[bundleInfo objectForKey:@"CFBundlePackageType"] isEqualToString:@"APPL"]) {
		// all non 'APPL' (application) type processes are background. E.g. XPC, Framework etc.
		return YES;
	}
	return ([[bundleInfo objectForKey:@"LSBackgroundOnly"] boolValue]
		    || [[bundleInfo objectForKey:@"LSUIElement"] boolValue]
			|| [[bundleInfo objectForKey:@"NSUIElement"] boolValue]);
}

- (void)quitOtherApplications:(NSArray *)theApps {
	
	NSUInteger count = [theApps count];
	pid_t pidsToShow[count];
	NSUInteger i;
	for (i = 0; i<count; i++) {
		pidsToShow[i] = (pid_t)[self pidForApplication:[theApps objectAtIndex:i]];
	}
	
	BOOL shouldKeepAlive;
	for (NSRunningApplication *app in [self runningApplications]) {
		shouldKeepAlive = NO;
		for (i = 0; i< count; i++) {
			if (app.processIdentifier == pidsToShow[i] || [app.bundleIdentifier isEqualToString:@"com.apple.Finder"] || [self appIsBackground:app]) {
				shouldKeepAlive = YES;
				break;
			} else {
				//NSLog(@"quitting app %@", app);
			}
		}
		if (shouldKeepAlive) {
			[app unhide];
		} else {
			[app terminate];
		}
	}
}

- (void)showApplication:(NSDictionary *)theApp {
	NSRunningApplication *app = [self runningApplicationFromAppDict:theApp];
	if (app) {
		if(![app unhide]) {
			NSLog(@"Error: unable to show app %@", theApp);
		}
	}
}

- (void)activateApplication:(NSDictionary *)theApp {
	NSRunningApplication *app = [self runningApplicationFromAppDict:theApp];
	if (app) {
		if (![app activateWithOptions:NSApplicationActivateIgnoringOtherApps]) {
			NSLog(@"Error: unable to activate app %@", theApp);
		}
	}
}

- (void)reopenApplication:(NSDictionary *)theApp {
	[self launchApplication:[theApp objectForKey:@"NSApplicationPath"]];
}

- (void)quitApplication:(NSDictionary *)theApp {
	NSRunningApplication *app = [self runningApplicationFromAppDict:theApp];
	[app terminate];
}


- (void)launchACopyOfApplication:(NSDictionary *)theApp {
	OSStatus err;
	LSLaunchURLSpec spec;
	spec.appURL = (__bridge CFURLRef) [NSURL fileURLWithPath:[theApp objectForKey:@"NSApplicationPath"]];
	spec.itemURLs = NULL;
	spec.passThruParams  = NULL;
	spec.launchFlags	 = kLSLaunchNewInstance;
	spec.asyncRefCon	 = NULL;
	err = LSOpenFromURLSpec( &spec, NULL );
	NSLog(@"err %ld", (long)err);
	//CFRelease( spec.appURL );
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
- (void)relaunchApplication:(NSDictionary *)theApp {
	if ([[theApp objectForKey:@"NSApplicationProcessIdentifier"] integerValue] == [[NSProcessInfo processInfo] processIdentifier]) {
		[NSApp relaunch:nil];
    }
    NSRunningApplication *runningApplication = [NSRunningApplication runningApplicationWithProcessIdentifier:[[theApp objectForKey:@"NSApplicationProcessIdentifier"] intValue]];

    if (!runningApplication) {
        NSBeep();
        NSLog(@"Unable to find application %@ to restart", theApp);
        return;
    }
    NSURL *bundleURL = [runningApplication bundleURL];
    [runningApplication terminate];
    NSDate *aDate = [NSDate date];
    while(![runningApplication isTerminated]) {       
        
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        
        usleep(100000);
        
        // break: it's been 20s since the action was called
        if (-[aDate timeIntervalSinceNow] > 12) {
            NSLog(@"Could not terminate %@, abandoning restart",[runningApplication localizedName]);
            return;
        }
        
		}
		usleep(200000);
		[self openURL:bundleURL];
}

@end
