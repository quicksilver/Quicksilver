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

}
+ (id)plugInWithBundle:(NSBundle *)aBundle;
+ (id)plugInWithWebInfo:(NSDictionary *)webInfo;
- (int) isInstalled;
- (NSString *)name;
- (NSString *)status;
- (NSString *)statusBullet;
- (NSString *)author;
- (NSDate *)createdDate;
- (NSDate *)modifiedDate;
- (NSString *)version;
- (NSString *)buildVersion;

- (BOOL)isRecommended;
- (NSArray *)categories;
- (NSArray *)relatedBundles;

- (NSData *)attributedDescription;
- (NSImage *)icon;
- (int) enabled;
- (BOOL)canBeDisabled;
- (BOOL)needsUpdate;
- (NSString *)identifier;

- (NSString *)path;

- (NSString *)bundleIdentifier;
- (NSString *)bundlePath;
- (int) isLoaded;
- (BOOL)meetsFeature;
- (NSDictionary *)info;
- (BOOL)isUniversal;
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
- (void)downloadFailed;
+ (id)plugInWithBundle:(NSBundle *)aBundle;
- (NSString *)infoHTML;
- (NSString *)shortName;
- (void)setEnabled:(BOOL)flag;
- (NSString *)text;
- (NSImage *)image;
@end


@interface QSPlugIn (Registry)
- (BOOL)registerPlugIn;
- (NSArray *)unmetDependencies;
- (BOOL)meetsRequirements:(NSString **)error;
@end
