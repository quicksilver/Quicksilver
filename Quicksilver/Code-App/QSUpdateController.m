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

/*
 * As there's a bunch of settings that control updating, and you can't quickly
 * tell them apart, here's a cheatsheet :
 *
 * - [defaults boolForKey:@"QSPreventAutomaticUpdate"]
 *   "Paranoid" mode - Quicksilver will only update itself when the user explicitely asks for it.
 *   It's a hidden pref setting, so developers can use this to stop those pesky update dialogs.
 *
 * - [defaults boolForKey:kCheckForUpdates]
 *   The user-accessible preference setting.
 *
 * - [defaults boolForKey:@"QSDownloadUpdatesInBackground"]
 *   QS won't ask before downloading an update.
 *
 * - [defaults boolForKey:@"QSUpdateWithoutAsking"]
 *   QS will install the update silently and relaunch automatically.
 *
 */

@interface QSUpdateController () {
	NSTimer *updateTimer;
	NSString *availableVersion;
	NSString *tempPath;
}
@property (retain) QSURLDownload *appDownload;
@property (retain) QSTask *downloadTask;
@end

@implementation QSUpdateController

+ (instancetype)sharedInstance {
	static id _sharedInstance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedInstance = [[[self class] alloc] init];
	});
	return _sharedInstance;
}

- (instancetype)init {
	self = [super init];
	if (!self) return nil;

	if ([NSApp checkLaunchStatus] == QSApplicationUpgradedLaunch) {
		NSLog(@"Updated: Forcing Check");
		[self checkForUpdates:YES];
	}

	[self setUpdateTimer];

	return self;
}

- (void)setUpdateTimer {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

#ifdef DEBUG
	if ([defaults boolForKey:@"QSPreventAutomaticUpdate"]) return;
#else
	if (![defaults boolForKey:kCheckForUpdates]) return;
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
	NSDate *nextCheck = [[NSDate alloc] initWithTimeInterval:checkInterval sinceDate:lastCheck];
	if (updateTimer) {
		[updateTimer invalidate];
	}
	updateTimer = [NSTimer scheduledTimerWithTimeInterval:checkInterval target:self selector:@selector(scheduledCheckForUpdate:) userInfo:nil repeats:shouldRepeat];
	[updateTimer setFireDate:nextCheck];
#ifdef DEBUG
	if (VERBOSE) NSLog(@"Next Version Check at : %@", [[updateTimer fireDate] description]);
#endif
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
	kQSUpdateCheckError = -1,
	kQSUpdateCheckNoUpdate = 0,
	kQSUpdateCheckUpdateAvailable = 1,
} QSUpdateCheckResult;

- (QSUpdateCheckResult)checkForUpdateStatus:(BOOL)userInitiated {
	NSString *thisVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
	NSString *checkVersionString = nil;

	QSTask *task = [QSTask taskWithIdentifier:@"QSUpdateControllerTask"];
	task.status = NSLocalizedString(@"Checking for Updates", @"QSUpdateController - task status");
	task.progress = -1;
	[task start];

	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:[self buildUpdateCheckURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
	[theRequest setValue:kQSUserAgent forHTTPHeaderField:@"User-Agent"];

	NSData *data = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:nil error:nil];
	[task stop];

	checkVersionString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastUpdateCheck];
	if (![checkVersionString length] || [checkVersionString length] > 10) {
		NSString *preview = [checkVersionString substringToIndex:([checkVersionString length] < 10 ? [checkVersionString length] : 9)];
		NSLog(@"Strange reply from update server: %@", preview);
		return kQSUpdateCheckError;
	}

	BOOL newVersionAvailable = [checkVersionString hexIntValue] > [thisVersionString hexIntValue];
	/* We have to get the current available version, because it will get displayed to the user,
	 * so force happens only if there's a valid response from the server
	 */
	availableVersion = checkVersionString;
#ifdef DEBUG
	if (VERBOSE)
		NSLog(@"Installed Version: %@, Available Version: %@, Valid: %@, User-initiated: %@", thisVersionString, checkVersionString, (newVersionAvailable ? @"YES" : @"NO"), (userInitiated ? @"YES" : @"NO"));
#endif
	return newVersionAvailable ? kQSUpdateCheckUpdateAvailable : kQSUpdateCheckNoUpdate;
}

