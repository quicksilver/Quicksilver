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


typedef enum {
	kQSUpdateCheckError = -1,
	kQSUpdateCheckNoUpdate = 0,
	kQSUpdateCheckUpdateAvailable = 1,
} QSUpdateCheckResult;


@interface QSUpdateController () <QSURLDownloadDelegate> {
	NSTimer *updateTimer;
	NSString *availableVersion;
	NSString *availableVersionDisplay;
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
	_isCheckingForUpdates = NO;
	if ([NSApp checkLaunchStatus] == QSApplicationUpgradedLaunch) {
		NSLog(@"Updated: Forcing Check");
		[self checkForUpdates:NO];
	}

	[self setUpdateTimer];

	return self;
}

- (void)setUpdateTimer {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];


	if (![defaults boolForKey:kCheckForUpdates]) return;

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

- (NSString *)currentVersionString {
	return [NSString stringWithFormat:NSLocalizedString(@"%@, build %@", @"no update version number string"), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]];
}

- (NSString *)newVersionString {
	return [NSString stringWithFormat:NSLocalizedString(@"%@, build %@", @"no update version number string"), self->availableVersionDisplay, self->availableVersion];
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

	checkURL = [checkURL stringByAppendingFormat:@"?type=%@&current=%@&json=1", versionType, thisVersionString];
#ifdef DEBUG
	if (VERBOSE) NSLog(@"Update Check URL: %@", checkURL);
#endif
	return [NSURL URLWithString:checkURL];
}

- (void)checkForUpdateStatus:(BOOL)userInitiated completionHandler:(void (^)(QSUpdateCheckResult result))block {
	
	NSString *thisVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
	QSTask *task = [QSTask taskWithIdentifier:@"QSUpdateControllerTask"];
	task.name = NSLocalizedString(@"Updating Quicksilver", @"QSUpdateController - download task name");
	task.status = NSLocalizedString(@"Checking for Updates…", @"QSUpdateController - task status");
	task.progress = -1;
	task.icon = [QSResourceManager imageNamed:@"Quicksilver"];
	[task start];

	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:[self buildUpdateCheckURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
	[theRequest setValue:kQSUserAgent forHTTPHeaderField:@"User-Agent"];
	NSURLSession *session = [NSURLSession sharedSession];
	NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:theRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		QSGCDMainAsync(^{
			[task stop];

			// convert the response data from json to a dict.
			if (error || !data) {
				NSLog(@"Error: %@", error);
				block(kQSUpdateCheckError);
				return;
			}
			NSError *jsonError = nil;
			// format, see https://github.com/quicksilver/QSApp.com/blob/main/qs0/plugins/check.php#L70
			// latestDisplay -> displayVersion (STRING)
			// latest -> latestVersion (HEX)
			// current -> currentVersion (HEX)
			NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
			if (jsonError) {
				NSLog(@"JSON Error: %@", jsonError);
				block(kQSUpdateCheckError);
				return;
			}
			NSString *checkVersionString = json[@"latest"];
			[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastUpdateCheck];
			if (![checkVersionString length] || [checkVersionString length] > 10) {
				NSString *preview = [checkVersionString substringToIndex:([checkVersionString length] < 10 ? [checkVersionString length] : 9)];
				NSLog(@"Strange reply from update server: %@", preview);
				block(kQSUpdateCheckError);
				return;
			}
			
			BOOL newVersionAvailable = [checkVersionString hexIntValue] > [thisVersionString hexIntValue];
			/* We have to get the current available version, because it will get displayed to the user,
			 * so force happens only if there's a valid response from the server
			 */
			self->availableVersion = checkVersionString;
			self->availableVersionDisplay = json[@"latestDisplay"];
#ifdef DEBUG
			if (VERBOSE)
				NSLog(@"Installed Version: %@, Available Version: %@, Valid: %@, User-initiated: %@", thisVersionString, checkVersionString, (newVersionAvailable ? @"YES" : @"NO"), (userInitiated ? @"YES" : @"NO"));
#endif
			block(newVersionAvailable ? kQSUpdateCheckUpdateAvailable : kQSUpdateCheckNoUpdate);
			return;
		});
	}];
	[dataTask resume];
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
	if ([key isEqualToString:@"isCheckingForUpdates"]) {
		// we udpate isCheckingForUpdates manually, so we can do it on the main thread
		return NO;
	}
	return YES;
}

