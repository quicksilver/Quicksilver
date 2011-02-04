//
// QSUpdateController.m
// Quicksilver
//
// Created by Alcor on 7/22/04.
// Copyright 2004 Blacktree. All rights reserved.
//

// Ankur, Dec 12:
//	update task is now cancelled on "connection error".
//	networkIsReachable returning YES. commented out.

#import <SystemConfiguration/SystemConfiguration.h>

#import "Quicksilver.h"

#import "QSUpdateController.h"

@implementation QSUpdateController

+ (id)sharedInstance {
	static id _sharedInstance;
	if (!_sharedInstance) _sharedInstance = [[[self class] allocWithZone:[self zone]] init];
	return _sharedInstance;
}

- (id)init {
	self = [super init];
	return self;
}

- (void)forceStartupCheck {
	NSLog(@"Updated: Forcing Plug-in Check");
	doStartupCheck = YES;
}

- (void)setUpdateTimer {
	// ***warning  * fix me
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	if (DEVELOPMENTVERSION ? ![defaults boolForKey:@"QSPreventAutomaticUpdate"] : [defaults boolForKey:kCheckForUpdates]) {
		NSDate *lastCheck = [defaults objectForKey:kLastUpdateCheck];
		int frequency = [defaults integerForKey:kCheckForUpdateFrequency];
		int versionType = [defaults integerForKey:@"QSUpdateReleaseLevel"];
	//	if (DEVELOPMENTVERSION && frequency>7)
//			frequency = 7;
#ifdef DEBUG
		if (versionType>0 && frequency>1)
			frequency = 1;
#endif
		BOOL shouldRepeat = (frequency>0);
		NSTimeInterval checkInterval = frequency*24*60*60;
		//NSLog(@"Last Version Check at : %@", [lastCheck description]);
		NSDate *nextCheck = [[NSDate alloc] initWithTimeInterval:checkInterval sinceDate:lastCheck];
		//if (DEVELOPMENTVERSION)
		//nextCheck = [NSDate distantPast];
		//nextCheck = [NSDate dateWithTimeIntervalSinceNow: 20.0];
		if (updateTimer) {
			[updateTimer invalidate];
			[updateTimer release];
		}
		updateTimer = [[NSTimer scheduledTimerWithTimeInterval:checkInterval target:self selector:@selector(threadedCheckForUpdate:) userInfo:nil repeats:shouldRepeat] retain];
		[updateTimer setFireDate:( doStartupCheck ? [NSDate dateWithTimeIntervalSinceNow:33.333f] : nextCheck )];
#ifdef DEBUG
		if (VERBOSE) NSLog(@"Next Version Check at : %@", [[updateTimer fireDate] description]);
#endif
        [nextCheck release];
	}
}

- (BOOL)networkIsReachable {
    /* FIXME: Hard to get right */
    return YES;
	BOOL success = NO;
	SCNetworkConnectionFlags reachabilityStatus;
	success = SCNetworkCheckReachabilityByName("www.apple.com", &reachabilityStatus);
	success = (success && (reachabilityStatus & 3) );
#ifdef DEBUG
	if (VERBOSE) NSLog(@"Blacktree reachable: %d", reachabilityStatus);
#endif
	return success;
}

- (NSURL *)buildUpdateCheckURL {
	NSString *checkURL = [[[NSProcessInfo processInfo] environment] objectForKey:@"QSCheckUpdateURL"];
    if (!checkURL)
        checkURL = kCheckUpdateURL;
    NSString *thisVersionString = (NSString *)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey);
    
    NSString *versionType = nil;
    switch ([[NSUserDefaults standardUserDefaults] integerForKey:@"QSNewUpdateReleaseLevel"]) {
        case 2:
            versionType = @"dev";
            break;
        case 1:
            versionType = @"pre";
            break;
        default:
            versionType = @"rel";
            break;
    }
#ifdef DEBUG
    if (PRERELEASEVERSION)
        versionType = @"pre";
#endif
    
    checkURL = [checkURL stringByAppendingFormat:@"?type=%@&current=%@", versionType, thisVersionString];
#ifdef DEBUG
	if (VERBOSE) NSLog(@"Update Check URL: %@", checkURL);
#endif
    return [NSURL URLWithString:checkURL];
}

