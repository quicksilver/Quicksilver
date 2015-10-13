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

#import "Quicksilver.h"

#import "QSUpdateController.h"

@implementation QSUpdateController

+ (id)sharedInstance {
	static id _sharedInstance;
	if (!_sharedInstance) _sharedInstance = [[[self class] alloc] init];
	return _sharedInstance;
}

- (id)init {
	self = [super init];
	return self;
}

- (void)forceStartupCheck {
	NSLog(@"Updated: Forcing Plugin Check");
	doStartupCheck = YES;
}

- (void)setUpdateTimer {
	// ***warning  * fix me
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

#ifdef DEBUG
	if (![defaults boolForKey:@"QSPreventAutomaticUpdate"]) {
#else
    if ([defaults boolForKey:kCheckForUpdates]) {
#endif
		NSDate *lastCheck = [defaults objectForKey:kLastUpdateCheck];
		// leaving this `nil` can cause Quicksilver to hang if it starts very soon after login
		if (!lastCheck) {
			lastCheck = [NSDate distantPast];
		}
		NSInteger frequency = [defaults integerForKey:kCheckForUpdateFrequency];
#ifdef DEBUG
        NSInteger versionType = [defaults integerForKey:@"QSUpdateReleaseLevel"];
		if (versionType>0 && frequency>1)
			frequency = 1;
#endif
		BOOL shouldRepeat = (frequency>0);
		NSTimeInterval checkInterval = frequency*24*60*60;
		//NSLog(@"Last Version Check at : %@", [lastCheck description]);
		NSDate *nextCheck = [[NSDate alloc] initWithTimeInterval:checkInterval sinceDate:lastCheck];
		//nextCheck = [NSDate distantPast];
		//nextCheck = [NSDate dateWithTimeIntervalSinceNow: 20.0];
		if (updateTimer) {
			[updateTimer invalidate];
		}
		updateTimer = [NSTimer scheduledTimerWithTimeInterval:checkInterval target:self selector:@selector(threadedCheckForUpdate:) userInfo:nil repeats:shouldRepeat];
		[updateTimer setFireDate:( doStartupCheck ? [NSDate dateWithTimeIntervalSinceNow:33.333f] : nextCheck )];
#ifdef DEBUG
		if (VERBOSE) NSLog(@"Next Version Check at : %@", [[updateTimer fireDate] description]);
#endif
	}
}

- (NSURL *)buildUpdateCheckURL {
	NSString *checkURL = [[[NSProcessInfo processInfo] environment] objectForKey:@"QSCheckUpdateURL"];
    if (!checkURL)
        checkURL = kCheckUpdateURL;
    NSString *thisVersionString = (__bridge NSString *)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey);
    
    NSString *versionType = nil;
    switch ([[NSUserDefaults standardUserDefaults] integerForKey:@"QSUpdateReleaseLevel"]) {
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
    
    checkURL = [checkURL stringByAppendingFormat:@"?type=%@&current=%@", versionType, thisVersionString];
#ifdef DEBUG
	if (VERBOSE) NSLog(@"Update Check URL: %@", checkURL);
#endif
    return [NSURL URLWithString:checkURL];
}

typedef enum {
    kQSUpdateCheckSkip = -2,
    kQSUpdateCheckError = -1,
    kQSUpdateCheckNoUpdate = 0,
    kQSUpdateCheckUpdateAvailable = 1,
} QSUpdateCheckResult;

- (QSUpdateCheckResult)checkForUpdates:(BOOL)force {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"QSPreventAutomaticUpdate"] || (![defaults boolForKey:kCheckForUpdates] && !force)) {
        NSLog(@"Preventing update check.");
        return kQSUpdateCheckSkip;
    }

    NSString *thisVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
	NSString *checkVersionString = nil;

    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:[self buildUpdateCheckURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
    [theRequest setValue:kQSUserAgent forHTTPHeaderField:@"User-Agent"];

    NSData *data = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:nil error:nil];
    checkVersionString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    [defaults setObject:[NSDate date] forKey:kLastUpdateCheck];
    if (![checkVersionString length] || [checkVersionString length] > 10) {
        NSLog(@"Unable to check for new version.");
        [[QSTaskController sharedInstance] removeTask:@"Check for Update"];
        return kQSUpdateCheckError;
    }

    BOOL newVersionAvailable = [checkVersionString hexIntValue] > [thisVersionString hexIntValue];
    /* We have to get the current available version, because it will get displayed to the user,
     * so force happens only if there's a valid response from the server
     */
    newVersion = checkVersionString;
