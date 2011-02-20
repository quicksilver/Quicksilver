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
		if ((versionType>0 || PRERELEASEVERSION) && frequency>1)
			frequency = 1;
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
		if (VERBOSE) NSLog(@"Next Version Check at : %@", [[updateTimer fireDate] description]);
        [nextCheck release];
	}
}

- (void)handleURL:(NSURL *)url {
	NSLog(@"url %@", url);
	[self threadedRequestedCheckForUpdate:nil];
}

- (IBAction)threadedCheckForUpdate:(id)sender {
	[NSThread detachNewThreadSelector:@selector(checkForUpdate:) toTarget:self withObject:nil];
}

- (IBAction)threadedRequestedCheckForUpdate:(id)sender {
	[NSThread detachNewThreadSelector:@selector(checkForUpdate:) toTarget:self withObject:mOptionKeyIsDown?@"Force":@"Requested"];
}

#if 0
- (BOOL)networkIsReachable {
	BOOL success = NO;
	SCNetworkConnectionFlags reachabilityStatus;
	success = SCNetworkCheckReachabilityByName("www.apple.com", &reachabilityStatus);
	success = (success && (reachabilityStatus & 3) );
	if (VERBOSE) NSLog(@"Blacktree reachable: %d", reachabilityStatus);
	return success;
}
#endif

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
    if (PRERELEASEVERSION)
        versionType = @"pre";
    
    checkURL = [checkURL stringByAppendingFormat:@"?type=%@&current=%@", versionType, thisVersionString];
    
	if (VERBOSE) NSLog(@"Update Check URL: %@", checkURL);
    return [NSURL URLWithString:checkURL];
}

- (IBAction)checkForUpdate:(id)sender {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[[QSTaskController sharedInstance] updateTask:@"Check for Update" status:@"Check for Update" progress:-1];

	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

	BOOL quiet = !sender || sender == self || [sender isKindOfClass:[NSTimer class]];
	BOOL success = YES;
/*	BOOL success = [self networkIsReachable];
	if (!success) {
		NSLog(@"Blacktree unreacheable");
		[[QSTaskController sharedInstance] removeTask:@"Check for Update"];
		if (quiet) {
			return;
		} else {
			int result = NSRunInformationalAlertPanel(@"Connection Error", @"Your internet connection does not appear to be active.", @"Cancel", @"Check Anyway", nil);
			if (result == NSAlertDefaultReturn) return;
		}
	}
*/
	NSString *thisVersionString = (NSString *)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey);

	//NSLog(@"%@", sender);
	//[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
	BOOL forceUpdate = [sender isEqual:@"Force"];
	if (forceUpdate) NSLog(@"Forcing Update");
    
	BOOL newVersionAvailable = NO;
    
	NSURL *versionURL = [self buildUpdateCheckURL];
    
	NSString *testVersionString = nil;
	if (success) {
		NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:versionURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];

		NSData *data = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:nil error:nil];
		testVersionString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		NSLog(@"Version: %@", testVersionString);
	}

	[defaults setObject:[NSDate date] forKey:kLastUpdateCheck];
	if ([testVersionString length] && [testVersionString length] <10) {
		if (VERBOSE) NSLog(@"Current Version:%d Installed Version:%d", [testVersionString hexIntValue], [thisVersionString hexIntValue]);
		newVersionAvailable = [testVersionString hexIntValue] > [thisVersionString hexIntValue];
		if (newVersionAvailable)
			newVersion = [testVersionString retain];
	} else {
		NSLog(@"Unable to check for new version.");
		[[QSTaskController sharedInstance] removeTask:@"Check for Update"];
		if (!quiet)
			NSRunInformationalAlertPanel(@"Connection Error", @"Unable to check for updates.", @"OK", nil, nil);
		[pool release];
		return;
	}

	if (forceUpdate)
		newVersionAvailable = YES;

	if (newVersionAvailable) {
		//[NSApp activateIgnoringOtherApps:YES];
		if (defaultBool(@"QSDownloadUpdatesInBackground") ) {
			[self performSelectorOnMainThread:@selector(installAppUpdate) withObject:nil waitUntilDone:NO];
		} else {
			int selection = NSRunInformationalAlertPanel([NSString stringWithFormat:@"New Version", nil], @"A new version of Quicksilver is available; would you like to download it now? (%@) ", @"Get New Version", @"Cancel", nil, newVersion); //, @"More Info");
			if (selection == 1) {
				[self performSelectorOnMainThread:@selector(installAppUpdate) withObject:nil waitUntilDone:NO];
			} else if (selection == -1) {  //Go to web site
				[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kDownloadUpdateURL]];
			}
		}
	} else {
		BOOL updated = [[QSPlugInManager sharedInstance] checkForPlugInUpdates];
		if (!updated) {
			NSLog(@"Quicksilver is up to date.");
			// NSLog(@"sender: %@", sender);
			if (!quiet) NSRunInformationalAlertPanel(@"No Updates Available", [NSString stringWithFormat:@"You already have the latest version of Quicksilver (v%@) and all installed plug-ins", thisVersionString] , @"OK", nil, nil);
		}
	}
	[[QSTaskController sharedInstance] removeTask:@"Check for Update"];
	//  [self setUpdateTimer];
	[pool release];
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
    else if (versionType == 1 || PRERELEASEVERSION)
        fileURL = [fileURL stringByAppendingString:@"&pre=1"];

	if (VERBOSE) NSLog(@"Downloading update from %@", fileURL);

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

		//			[[QSTaskController sharedInstance] updateTask:@"QSAppUpdateInstalling" status:@"Downloading Update" progress:-1];
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

	//[self installAppFromCompressedFile:path];
	[updateTask setStatus:@"Download Complete"];
	[updateTask setProgress:1.0];
	//	[[QSTaskController sharedInstance] updateTask:@"QSAppUpdateInstalling" status:@"Download Complete" progress:-1];
	[self installAppFromDiskImage:path];
	[updateTask stopTask:nil];
	[updateTask release], updateTask = nil;

}
- (NSArray *)installAppFromCompressedFile:(NSString *)path {
	int selection = defaultBool(@"QSUpdateWithoutAsking");
	if (!selection)
		selection = NSRunInformationalAlertPanel(@"Download Successful", @"A new version of Quicksilver has been downloaded. This version must be relaunched after it is installed.", @"Install and Relaunch", @"Cancel Update", nil);
	if (selection == 1) {
		NSFileManager *manager = [NSFileManager defaultManager];

		NSString *tempDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"QSUpdate"];
		[manager createDirectoryAtPath:tempDirectory withIntermediateDirectories:NO attributes:nil error:nil];
		[updateTask setProgress:-1.0];

		NSArray *extracted = [self extractFilesFromQSPkg:path toPath:tempDirectory];
		if ([extracted count] != 1) {
			NSLog(@"App Update Error");
			return nil;
		}

		NSString *newAppVersionPath = [tempDirectory stringByAppendingPathComponent:[extracted lastObject]];
		if (newAppVersionPath)
			[NSApp relaunchAfterMovingFromPath:newAppVersionPath];
	} 	else {

		[updateTask stopTask:nil];
		[updateTask release];
		updateTask = nil;

	}
	return nil;
}
- (NSArray *)installAppFromDiskImage:(NSString *)path {
	int selection = defaultBool(@"QSUpdateWithoutAsking");
	if (!selection)
		selection = NSRunInformationalAlertPanel(@"Download Successful", @"A new version of Quicksilver has been downloaded. This version must be relaunched after it is installed.", @"Install and Relaunch", @"Cancel Update", nil);
	if (selection == 1) {
		NSFileManager *manager = [NSFileManager defaultManager];

		NSString *tempDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString uniqueString]];
		[manager createDirectoryAtPath:tempDirectory withIntermediateDirectories:NO attributes:nil error:nil];

		[updateTask setProgress:-1.0];
		[updateTask setName:@"Installing Update"];
		[updateTask setStatus:@"Verifying Data"];
			//		[[QSTaskController sharedInstance] updateTask:@"QSAppUpdateInstalling" status:@"Verifying Data" progress:-1];
		NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/hdiutil"
											 arguments:[NSArray arrayWithObjects:@"attach", path, @"-nobrowse", @"-mountpoint", tempDirectory, nil]];

		[task waitUntilExit];

		NSArray *extracted = [[manager contentsOfDirectoryAtPath:tempDirectory error:nil] pathsMatchingExtensions:[NSArray arrayWithObject:@"app"]];
		//NSLog(@"extract %@ %@ %@",extracted, tempDirectory, [task arguments]);
		if ([extracted count] != 1) {
			NSLog(@"App Update Error");
			return nil;
		}