- (NSInteger)checkForUpdates:(BOOL)force {
    NSString *thisVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
	NSString *checkVersionString = nil;

    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:[self buildUpdateCheckURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];

    NSData *data = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:nil error:nil];
    checkVersionString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];

    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastUpdateCheck];
    if (![checkVersionString length] && [checkVersionString length] > 10) {
        NSLog(@"Unable to check for new version.");
        [[QSTaskController sharedInstance] removeTask:@"Check for Update"];
        return -1;
    }

    BOOL newVersionAvailable = [checkVersionString hexIntValue] > [thisVersionString hexIntValue];
    /* We have to get the current available version, because it will get displayed to the user,
     * so force happens only if there's a valid response from the server
     */
    newVersion = [checkVersionString retain];
#ifdef DEBUG
    if (VERBOSE)
        NSLog(@"Installed Version: %@, Available Version: %@, Valid: %@, Force update: %@", thisVersionString, checkVersionString, (newVersionAvailable ? @"YES" : @"NO"), (force ? @"YES" : @"NO"));
#endif
    return (newVersionAvailable || force) ? 1 : 0;
}

- (BOOL)checkForUpdatesInBackground:(BOOL)quiet force:(BOOL)force {
	[[QSTaskController sharedInstance] updateTask:@"Check for Update" status:@"Check for Update" progress:-1];
    BOOL updated = NO;
    BOOL reachable = [self networkIsReachable];
    if (!reachable) {
        NSLog(@"Network unreacheable");
        [[QSTaskController sharedInstance] removeTask:@"Check for Update"];
        if (!quiet) {
            int result = NSRunInformationalAlertPanel(@"Connection Error", @"Your internet connection does not appear to be active.", @"Cancel", @"Check Anyway", nil);
            if (result == NSAlertDefaultReturn)
                return NO;
        } else
            return NO;
    }

    NSInteger check = [self checkForUpdates:force];
    [[QSTaskController sharedInstance] removeTask:@"Check for Update"];
    if (check == -1) {
        if (!quiet)
            NSRunInformationalAlertPanel(@"Connection Error", @"Unable to check for updates.", @"OK", nil, nil);
        return NO;
    } else if (check == 1) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"QSDownloadUpdatesInBackground"]) {
            [self performSelectorOnMainThread:@selector(installAppUpdate) withObject:nil waitUntilDone:NO];
        } else {
            int selection = NSRunInformationalAlertPanel([NSString stringWithFormat:@"New Version", nil], @"A new version of Quicksilver, version %@, is available; would you like to download it now?", @"Get New Version", @"Cancel", nil, newVersion); //, @"More Info");
            if (selection == 1) {
                [self performSelectorOnMainThread:@selector(installAppUpdate) withObject:nil waitUntilDone:NO];
            } else if (selection == -1) {  //Go to web site
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kWebSiteURL]];
            }
        }
        return YES;
    } else {
        updated = [[QSPlugInManager sharedInstance] checkForPlugInUpdates];
        if (!updated) {
            NSLog(@"Quicksilver is up to date.");
            if (!quiet)
                NSRunInformationalAlertPanel(@"No Updates Available", [NSString stringWithFormat:@"You already have the latest version of Quicksilver (v%@) and all installed plug-ins", [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]] , @"OK", nil, nil);
        }
    }

    return updated;
}

- (BOOL)threadedCheckForUpdates:(BOOL)force {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    BOOL res = [self checkForUpdatesInBackground:NO force:force];
    [pool release];
    return res;
}

- (BOOL)threadedCheckForUpdatesInBackground:(BOOL)force {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    BOOL res = [self checkForUpdatesInBackground:YES force:force];
    [pool release];
    return res;
}

- (IBAction)checkForUpdate:(id)sender {
	BOOL quiet = !sender || sender == self || [sender isKindOfClass:[NSTimer class]];
	BOOL forceUpdate = [sender isEqual:@"Force"];

    [self checkForUpdatesInBackground:quiet force:forceUpdate];
}

- (void)handleURL:(NSURL *)url {
	[self threadedCheckForUpdatesInBackground:NO];
}

- (IBAction)threadedCheckForUpdate:(id)sender {
	[self threadedCheckForUpdates:NO];
}

- (IBAction)threadedRequestedCheckForUpdate:(id)sender {
	[self threadedCheckForUpdates:mOptionKeyIsDown];
}