#ifdef DEBUG
    if (VERBOSE)
        NSLog(@"Installed Version: %@, Available Version: %@, Valid: %@, Force update: %@", thisVersionString, checkVersionString, (newVersionAvailable ? @"YES" : @"NO"), (force ? @"YES" : @"NO"));
#endif
    return newVersionAvailable ? kQSUpdateCheckUpdateAvailable : kQSUpdateCheckNoUpdate;
}

- (BOOL)checkForUpdatesInBackground:(BOOL)quiet force:(BOOL)force {
	[[QSTaskController sharedInstance] updateTask:@"Check for Update" status:@"Check for Update" progress:-1];
    BOOL updated = NO;
    
    NSInteger check = [self checkForUpdates:force];
    [[QSTaskController sharedInstance] removeTask:@"Check for Update"];
    switch (check) {
        case kQSUpdateCheckError:
            if (!quiet) {
                NSUserNotification *connectionAlert = [[NSUserNotification alloc] init];
                [connectionAlert setIdentifier:@"QSConnectionErrorUserNotification"];
                NSString *title = NSLocalizedString(@"Internet Connection Error", nil);
                NSString *details = NSLocalizedString(@"Unable to check for updates. Please verify your connection.", nil);
                [connectionAlert setTitle:title];
                [connectionAlert setInformativeText:details];
                [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:connectionAlert];
            }
            return NO;
        break;
        case kQSUpdateCheckUpdateAvailable:
            if (!force && [[NSUserDefaults standardUserDefaults] boolForKey:@"QSDownloadUpdatesInBackground"]) {
/** Diable automatically checking for updates in the background for DEBUG builds
 You can still check for updates by clicking the "Check Now" button **/
#ifndef DEBUG
                [self performSelectorOnMainThread:@selector(installAppUpdate) withObject:nil waitUntilDone:NO];
#endif
            } else {
                NSUserNotification *updateAlert = [[NSUserNotification alloc] init];
                [updateAlert setIdentifier:QSUpdateAvailableUserNotification];
                NSString *title = NSLocalizedString(@"Update Available", nil);
                NSString *localDetails = NSLocalizedString(@"A new version of Quicksilver is available. Update from %@ → %@?", nil);
                NSString *currentBuild = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
                NSString *details = [NSString stringWithFormat:localDetails, currentBuild, newVersion];
                NSString *button = NSLocalizedString(@"Download", nil);
                [updateAlert setTitle:title];
                [updateAlert setInformativeText:details];
                [updateAlert setActionButtonTitle:button];
                [updateAlert setUserInfo:@{@"updateController": self}];
                [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
                [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:updateAlert];
            }
            return YES;
        break;
        case kQSUpdateCheckNoUpdate:
        {
            QSPluginUpdateStatus updateStatus;
            updateStatus = [[QSPlugInManager sharedInstance] checkForPlugInUpdates];
            if (updateStatus == QSPluginUpdateStatusNoUpdates) {
                updated = NO;
                NSLog(@"Quicksilver is up to date.");
                if (!quiet) {
                    NSUserNotification *upToDateAlert = [[NSUserNotification alloc] init];
                    [upToDateAlert setIdentifier:@"QSUpToDateUserNotification"];
                    NSString *title = NSLocalizedString(@"You're up-to-date!", nil);
                    NSString *details = NSLocalizedString(@"You have the latest version of Quicksilver and installed plugins.", nil);
                    [upToDateAlert setTitle:title];
                    [upToDateAlert setInformativeText:details];
                    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:upToDateAlert];
                }
            }
            return updated;
        break;
        }
        default:
        case kQSUpdateCheckSkip:
        break;
    }

    return NO;
}

- (BOOL)threadedCheckForUpdates:(BOOL)force {
    BOOL res = [self checkForUpdatesInBackground:NO force:force];
    return res;
}

- (BOOL)threadedCheckForUpdatesInBackground:(BOOL)force {
    BOOL res = [self checkForUpdatesInBackground:YES force:force];
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
    QSGCDAsync(^{
        
        // Test to see if the update request is an automatic request (e.g. on launch)
        BOOL quiet = !sender || sender == self || [sender isKindOfClass:[NSTimer class]];
        
        if (quiet) {
            [self threadedCheckForUpdatesInBackground:NO];
        }
        else {
            [self threadedCheckForUpdates:NO];
        }
    });
}

