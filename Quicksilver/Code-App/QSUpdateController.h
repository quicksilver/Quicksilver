//
//  QSUpdateController.h
//  Quicksilver
//
//  Created by Alcor on 7/22/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define QSUpdateAvailableUserNotification @"QSUpdateAvailableUserNotification"
#define QSUpdateDownloadedUserNotification @"QSUpdateDownloadedUserNotification"
#define QSUpdateInstalledUserNotification @"QSUpdateInstalledUserNotification"

@class QSTask, QSURLDownload;

@interface QSUpdateController : NSObject <NSUserNotificationCenterDelegate> {
	NSTimer *updateTimer;
	BOOL doStartupCheck;
	QSURLDownload *appDownload;
	NSString *newVersion;
	NSString *tempPath;
	QSTask *updateTask;
	BOOL shouldCancel;
    NSUserNotificationCenter *userNotificationCenter;
}

+ (id)sharedInstance;
- (void)setUpdateTimer;
- (IBAction)checkForUpdate:(id)sender;
//- (BOOL)updatePlugIns:(NSArray *)bundles;
//- (BOOL)installPlugInsForIdentifiers:(NSArray *)bundleIDs;
//- (NSMutableArray *)updatedPlugIns;
//- (NSMutableArray *)downloadsQueue;
//- (BOOL)handleInstallURL:(NSURL *)url;
//- (BOOL)installPlugInsFromFiles:(NSArray *)fileList;
//- (NSString *)installPlugInFromFile:(NSString *)path;
//- (NSArray *)installPlugInFromCompressedFile:(NSString *)path;
//-(float) downloadProgress;
- (void)forceStartupCheck;
- (NSArray *)extractFilesFromQSPkg:(NSString *)path toPath:(NSString *)tempDirectory;
- (IBAction)threadedRequestedCheckForUpdate:(id)sender;
- (void)finishAppInstall;
- (BOOL)installAppFromDiskImage:(NSString *)path;
- (IBAction)threadedCheckForUpdate:(id)sender;
@end