- (void)installAppUpdate {
	if (updateTask) return;

	NSString *fileURL = [[[NSProcessInfo processInfo] environment] objectForKey:@"QSDownloadUpdateURL"];
	if (!fileURL)
        fileURL = kDownloadUpdateURL;

    fileURL = [fileURL stringByAppendingFormat:@"?id=%@&type=dmg&new=yes", [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleIdentifierKey]];

    int versionType = [[NSUserDefaults standardUserDefaults] integerForKey:@"QSUpdateReleaseLevel"];
    if (versionType == 2)
        fileURL = [fileURL stringByAppendingString:@"&dev=1"];
    else if (versionType == 1)
        fileURL = [fileURL stringByAppendingString:@"&pre=1"];
#ifdef DEBUG
	if (VERBOSE) NSLog(@"Downloading update from %@", fileURL);
#endif

	NSURL *url = [NSURL URLWithString:fileURL];
	NSURLRequest *theRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];

	// NSLog(@"app %@", theRequest);
	// create the connection with the request
	// and start loading the data
	appDownload = [[QSURLDownload alloc] initWithRequest:theRequest delegate:self];
	if (appDownload) {
		updateTask = [[QSTask taskWithIdentifier:@"QSAppUpdateInstalling"] retain];
		[updateTask setName:@"Downloading Update"];
		[updateTask setProgress:-1];

        [updateTask setCancelAction:@selector(cancelUpdate:)];
		[updateTask setCancelTarget:self];

		[QSTaskController showViewer];
		[updateTask startTask:nil];
        [appDownload start];
	}
}

//- (NSDictionary *)downloadInfoForDownload:(NSURLDownload *)download {
//	//NSLog(@"url %@ %@", [appDownload objectForKey:@"download"] , download);
//	if ([appDownload isEqual:download]) return appDownload;
//
//	NSEnumerator *e = [[self downloadsQueue] objectEnumerator];
//
//	NSMutableDictionary *info;
//	while(info = [e nextObject]) {
//		if ([[info objectForKey:@"download"] isEqual:download]) break;
//	}
//	return info;
//}
- (void)download:(QSURLDownload *)download didFailWithError:(NSError *)error {
    if (download != appDownload)
        return;
	NSLog(@"Download Failed");
	//	[[QSTaskController sharedInstance] removeTask:@"QSAppUpdateInstalling"];
	[updateTask stopTask:nil];
	[updateTask release];
	updateTask = nil;
	NSRunInformationalAlertPanel(@"Download Failed", @"An error occured while updating: %@", @"OK", nil, nil, [error localizedDescription] );
    [appDownload cancel];
	[appDownload release];
}

- (void)downloadDidFinish:(QSURLDownload *)download {
    [download cancel];
	[download release];

	BOOL plugInUpdates = [[QSPlugInManager sharedInstance] updatePlugInsForNewVersion:newVersion];

	if (plugInUpdates) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												selector:@selector(finishAppInstall)
													name:@"QSPlugInUpdatesFinished"
												 object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												selector:@selector(finishAppInstall)
													name:@"QSPlugInUpdatesFailed"
												 object:nil];
	} else {
		NSLog(@"Plug-ins don't need update");
		[self finishAppInstall];
	}
}

- (void)downloadDidUpdate:(QSURLDownload *)download {
    NSString * status = [NSString stringWithFormat:@"%.0fk of %.0fk", (double) [download currentContentLength] /1024, (double)[download expectedContentLength] /1024];
    [updateTask setStatus:status];
	[updateTask setProgress:[(QSURLDownload *)download progress]];
}

- (void)cancelUpdate:(QSTask *)task {
	shouldCancel = YES;
	[appDownload cancel];
    [appDownload release], appDownload = nil;
	[updateTask stopTask:nil];
	[updateTask release];
	updateTask = nil;
}

