//
//  QSUpdateController.h
//  Quicksilver
//
//  Created by Alcor on 7/22/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class QSTask, QSURLDownload;

@interface QSUpdateController : NSObject {
	NSTimer *updateTimer;
	BOOL doStartupCheck;
	QSURLDownload *appDownload;
	NSString *newVersion;
	NSString *tempPath;
	QSTask *updateTask;
	BOOL shouldCancel;
}

+ (id)sharedInstance;
- (void)setUpdateTimer;
- (IBAction)checkForUpdate:(id)sender;
- (void)forceStartupCheck;
- (NSArray *)extractFilesFromQSPkg:(NSString *)path toPath:(NSString *)tempDirectory;
- (IBAction)threadedRequestedCheckForUpdate:(id)sender;
- (void)finishAppInstall;
- (BOOL)installAppFromDiskImage:(NSString *)path;
- (IBAction)threadedCheckForUpdate:(id)sender;
@end