- (void)checkForUpdates:(BOOL)userInitiated {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	/* This is an automated check and updates are blocked or not enabled */
	if ([defaults boolForKey:@"QSPreventAutomaticUpdate"] || ([defaults boolForKey:kCheckForUpdates] && !userInitiated)) {
		NSLog(@"Preventing update check.");
		return;
	}

	QSGCDQueueAsync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		NSInteger check = [self checkForUpdateStatus:userInitiated];
		if (check == kQSUpdateCheckError) {
			if (userInitiated) {
				NSAlert *alert = [[NSAlert alloc] init];

				alert.alertStyle = NSInformationalAlertStyle;
				alert.messageText = NSLocalizedString(@"Internet Connection Error", @"QSUpdateController - update check error title"),
				alert.informativeText = NSLocalizedString(@"Unable to check for updates, the server could not be reached. Please check your internet connection.", @"QSUpdateController - update check error message");
				[alert addButtonWithTitle:NSLocalizedString(@"OK", @"QSUpdateController - update check default button")];

				[[QSAlertManager defaultManager] beginAlert:alert onWindow:nil completionHandler:nil];
			}
			return;
		}

		if (check == kQSUpdateCheckUpdateAvailable) {
			__block BOOL shouldInstallApp = NO;

#ifdef DEBUG
			/* Disable automatically checking for updates in the background for DEBUG builds
			 * You can still check for updates by clicking the "Check Now" button */
			if (!userInitiated) {
				NSLog(@"Update available (%@) but disabled in DEBUG", availableVersion);
				return;
			}
#endif

			/* We should ask the user if we're user-initiated or automatic downloads are not enabled. */
			if (userInitiated || ![[NSUserDefaults standardUserDefaults] boolForKey:@"QSDownloadUpdatesInBackground"]) {
				NSAlert *alert = [[NSAlert alloc] init];
				alert.alertStyle = NSInformationalAlertStyle;
				alert.messageText = NSLocalizedString(@"New Version of Quicksilver Available", @"QSUpdateController - update available alert title");
				alert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"A new version of Quicksilver is available, would you like to update now?\n\n(Update from %@ → %@)", @"QSUpdateController - update available alert message"), [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey], availableVersion];
				[alert addButtonWithTitle:NSLocalizedString(@"Install Update", @"QSUpdateController - update available alert default button")];
				[alert addButtonWithTitle:NSLocalizedString(@"Later", @"QSUpdateController - update available alert cancel button")];
				[alert addButtonWithTitle:NSLocalizedString(@"More Info", @"QSUpdateController - update available alert other button")];

				[[QSAlertManager defaultManager] beginAlert:alert onWindow:nullEvent completionHandler:^(QSAlertResponse response) {
					if (response == QSAlertResponseOK)
						shouldInstallApp = YES;
					else if (response == QSAlertResponseCancel)
						shouldInstallApp = NO;
					else if (response == QSAlertResponseThird)
						QSGCDMainAsync(^{
							[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kWebSiteURL]];
						});
				}];
			}

			if (shouldInstallApp)
				[self installAppUpdate];
			return;
		}

		if (check == kQSUpdateCheckNoUpdate) {
			QSPluginUpdateStatus updateStatus = [[QSPlugInManager sharedInstance] checkForPlugInUpdates];
			if (updateStatus == QSPluginUpdateStatusNoUpdates) {
				NSLog(@"Quicksilver is up to date");

				if (!userInitiated) return;

				NSAlert *alert = [[NSAlert alloc] init];

				alert.alertStyle = NSInformationalAlertStyle;
				alert.messageText = NSLocalizedString(@"You're up-to-date!", @"QSUpdateController - no update alert title"),
				alert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"You already have the latest version of Quicksilver (%@) and all installed plugins", @"no update alert message"), [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]];
				[alert addButtonWithTitle:NSLocalizedString(@"OK", @"no update alert default button")];

				[[QSAlertManager defaultManager] beginAlert:alert onWindow:nil completionHandler:nil];
			}
			return;
		}
	});
}

- (void)handleURL:(NSURL *)url {
	[self checkForUpdates:YES];
}

- (void)scheduledCheckForUpdate:(NSTimer *)timer {
	[self checkForUpdates:NO];
}

- (void)installAppUpdate {
	if (self.downloadTask) return;

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
	self.appDownload = [[QSURLDownload alloc] initWithRequest:theRequest delegate:(id)self];
	if (self.appDownload) {
		self.downloadTask = [QSTask taskWithIdentifier:@"QSAppUpdateInstalling"];
		self.downloadTask.name = NSLocalizedString(@"Updating Quicksilver", @"QSUpdateController - download task name");
		self.downloadTask.status = NSLocalizedString(@"Downloading Update…", @"QSUpdateController - download task status");
		self.downloadTask.progress = -1;

		__weak QSUpdateController *weakSelf = self;
		self.downloadTask.cancelBlock = ^{
			__strong QSUpdateController *strongSelf = weakSelf;
			[strongSelf.appDownload cancel];
			strongSelf.appDownload = nil;
		};

		[[QSTaskViewer sharedInstance] showWindow:self];;
		[self.downloadTask start];
		[self.appDownload start];
	}
}