- (void)finishAppInstall {
	NSString *path = [appDownload destination];

	[updateTask setStatus:@"Download Complete"];
	[updateTask setProgress:1.0];
    
    NSInteger selection = 0;
	BOOL update = [[NSUserDefaults standardUserDefaults] boolForKey:@"QSUpdateWithoutAsking"];
	if (!update) {
        selection = NSRunInformationalAlertPanel(@"Download Successful", @"A new version of Quicksilver has been downloaded. This version must be relaunched after it is installed.", @"Install and Relaunch", @"Cancel Update", nil);
		update = (selection == NSAlertDefaultReturn);
    }
    
    //[self installAppFromCompressedFile:path];
    NSString *installPath = nil;
    if (update) {
        installPath = [self installAppFromDiskImage:path];
        if (!installPath) {
            selection = NSRunInformationalAlertPanel(@"Installation Failed", @"It was not possible to decompress downloaded file.", @"Cancel Update", @"Download manually", nil);
            if (selection == NSAlertAlternateReturn)
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kWebSiteURL]];
        }
    }
    if (installPath) {
        BOOL relaunch = [[NSUserDefaults standardUserDefaults] boolForKey:@"QSRelaunchAutomaticallyAfterUpdate"];
        if (!relaunch) {
            selection = NSRunInformationalAlertPanel(@"Installation Successful", @"A new version of Quicksilver has been installed. This version must be relaunched after it is installed.", @"Relaunch", @"Relaunch Later", nil);
            relaunch = (selection == NSAlertDefaultReturn);
        }
        if (relaunch)
            [NSApp relaunchFromPath:installPath];
    }

	[updateTask stopTask:nil];
	[updateTask release], updateTask = nil;
}

- (NSString *)installAppFromCompressedFile:(NSString *)path {
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSString *tempDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"QSUpdate"];
    [manager createDirectoryAtPath:tempDirectory withIntermediateDirectories:NO attributes:nil error:nil];
    
    [updateTask setName:@"Installing Update"];
    [updateTask setStatus:@"Extracting Data"];
    [updateTask setProgress:-1.0];
    NSArray *extracted = [self extractFilesFromQSPkg:path toPath:tempDirectory];
    if ([extracted count] != 1) {
        NSLog(@"App Update Error");
        return nil;
    }
    
    NSString *newAppVersionPath = [tempDirectory stringByAppendingPathComponent:[extracted lastObject]];
    
    [updateTask setStatus:@"Copying Application"];
    [NSApp replaceWithUpdateFromPath:newAppVersionPath];
    [updateTask setStatus:@"Cleaning Up"];

    return newAppVersionPath;
}

- (NSString *)installAppFromDiskImage:(NSString *)path {
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSString *tempDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString uniqueString]];
    [manager createDirectoryAtPath:tempDirectory withIntermediateDirectories:NO attributes:nil error:nil];
    
    [updateTask setName:@"Installing Update"];
    [updateTask setStatus:@"Verifying Data"];
    [updateTask setProgress:-1.0];
    
    NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/hdiutil"
                                            arguments:[NSArray arrayWithObjects:@"attach", path, @"-nobrowse", @"-mountpoint", tempDirectory, nil]];
    
    [task waitUntilExit];
    
    if ([task terminationStatus] != 0)
        return nil;

    NSArray *extracted = [[manager contentsOfDirectoryAtPath:tempDirectory error:nil] pathsMatchingExtensions:[NSArray arrayWithObject:@"app"]];
    if ([extracted count] != 1)
        return nil;

    NSString *newAppVersionPath = [tempDirectory stringByAppendingPathComponent:[extracted lastObject]];
    if (!newAppVersionPath)
        return nil;
    
    [updateTask setStatus:@"Copying Application"];
    [NSApp replaceWithUpdateFromPath:newAppVersionPath];
    [updateTask setStatus:@"Cleaning Up"];
    
    task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/hdiutil"
                                    arguments:[NSArray arrayWithObjects:@"detach", tempDirectory, nil]];
    [task waitUntilExit];
    [[NSFileManager defaultManager] removeItemAtPath:tempDirectory error:nil];
    
    [tempPath release];
    tempPath = nil;
    return newAppVersionPath;    
}

- (NSArray *)extractFilesFromQSPkg:(NSString *)path toPath:(NSString *)tempDirectory {
	if (!path) return nil;
	NSFileManager *manager = [NSFileManager defaultManager];
	NSTask *task = [[[NSTask alloc] init] autorelease];
	[task setLaunchPath:@"/usr/bin/ditto"];

	[task setArguments:[NSArray arrayWithObjects:@"-x", @"-rsrc", path, tempDirectory, nil]];
	[task launch];
	[task waitUntilExit];
	int status = [task terminationStatus];
	if (status == 0) {
		[manager removeItemAtPath:path error:nil];
		[[NSWorkspace sharedWorkspace] noteFileSystemChanged:[path stringByDeletingLastPathComponent]];
		return [manager contentsOfDirectoryAtPath:tempDirectory error:nil];
	} else {
		return nil;
	}

}

@end

