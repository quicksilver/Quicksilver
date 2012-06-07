//
//  QSPlugInManager.h
//  Quicksilver
//
//  Created by Alcor on 2/7/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QSCore/QSURLDownloadWrapper.h>

#define QSPlugInListingDownloadCompleteNotification @"QSPlugInListingDownloadComplete"
#define QSPlugInInfoLoadedNotification @"QSPlugInInfoLoaded"
#define QSPlugInInfoFailedNotification @"QSPlugInInfoFailed"

@class QSPlugIn;
@interface QSPlugInManager : NSObject <QSURLDownloadDelegate> {
	BOOL startupLoadComplete;

	NSMutableDictionary 			*localPlugIns; 	// Most recent version of every plugin on this machine. Includes restricted.
	NSMutableDictionary 			*knownPlugIns; 	// Local plugins + visible web plugins. Includes restricted.
	NSMutableDictionary				*loadedPlugIns; 	// All plugins that have been loaded

	NSMutableArray 					*oldPlugIns; 		// Plugins with newer versions overriding, these are not included in local plugins
	NSMutableDictionary 			*dependingPlugIns; 	// Dictionary of dependencies -> array of waiting
	NSMutableDictionary				*obsoletePlugIns;   // plugins that are made obsolete by another

	NSMutableData *receivedData;
	NSMutableDictionary *plugInWebData;
	NSDate 				*plugInWebDownloadDate;

	BOOL showNotifications;
	BOOL updatingPlugIns;
	BOOL warnedOfRelaunch;

	NSMutableSet *updatedPlugIns;
	NSMutableArray *queuedDownloads;
    NSMutableSet *activeDownloads;
    
	NSString *installStatus;
	CGFloat installProgress;
	BOOL isInstalling;
	BOOL supressRelaunchMessage;
    NSInteger errorCount;
    NSTimeInterval lastCheck;
}

+ (id)sharedInstance;


- (BOOL)showNotifications;
- (void)setShowNotifications: (BOOL)flag;

- (QSPlugIn *)plugInWithBundle:(NSBundle *)bundle;
- (QSPlugIn *)plugInWithID:(NSString *)identifier;
- (BOOL)plugInIsMostRecent:(QSPlugIn *)plugIn inGroup:(NSDictionary *)loadingBundles;
- (BOOL)plugInMeetsRequirements:(QSPlugIn *)plugIn;
- (BOOL)plugInMeetsDependencies:(QSPlugIn *)plugIn;
- (void)downloadWebPlugInInfoFromDate:(NSDate *)date forUpdateVersion:(NSString *)version synchronously:(BOOL)synchro;
- (NSMutableDictionary *)loadedPlugIns;
- (NSMutableArray *)oldPlugIns;

- (BOOL)startupLoadComplete;

- (NSMutableArray *)allBundles;
- (void)loadPlugInsAtLaunch;
- (void)suggestOldPlugInRemoval;
- (BOOL)liveLoadPlugIn:(QSPlugIn *)plugin;
- (NSArray *)knownPlugInsWithWebInfo ;
//- (BOOL)shouldLoadPlugIn:(QSPlugIn *)plugIn inGroup:(NSDictionary *)loadingBundles;
- (QSPlugIn *)plugInBundleWasInstalled:(NSBundle *)bundle;
- (void)deletePlugIns:(NSArray *)deletePlugIns fromWindow:(NSWindow *)window;
- (void)checkForUnmetDependencies;
- (void)checkForObsoletes:(QSPlugIn *)plugin;
- (void)removeObsoletePlugIns;
//- (NSMutableDictionary *)validPlugIns;
//- (void)setValidPlugIns:(NSMutableDictionary *)newValidPlugIns;



//- (NSString *)installPlugInFromFile:(NSString *)path;
- (BOOL)installPlugInsForIdentifiers:(NSArray *)bundleIDs;
- (BOOL)installPlugInsForIdentifiers:(NSArray *)bundleIDs version:(NSString *)version;
- (void)loadNewWebData:(NSData *)data;
- (BOOL)checkForPlugInUpdates;
- (BOOL)checkForPlugInUpdatesForVersion:(NSString *)version;

- (NSMutableDictionary *)localPlugIns;
- (void)setLocalPlugIns:(NSMutableDictionary *)newLocalPlugIns;
- (NSMutableDictionary *)knownPlugIns;
- (void)setKnownPlugIns:(NSMutableDictionary *)newKnownPlugIns;
- (NSMutableDictionary *)loadedPlugIns;
- (void)setLoadedPlugIns:(NSMutableDictionary *)newLoadedPlugIns;
- (NSMutableDictionary *)obsoletePlugIns;
- (NSString *)installStatus;
- (void)setInstallStatus:(NSString *)newInstallStatus;
- (CGFloat) installProgress;
- (void)setInstallProgress:(CGFloat)newInstallProgress;
- (BOOL)isInstalling;
- (void)setIsInstalling:(BOOL)flag;
- (void)updateDownloadProgressInfo;
- (NSString *)urlStringForPlugIn:(NSString *)ident version:(NSString *)version;
- (BOOL)supressRelaunchMessage;
- (void)setSupressRelaunchMessage:(BOOL)flag;
- (NSString *)installPlugInFromFile:(NSString *)path;
- (void)downloadWebPlugInInfo;
- (void)downloadWebPlugInInfoIgnoringDate;
- (BOOL)updatePlugInsForNewVersion:(NSString *)version;
- (CGFloat)downloadProgress;
- (NSMutableSet *)updatedPlugIns;
- (BOOL)handleInstallURL:(NSURL *)url;
- (BOOL)installPlugInsFromFiles:(NSArray *)fileList;

- (void)cancelPlugInInstall;

- (void)loadPlugInInfo:(NSArray *)array;
@end