- (IBAction)threadedRequestedCheckForUpdate:(id)sender {
	[self threadedCheckForUpdates:YES];
}

- (void)installAppUpdate {
	if (updateTask) return;

	NSString *fileURL = [[[NSProcessInfo processInfo] environment] objectForKey:@"QSDownloadUpdateURL"];
	if (!fileURL)
        fileURL = kDownloadUpdateURL;

    fileURL = [fileURL stringByAppendingFormat:@"?id=%@&type=dmg&new=yes", [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleIdentifierKey]];

    NSInteger versionType = [[NSUserDefaults standardUserDefaults] integerForKey:@"QSUpdateReleaseLevel"];
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
	appDownload = [[QSURLDownload alloc] initWithRequest:theRequest delegate:(id)self];
	if (appDownload) {
		updateTask = [QSTask taskWithIdentifier:@"QSAppUpdateInstalling"];
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
	NSLog(@"Download Failed: %@", error);
	//	[[QSTaskController sharedInstance] removeTask:@"QSAppUpdateInstalling"];
	[updateTask stopTask:nil];
	updateTask = nil;
	NSRunInformationalAlertPanel(@"Download Failed", @"An error occured while updating: %@", @"OK", nil, nil, [error localizedDescription] );
    [appDownload cancel];
	appDownload = nil;
}

- (void)downloadDidFinish:(QSURLDownload *)download {
    if (download != appDownload)
        return;

	[updateTask setStatus:@"Download Complete"];
	[updateTask setProgress:1.0];

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
		NSLog(@"Plugins don't need update");
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
    appDownload = nil;
	[updateTask stopTask:nil];
	updateTask = nil;
}

- (void)finishAppInstall {
    BOOL update = [[NSUserDefaults standardUserDefaults] boolForKey:@"QSUpdateWithoutAsking"];
    if (!update) {
        NSUserNotification *downloadedAlert = [[NSUserNotification alloc] init];
        [downloadedAlert setIdentifier:QSUpdateDownloadedUserNotification];
        NSString *title = NSLocalizedString(@"Download Successful", nil);
        NSString *details = NSLocalizedString(@"A new version of Quicksilver has been downloaded. Would you like to install it?", nil);
        NSString *button = NSLocalizedString(@"Install", nil);
        [downloadedAlert setTitle:title];
        [downloadedAlert setInformativeText:details];
        [downloadedAlert setActionButtonTitle:button];
        [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:downloadedAlert];
    }

	[updateTask stopTask:nil];
	updateTask = nil;
    appDownload = nil;
}

- (BOOL)installAppFromDiskImage:(NSString *)path {
    NSFileManager *manager = [NSFileManager defaultManager];
    
    // Create a temp directory to mount the .dmg
    NSError *err = nil;
    NSString *tempDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString uniqueString]];
    [manager createDirectoryAtPath:tempDirectory withIntermediateDirectories:YES
                        attributes:nil error:&err];
    if(err) {
        NSLog(@"Error: %@", err);
        return NO;
    }
    
    [updateTask setName:@"Installing Update"];
    [updateTask setStatus:@"Verifying Data"];
    [updateTask setProgress:-1.0];
    
    // mount the .dmg
    NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/hdiutil"
                                            arguments:[NSArray arrayWithObjects:@"attach", path, @"-nobrowse", @"-mountpoint", tempDirectory, nil]];
    
    [task waitUntilExit];
    
    if ([task terminationStatus] != 0)
        return NO;
    
    NSArray *extracted = [[manager contentsOfDirectoryAtPath:tempDirectory error:nil] pathsMatchingExtensions:[NSArray arrayWithObject:@"app"]];
    if ([extracted count] != 1)
        return NO;
    
    NSString *mountedAppPath = [tempDirectory stringByAppendingPathComponent:[extracted lastObject]];
    if (!mountedAppPath) {
        return NO;
    }
    
    // Copy Quicksilver.app from the .dmg to a writeable folder (QS App Support folder)

    // Attempt to delete any old update folders
    if ([manager fileExistsAtPath:pUpdatePath]) {
        [manager removeItemAtPath:pUpdatePath error:&err];
        if (err) {
            // report the error, but attempt to carry on
            NSLog(@"Error: %@",err);
            err = nil;
        }
    }

    [manager createDirectoryAtPath:pUpdatePath withIntermediateDirectories:YES attributes:nil error:&err];
    if (err) {
        NSLog(@"Error: %@",err);
        return NO;
    }
    NSString *storedAppPath = [pUpdatePath stringByAppendingPathComponent:[mountedAppPath lastPathComponent]];
    NSError *copyErr = nil;
    [manager copyItemAtPath:mountedAppPath toPath:storedAppPath error:&copyErr];
    if (copyErr) {
        NSLog(@"Error: %@",copyErr);
        return NO;
    }
    
    
    // Copy the Application over the current app
    [updateTask setStatus:@"Copying Application"];
    BOOL copySuccess = [NSApp moveToPath:[[NSBundle mainBundle] bundlePath] fromPath:storedAppPath];
    [updateTask setStatus:@"Cleaning Up"];
    
    // Unmount .dmg and tidyup
    task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/hdiutil"
                                    arguments:[NSArray arrayWithObjects:@"detach", tempDirectory, nil]];
    [task waitUntilExit];
    [manager removeItemAtPath:tempDirectory error:&err];
    if(err) {
        // Couldn't delete the temp directory. Not the end of the world: report and continue
        NSLog(@"Error: %@",err);
        err = nil;
    }
    [manager removeItemAtPath:pUpdatePath error:&err];
    if(err) {
        // Couldn't delete the update directory. Not the end of the world: report and continue
        NSLog(@"Error: %@",err);
        err = nil;
    }
    
    return copySuccess;
    
}

