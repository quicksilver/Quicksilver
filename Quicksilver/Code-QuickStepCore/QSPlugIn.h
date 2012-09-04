//
//  QSPlugInInfo.h
//  Quicksilver
//
//  Created by Alcor on 2/5/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define kQSPlugInInfoHandlers @"QSPlugInInfoHandlers"

@interface NSObject (QSPlugInInfoHandler)
- (BOOL)handleInfo:(id)info ofType:(NSString *)type fromBundle:(NSBundle *)bundle;
@end


@interface QSPlugIn : NSObject {
	NSBundle *bundle;
	NSMutableDictionary *data;

	NSImage *icon;
	NSImage *smallIcon;

	BOOL installing;
	BOOL loading;
	BOOL loaded;
	BOOL shouldInstall;
	NSString *loadError;
	NSString *status;

}
+ (id)plugInWithBundle:(NSBundle *)aBundle;
+ (id)plugInWithWebInfo:(NSDictionary *)webInfo;
+ (NSString *)bundleIDForPluginAt:(NSString*)path andVersion:(NSString**)version;
- (NSInteger) isInstalled;
- (NSString *)name;
- (NSString *)statusBullet;
- (NSString *)author;
- (NSDate *)createdDate;
- (NSDate *)modifiedDate;
- (NSDate *)installedDate;
- (NSDate *)latestVersionDate;
- (NSString *)version;
- (NSString *)buildVersion;
- (NSString *)installedVersion;
- (NSString *)latestVersion;

- (BOOL)isRecommended;
- (NSArray *)categories;
- (NSString *)categoriesAsString;
- (NSArray *)relatedBundles;
- (NSArray *)relatedPaths;

- (NSData *)attributedDescription;
- (NSImage *)icon;
- (NSInteger) enabled;
- (BOOL)canBeDisabled;
- (BOOL)isObsolete;
- (BOOL)needsUpdate;
- (NSString *)identifier;

- (NSString *)path;

- (NSString *)bundleIdentifier;
- (NSString *)bundlePath;
- (NSInteger) isLoaded;
- (NSDictionary *)info;
- (BOOL)isSupported; // plug-in provides an architecture matching Quicksilver's
- (BOOL)isSecret;
//---------
- (NSBundle *)bundle;
- (void)setBundle:(NSBundle *)newBundle;
- (NSMutableDictionary *)data;
- (void)setData:(NSMutableDictionary *)newData;
- (NSString *)loadError;
- (void)setLoadError:(NSString *)newLoadError;

- (BOOL)delete;
- (BOOL)reveal;
- (NSArray *)dependencies;
- (NSSet *)obsoletes;
- (void)downloadFailed;
+ (id)plugInWithBundle:(NSBundle *)aBundle;
- (NSString *)infoHTML;
- (BOOL)hasExtendedDescription;
- (NSString *)shortName;
- (void)setEnabled:(BOOL)flag;
- (NSString *)text;
- (NSImage *)image;
@property (copy,readwrite,nonatomic) NSString *status;
@end


@interface QSPlugIn (Registry)
- (BOOL)registerPlugIn;
- (NSArray *)unmetDependencies;
- (BOOL)meetsRequirements:(NSString **)error;
@end