- (void)setIsCheckingForUpdates:(BOOL)val {
	QSGCDMainAsync(^{
		[self willChangeValueForKey:@"isCheckingForUpdates"];
		self->_isCheckingForUpdates = val;
		[self didChangeValueForKey:@"isCheckingForUpdates"];
	});
}
- (void)checkForUpdates:(BOOL)userInitiated {
	[self setIsCheckingForUpdates:YES];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	/* This is an automated check and updates are blocked or not enabled */
	if ([defaults boolForKey:@"QSPreventAutomaticUpdate"] && !userInitiated) {
		NSLog(@"Preventing update check.");
		[self setIsCheckingForUpdates:NO];
		return;
	}
	
	[self checkForUpdateStatus:userInitiated completionHandler:^(QSUpdateCheckResult check) {
		if (check == kQSUpdateCheckError) {
			if (userInitiated) {
				QSGCDMainAsync(^{
					NSAlert *alert = [[NSAlert alloc] init];
					
					alert.alertStyle = NSAlertStyleInformational;
					alert.messageText = NSLocalizedString(@"Internet Connection Error", @"QSUpdateController - update check error title");
					alert.informativeText = NSLocalizedString(@"Unable to check for updates, the server could not be reached. Please check your internet connection.", @"QSUpdateController - update check error message");
					[alert addButtonWithTitle:NSLocalizedString(@"OK", @"QSUpdateController - update check default button")];
					
					[alert runModal];
				});
			}
			[self setIsCheckingForUpdates:NO];
			return;
		}
		
		if (check == kQSUpdateCheckUpdateAvailable) {
			
			
#ifdef DEBUG
			/* Disable automatically checking for updates in the background for DEBUG builds
			 * You can still check for updates by clicking the "Check Now" button */
			if (!userInitiated) {
				NSLog(@"Update available (%@ build %@) but disabled in DEBUG", [self currentVersionString], [self newVersionString]);
				[self setIsCheckingForUpdates:NO];
				return;
			}
#endif
			
			/* We should ask the user if we're user-initiated or automatic downloads are not enabled. */
			if (userInitiated || ![[NSUserDefaults standardUserDefaults] boolForKey:@"QSDownloadUpdatesInBackground"]) {
				QSGCDMainAsync(^{
					NSAlert *alert = [[NSAlert alloc] init];
					alert.alertStyle = NSAlertStyleInformational;
					alert.messageText = NSLocalizedString(@"New Version of Quicksilver Available", @"QSUpdateController - update available alert title");
					alert.informativeText = [NSString stringWithFormat:
																	 @"%@\n\n%@",
																	 NSLocalizedString(@"A new version of Quicksilver is available, would you like to update now?", @"QSUpdateController - update available alert message"),
																	 [NSString stringWithFormat:NSLocalizedString(@"(Update from %@ → %@)", @"Update string from version to version"), [self currentVersionString], [self newVersionString]]];
					[alert addButtonWithTitle:NSLocalizedString(@"Install Update", @"QSUpdateController - update available alert default button")];
					[alert addButtonWithTitle:NSLocalizedString(@"Later", @"QSUpdateController - update available alert cancel button")];
					[alert addButtonWithTitle:NSLocalizedString(@"More Info", @"QSUpdateController - update available alert other button")];
					
					QSAlertResponse response = [alert runAlert];
					if (response == QSAlertResponseOK)
						[self installAppUpdate];
					else if (response == QSAlertResponseThird)
						QSGCDMainAsync(^{
							[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kChangelogURL]];
						});
				});
			} else {
				//
				[self installAppUpdate];
			}
			[self setIsCheckingForUpdates:NO];
			return;
		}
		
		if (check == kQSUpdateCheckNoUpdate) {
			[[QSPlugInManager sharedInstance] checkForPlugInUpdates:^(QSPluginUpdateStatus updateStatus) {
				if (updateStatus == QSPluginUpdateStatusNoUpdates) {
					NSLog(@"Quicksilver is up to date");
					
					if (userInitiated) {
						QSGCDMainAsync(^{
							NSAlert *alert = [[NSAlert alloc] init];
							
							NSString *versionNumber = [NSString stringWithFormat:NSLocalizedString(@"%@, build %@", @"no update version number string"), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]];
							alert.alertStyle = NSAlertStyleInformational;
							alert.messageText = NSLocalizedString(@"You're up-to-date!", @"QSUpdateController - no update alert title");
							alert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"You already have the latest version of Quicksilver (%@) and all installed plugins", @"no update alert message"), versionNumber];
							[alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
							
							[alert runModal];
						});
					}
				}
				[self setIsCheckingForUpdates:NO];
			}];
		}
	}];
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
	self.appDownload = [QSURLDownload downloadWithURL:url delegate:self];
	
	if (self.appDownload) {
		QSGCDMainSync(^{
			self.downloadTask = [QSTask taskWithIdentifier:@"QSAppUpdateInstalling"];
			self.downloadTask.name = NSLocalizedString(@"Updating Quicksilver", @"QSUpdateController - download task name");
			self.downloadTask.status = NSLocalizedString(@"Downloading Update…", @"QSUpdateController - download task status");
			self.downloadTask.progress = 0;
			self.downloadTask.icon = [NSApp applicationIconImage];
			
			__weak QSUpdateController *weakSelf = self;
			self.downloadTask.cancelBlock = ^{
				__strong QSUpdateController *strongSelf = weakSelf;
				[strongSelf.appDownload cancel];
				strongSelf.appDownload = nil;
				strongSelf.downloadTask.status = NSLocalizedString(@"Cancelled", @"QSUpdateController - cancelled task status");
				[strongSelf.downloadTask stop];
				strongSelf.downloadTask = nil;
			};
			
			[[QSTaskViewer sharedInstance] showWindow:self];;
			[self.downloadTask start];
		});
		[self.appDownload start];
	}
}