//		[updateTask:@"Installing Update" progress:-1];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWasMoved:) name:@"QSApplicationWillRelaunch" object:self];
		NSString *newAppVersionPath = [tempDirectory stringByAppendingPathComponent:[extracted lastObject]];
		if (newAppVersionPath) {
			[updateTask setStatus:@"Copying Application"];
			[NSApp replaceWithUpdateFromPath:newAppVersionPath];
			[updateTask setStatus:@"Cleaning Up"];
			//			[[QSTaskController sharedInstance] updateTask:@"QSAppUpdateInstalling" status:@"Cleaning Up" progress:-1];
			task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/hdiutil"
										 arguments:[NSArray arrayWithObjects:@"detach", tempDirectory, nil]];

			[task waitUntilExit];
			[[NSFileManager defaultManager] removeItemAtPath:tempDirectory error:nil];

			[tempPath release];
			tempPath = nil;

			[updateTask stopTask:nil];
			[updateTask release];
			updateTask = nil;

			//	[[QSTaskController sharedInstance] removeTask:@"QSAppUpdateInstalling"];
			[QSTaskController hideViewer];
			if (defaultBool(@"QSQuitAfterUpdate") )
				[NSApp terminate:nil];
			else
				[NSApp relaunch:self];

		} else {

			[updateTask stopTask:nil];
			[updateTask release];
			updateTask = nil;

		}
	}
	return nil;
}

- (void)applicationWasMoved:(NSNotification *)notif {
	NSLog(@"notif %@ %@", notif, tempPath);
}

- (void)finishInstallAndRelaunch {
	//	[manager removeItemAtPath:tempDirectory error:nil];
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