- (NSArray *)extractFilesFromQSPkg:(NSString *)path toPath:(NSString *)tempDirectory {
	if (!path) return nil;
	NSFileManager *manager = [NSFileManager defaultManager];
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath:@"/usr/bin/ditto"];

	[task setArguments:[NSArray arrayWithObjects:@"-x", @"-rsrc", path, tempDirectory, nil]];
	[task launch];
	[task waitUntilExit];
	NSInteger status = [task terminationStatus];
	if (status == 0) {
		[manager removeItemAtPath:path error:nil];
		[[NSWorkspace sharedWorkspace] noteFileSystemChanged:[path stringByDeletingLastPathComponent]];
		return [manager contentsOfDirectoryAtPath:tempDirectory error:nil];
	} else {
		return nil;
	}

}

#pragma mark NSUserNotificationCenter delegate methods

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    if ([[notification identifier] isEqualToString:QSUpdateAvailableUserNotification]) {
        if (notification.activationType == NSUserNotificationActivationTypeContentsClicked) {
            // open release notes URL if message clicked
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kReleaseNotesURL]];
            return;
        }
        QSGCDMainAsync(^{
            [self installAppUpdate];
        });
        return;
    }
    if ([[notification identifier] isEqualToString:QSUpdateDownloadedUserNotification]) {
        // install
        NSString *path = [appDownload destination];
        BOOL installSuccessful = [self installAppFromDiskImage:path];
        if (installSuccessful) {
            BOOL relaunch = [[NSUserDefaults standardUserDefaults] boolForKey:@"QSUpdateWithoutAsking"];
            if (relaunch) {
                [NSApp relaunchFromPath:nil];
            } else {
                NSUserNotification *installAlert = [[NSUserNotification alloc] init];
                [installAlert setIdentifier:QSUpdateInstalledUserNotification];
                NSString *title = NSLocalizedString(@"Installation Successful", nil);
                NSString *details = NSLocalizedString(@"A new version of Quicksilver has been installed. Relaunch to start using it.", nil);
                NSString *button = NSLocalizedString(@"Relaunch", nil);
                NSString *cancel = NSLocalizedString(@"Later", @"Install update later");
                [installAlert setTitle:title];
                [installAlert setInformativeText:details];
                [installAlert setActionButtonTitle:button];
                [installAlert setOtherButtonTitle:cancel];
                [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
                [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:installAlert];
            }
        } else {
            NSUserNotification *installFailAlert = [[NSUserNotification alloc] init];
            [installFailAlert setIdentifier:@"QSInstallFailedUserNotification"];
            NSString *title = NSLocalizedString(@"Installation Failed", nil);
            NSString *details = NSLocalizedString(@"It was not possible to decompress downloaded file.", nil);
            [installFailAlert setTitle:title];
            [installFailAlert setInformativeText:details];
            [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:installFailAlert];
        }
        return;
    }
    if ([[notification identifier] isEqualToString:QSUpdateInstalledUserNotification]) {
        [NSApp relaunchFromPath:nil];
        return;
    }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    // there's no in-app equivalent for these notifications, so always show them
    return YES;
}
    
@end