- (void)download:(QSURLDownload *)download didFailWithError:(NSError *)error {
	if (download != self.appDownload)
		return;

	NSLog(@"Download Failed: %@", error);
	[self.downloadTask stop];
	self.downloadTask = nil;
	QSGCDMainSync(^{
		NSAlert *alert = [[NSAlert alloc] init];
		alert.messageText = NSLocalizedString(@"Download Failed", @"QSUpdateController - download failed alert title");
		alert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"An error occured while downloading the update: %@", @"QSUpdateController - download failed alert message"), error.localizedDescription];
		alert.alertStyle = NSAlertStyleInformational;
		
		[alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
		
		[alert runModal];
	});
	
	[self.appDownload cancel];
	self.appDownload = nil;
}

- (void)downloadDidFinish:(QSURLDownload *)download {
    if (download != self.appDownload)
        return;

	self.downloadTask.status = NSLocalizedString(@"Download Complete", @"QSUpdateController - download task status");
	self.downloadTask.progress = 1.0;

	[[QSPlugInManager sharedInstance] updatePlugInsForNewVersion:availableVersion completionHandler:^(QSPluginUpdateStatus status) {
		[self finishAppInstall];
	}];
}

- (void)downloadDidUpdate:(QSURLDownload *)download {
	NSString *status = [NSString stringWithFormat:@"%.2fMB of %.2fMB", (double) [download currentContentLength] /1024/1024, (double)[download expectedContentLength]/1024/1024];
	self.downloadTask.status = status;
	self.downloadTask.progress = [(QSURLDownload *)download progress];
}

