/*
 *  NDLaunchServicesObject.h
 *  Popup Launcher
 *
 *  Created by Nathan Day on Wed Dec 26 2001.
 *  Copyright (c) 2001 Nathan Day. All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface NDLaunchServicesObject : NSObject
{
}

+ (NDLaunchServicesObject *)defaultLaunchServices;
+ (void)terminateDefault;				// call when your app quits

- initWithFlags:(LSInitializeFlags)aFlags;

- (BOOL)copyItemInfo:(LSRequestedInfo)aWhichInfo forURL:(NSURL *)aURL outInfo:(LSItemInfoRecord *)anOutInfo;

- (NSString *)displayNameForURL:(NSURL *)aURL;
- (BOOL)setExtensionHidden:(BOOL)aHide forURL:(NSURL *)aURL;
- (NSString *)kindStringForURL:(NSURL *)aURL;

- (NSURL *)applicationForType:(OSType)aType creator:(OSType)aCreator extension:(NSString *)anExtension inRole:(LSRolesMask)aRole;
- (NSURL *)applicationForURL:(NSURL *)aURL inRole:(LSRolesMask)aRole;
- (NSURL *)findApplicationForCreator:(OSType)aCreator bundleID:(NSString *)aBundleID name:(NSString *)aName;

- (BOOL)canURL:(NSURL *)aURL acceptURL:(NSURL *)aTargetURL inRole:(LSRolesMask)aRole acceptanceFlags:(LSAcceptanceFlags)aFlags;
- (BOOL)canURL:(NSURL *)aURL acceptURL:(NSURL *)aTargetURL inRole:(LSRolesMask)aRole;

- (NSURL *)openURL:(NSURL *)aURL;
- (NSURL *)openURLs:(NSArray *)anArray usingApplication:(NSURL *)anApplication;
- (NSURL *)openURLs:(NSArray *)anArray usingApplication:(NSURL *)anApplication params:(NSAppleEventDescriptor *)aParams launchFlags:(LSLaunchFlags)aFlags asyncRefCon:(void *)asyncRefCon;

- (OSType)filetypeOfURL:(NSURL *)aURL;
- (OSType)creatorOfURL:(NSURL *)aURL;
- (NSString *)extensionOfURL:(NSURL *)aURL;

@end

/*
 * methods to get access LSItemInfoFlags
 */
@interface NDLaunchServicesObject (LSItemInfoFlags)

- (BOOL)isPlainFileAtURL:(NSURL *)aURL;
- (BOOL)isPackageAtURL:(NSURL *)aURL;
- (BOOL)isApplicationAtURL:(NSURL *)aURL;
- (BOOL)isContainerAtURL:(NSURL *)aURL;
- (BOOL)isAliasFileAtURL:(NSURL *)aURL;
- (BOOL)isSymlinkAtURL:(NSURL *)aURL;
- (BOOL)isInvisibleAtURL:(NSURL *)aURL;
- (BOOL)isNativeAppAtURL:(NSURL *)aURL;
- (BOOL)isClassicAppAtURL:(NSURL *)aURL;
- (BOOL)doesAppPrefersNativeAtURL:(NSURL *)aURL;
- (BOOL)doesAppPrefersClassicAtURL:(NSURL *)aURL;
- (BOOL)isAppIsScriptableAtURL:(NSURL *)aURL;
- (BOOL)isVolumeAtURL:(NSURL *)aURL;
- (BOOL)isExtensionIsHiddenAtURL:(NSURL *)aURL;

- (LSItemInfoFlags)itemInfoFlagAtURL:(NSURL *)aURL whichInfo:(LSRequestedInfo)aWhichInfo;
- (LSItemInfoFlags)basicItemInfoFlagAtURL:(NSURL *)aURL;

@end