- (void)download:(QSURLDownload *)download didFailWithError:(NSError *)error {
	if (download != self.appDownload)
		return;
	NSLog(@"Download Failed: %@", error);
	[self.downloadTask stop];
	self.downloadTask = nil;
	QSGCDMainAsync(^{
		NSRunInformationalAlertPanel(NSLocalizedString(@"Download Failed", @""), NSLocalizedString(@"An error occured while updating: %@", @""), NSLocalizedString(@"OK", @""), nil, nil, [error localizedDescription]);
	});
	[self.appDownload cancel];
	self.appDownload = nil;
}

- (void)downloadDidFinish:(QSURLDownload *)download {
    if (download != self.appDownload)
        return;

	self.downloadTask.status = NSLocalizedString(@"Download Complete", @"QSUpdateController - download task status");
	self.downloadTask.progress = 1.0;

	BOOL plugInUpdates = [[QSPlugInManager sharedInstance] updatePlugInsForNewVersion:availableVersion];

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
		NSLog(@"Plugins don't need updates");
		[self finishAppInstall];
	}
}

- (void)downloadDidUpdate:(QSURLDownload *)download {
	NSString *status = [NSString stringWithFormat:@"%.0fk of %.0fk", (double) [download currentContentLength] /1024, (double)[download expectedContentLength] /1024];
	self.downloadTask.status = status;
	self.downloadTask.progress = [(QSURLDownload *)download progress];
}

- (void)finishAppInstall {
	NSString *path = [self.appDownload destination];


	BOOL shouldUpdate = YES;
	BOOL updateWithoutAsking = [[NSUserDefaults standardUserDefaults] boolForKey:@"QSUpdateWithoutAsking"];
	if (!updateWithoutAsking) {
		NSAlert *alert = [[NSAlert alloc] init];
		alert.messageText = NSLocalizedString(@"Download Successful", @"QSUpdateController - update downloaded alert title");
		alert.informativeText = NSLocalizedString(@"A new version of Quicksilver has been downloaded. Quicksilver must relaunch to install it.", @"QSUpdateController - update downloaded alert message");
		alert.alertStyle = NSAlertStyleInformational;

		[alert addButtonWithTitle:NSLocalizedString(@"Install and Relaunch", @"QSUpdateController - update downloaded alert - default button")];
		[alert addButtonWithTitle:NSLocalizedString(@"Cancel Update", @"QSUpdateController - update downloaded alert - cancel button")];

		QSAlertResponse response = [[QSAlertManager defaultManager] runAlert:alert onWindow:nil];

		shouldUpdate = (response == QSAlertResponseOK);
	}

	if (shouldUpdate && ![self installAppFromDiskImage:path]) {
		NSAlert *alert = [[NSAlert alloc] init];
		alert.messageText = NSLocalizedString(@"Installation Failed", @"QSUpdateController - installation failed alert title");
		alert.informativeText = NSLocalizedString(@"It was not possible to decompress the downloaded file.", @"QSUpdateController - installation failed alert message");
		alert.alertStyle = NSAlertStyleWarning;

		[alert addButtonWithTitle:NSLocalizedString(@"Cancel Update", @"QSUpdateController - installation failed alert - default button")];
		[alert addButtonWithTitle:NSLocalizedString(@"Download manually", @"QSUpdateController - installation failed alert - cancel button")];

		QSAlertResponse response = [[QSAlertManager defaultManager] runAlert:alert onWindow:nil];

		if (response == QSAlertResponseSecond)
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kWebSiteURL]];

		return;
	}

	BOOL relaunch = NO;
	if (updateWithoutAsking) {
		NSAlert *alert = [[NSAlert alloc] init];
		alert.messageText = NSLocalizedString(@"Installation Successful", @"QSUpdateController - relauch required alert title");
		alert.informativeText = NSLocalizedString(@"A new version of Quicksilver has been installed. Quicksilver must relaunch to install it.", @"QSUpdateController - relauch required alert message");
		alert.alertStyle = NSAlertStyleInformational;

		[alert addButtonWithTitle:NSLocalizedString(@"Relaunch", @"QSUpdateController - relauch required alert - default button")];
		[alert addButtonWithTitle:NSLocalizedString(@"Relaunch Later", @"QSUpdateController - relauch required alert - cancel button")];

		QSAlertResponse response = [[QSAlertManager defaultManager] runAlert:alert onWindow:nil];

		relaunch = (response == QSAlertResponseOK);
	}
	if (relaunch) {
		[NSApp relaunchFromPath:nil];
	}

	[self.downloadTask stop];
	self.downloadTask = nil;
	self.appDownload = nil;
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

	self.downloadTask.status = NSLocalizedString(@"Verifying Data", @"QSUpdateController - download task status");
	self.downloadTask.progress = -1;

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
	self.downloadTask.status = NSLocalizedString(@"Copying Application", @"QSUpdateController - download task status");
	BOOL copySuccess = [NSApp moveToPath:[[NSBundle mainBundle] bundlePath] fromPath:storedAppPath];
	self.downloadTask.status = NSLocalizedString(@"Cleaning Up", QSUpdateController - download task status);

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

@end