- (void)finishAppInstall {
	NSString *path = [self.appDownload destination];

	BOOL __block shouldUpdate = YES;
	BOOL updateWithoutAsking = [[NSUserDefaults standardUserDefaults] boolForKey:@"QSUpdateWithoutAsking"];
	if (!updateWithoutAsking) {
		QSGCDMainSync(^{
			NSAlert *alert = [[NSAlert alloc] init];
			alert.alertStyle = NSAlertStyleInformational;
			alert.messageText = NSLocalizedString(@"Download Successful", @"QSUpdateController - update downloaded alert title");
				alert.informativeText = [NSString stringWithFormat:@"%@\n\n%@",
																 NSLocalizedString(@"A new version of Quicksilver has been dowloaded, would you like to install and relaunch now?", @"QSUpdateController - update available install and relaunch message"),
																 [NSString stringWithFormat:NSLocalizedString(@"(Update from %@ → %@)", @"Update string from version to version"), [self currentVersionString], [self newVersionString]]];
			[alert addButtonWithTitle:NSLocalizedString(@"Install and Relaunch", @"QSUpdateController - update available alert default button")];
			[alert addButtonWithTitle:NSLocalizedString(@"Cancel Update", @"QSUpdateController - cancel update button")];
			[alert addButtonWithTitle:NSLocalizedString(@"More Info", @"QSUpdateController - update available alert other button")];
			NSModalResponse response = [alert runModal];
			
			switch (response) {
				case NSAlertFirstButtonReturn:
					shouldUpdate = YES;
					break;
				case NSAlertSecondButtonReturn:
					shouldUpdate = NO;
					break;
				default:
					// third button
					shouldUpdate = NO;
					[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kChangelogURL]];
			}
		});
	}

	if (shouldUpdate && ![self installAppFromDiskImage:path]) {
		QSGCDMainSync(^{
			NSAlert *alert = [[NSAlert alloc] init];
			alert.messageText = NSLocalizedString(@"Installation Failed", @"QSUpdateController - installation failed alert title");
			alert.informativeText = NSLocalizedString(@"It was not possible to decompress the downloaded file.", @"QSUpdateController - installation failed alert message");
			alert.alertStyle = NSAlertStyleWarning;
			
			[alert addButtonWithTitle:NSLocalizedString(@"Cancel Update", @"QSUpdateController - cancel update button")];
			[alert addButtonWithTitle:NSLocalizedString(@"Download manually", @"QSUpdateController - installation failed alert - cancel button")];
			
			QSAlertResponse response = [alert runAlert];
			
			if (response == QSAlertResponseSecond)
				[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kWebSiteURL]];
		});
		
		return;
	}

	BOOL __block relaunch = updateWithoutAsking;
	if (shouldUpdate && !updateWithoutAsking) {
		QSGCDMainSync(^{
			NSAlert *alert = [[NSAlert alloc] init];
			alert.messageText = NSLocalizedString(@"Installation Successful", @"QSUpdateController - relauch required alert title");
			alert.informativeText = NSLocalizedString(@"A new version of Quicksilver has been installed. Quicksilver must relaunch to install it.", @"QSUpdateController - relauch required alert message");
			alert.alertStyle = NSAlertStyleInformational;
			
			[alert addButtonWithTitle:NSLocalizedString(@"Relaunch", @"QSUpdateController - relauch required alert - default button")];
			[alert addButtonWithTitle:NSLocalizedString(@"Relaunch Later", @"QSUpdateController - relauch required alert - cancel button")];
			
			NSModalResponse response = [alert runModal];
			relaunch = (response == NSAlertFirstButtonReturn);

		});
	}
	if (relaunch) {
		QSGCDMainAsync(^{
			[NSApp relaunchFromPath:nil];
		});
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
	NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/ditto" arguments:@[@"-x", @"-rsrc", path, tempDirectory]];
	[task waitUntilExit];

	NSInteger status = [task terminationStatus];
	if (status == 0) {
		[manager removeItemAtPath:path error:nil];
		QSGCDMainAsync(^{
			[[NSWorkspace sharedWorkspace] noteFileSystemChanged:[path stringByDeletingLastPathComponent]];
		});
		return [manager contentsOfDirectoryAtPath:tempDirectory error:nil];
	} else {
		return nil;
	}
}

@end

