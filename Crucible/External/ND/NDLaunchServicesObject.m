/*
 *  NDLaunchServicesObject.m
 *  Popup Launcher
 *
 *  Created by Nathan Day on Wed Dec 26 2001.
 *  Copyright (c) 2001 Nathan Day. All rights reserved.
 */

#import "NDLaunchServicesObject.h"
#import <Carbon/Carbon.h>

/*
 * class implementation NDLaunchServicesObject
 */
@implementation NDLaunchServicesObject

static NDLaunchServicesObject		* defaultLaunchServices = nil;

/*
 * +defaultLaunchServices
 */
+ (NDLaunchServicesObject *)defaultLaunchServices
{
	if( defaultLaunchServices == nil )
	{
		defaultLaunchServices = [[NDLaunchServicesObject alloc] initWithFlags:kLSInitializeDefaults];
	}

	return defaultLaunchServices;
}

/*
 * +terminateDefault
 */
+ (void)terminateDefault
{
	[defaultLaunchServices release];
}

/*
 * -initWithFlags:aFlags
 */
- initWithFlags:(LSInitializeFlags)aFlags
{
#if 0
	if( ( self = [self init] ) != nil )
	{
		if( LSInit( aFlags ) != noErr )
		{
			[self release];
			self = nil;
		}
	}

	return self;
#else
	return [self init];
#endif
}

/*
 * -dealloc
 */
- (void)dealloc
{
	if( self == defaultLaunchServices )
	{
#if 0
		LSTerm();
#endif
		defaultLaunchServices = nil;
	}

	[super dealloc];
}

/*
 * -copyItemInfo:forURL:outInfo:
 */
- (BOOL)copyItemInfo:(LSRequestedInfo)aWhichInfo forURL:(NSURL *)aURL outInfo:(LSItemInfoRecord *)anOutInfo
{
	return LSCopyItemInfoForURL( (CFURLRef)aURL, aWhichInfo, anOutInfo) == noErr;
}

/*
 * -displayNameForURL:
 */
- (NSString *)displayNameForURL:(NSURL *)aURL
{
	NSString		* theName;
	return ( LSCopyDisplayNameForURL( (CFURLRef)aURL, (CFStringRef *)&theName) == noErr ) ? [theName autorelease] : nil;
}

/*
 * -setExtensionHidden:forURL:
 */
- (BOOL)setExtensionHidden:(BOOL)aHide forURL:(NSURL *)aURL
{
	return LSSetExtensionHiddenForURL( (CFURLRef)aURL, (Boolean)aHide) == noErr;
}

/*
 * -kindStringForURL:
 */
- (NSString *)kindStringForURL:(NSURL *)aURL
{
	NSString		* theKind;
	return ( LSCopyKindStringForURL( (CFURLRef)aURL, (CFStringRef *)&theKind ) == noErr ) ? [theKind autorelease] : nil;
}

/*
 * -applicationForType:creator:extension:inRole:
 */
- (NSURL *)applicationForType:(OSType)aType creator:(OSType)aCreator extension:(NSString *)anExtension inRole:(LSRolesMask)aRole
{
	NSURL		* theApplicationURL;
	return ( LSGetApplicationForInfo( aType, aCreator, (CFStringRef)anExtension, aRole, NULL, (CFURLRef *)&theApplicationURL) == noErr ) ? theApplicationURL : nil;
}

/*
 * -applicationForURL:inRole:
 */
- (NSURL *)applicationForURL:(NSURL *)aURL inRole:(LSRolesMask)aRole
{
	NSURL		* theApplicationURL;
	return ( LSGetApplicationForURL( (CFURLRef)aURL, aRole, NULL, (CFURLRef *)&theApplicationURL) == noErr ) ? theApplicationURL : nil;
}

/*
 * -findApplicationForCreator:bundleID:name:
 */
- (NSURL *)findApplicationForCreator:(OSType)aCreator bundleID:(NSString *)aBundleID name:(NSString *)aName
{
	NSURL		* theApplicationURL;
	return ( LSFindApplicationForInfo( aCreator, (CFStringRef)aBundleID, (CFStringRef)aName, NULL, (CFURLRef *)&theApplicationURL) == noErr ) ? theApplicationURL : nil;
}

/*
 * -canURL:acceptURL:inRole:acceptanceFlags:
 */
- (BOOL)canURL:(NSURL *)aTargetURL acceptURL:(NSURL *)aURL inRole:(LSRolesMask)aRole acceptanceFlags:(LSAcceptanceFlags)aFlags
{
	Boolean			theWillAcceptsItem;
	return ( LSCanURLAcceptURL( (CFURLRef)aURL, (CFURLRef)aTargetURL, aRole, aFlags, &theWillAcceptsItem) == noErr ) && theWillAcceptsItem;
}

/*
 * -canURL:acceptURL:inRole:
 */
- (BOOL)canURL:(NSURL *)aURL acceptURL:(NSURL *)aTargetURL inRole:(LSRolesMask)aRole
{
	return [self canURL:aURL acceptURL:aTargetURL inRole:aRole acceptanceFlags:kLSAcceptDefault];

}

/*
 * -openURL:
 */
- (NSURL *)openURL:(NSURL *)aURL
{
	NSURL			* theLaunchedURL = nil;

	return ( LSOpenCFURLRef( (CFURLRef)aURL, (CFURLRef *)&theLaunchedURL) == noErr ) ? theLaunchedURL : nil;
}

/*
 * -openURLs:usingApplication:
 */
- (NSURL *)openURLs:(NSArray *)anArray usingApplication:(NSURL *)anApplication
{
	return [self openURLs:anArray usingApplication:anApplication params:nil launchFlags:kLSLaunchDefaults asyncRefCon:NULL];
}

/*
 * -openURLs:usingApplication:params:launchFlags:asyncRefCon:
 */
- (NSURL *)openURLs:(NSArray *)anArray usingApplication:(NSURL *)anApplication params:(NSAppleEventDescriptor *)aParams launchFlags:(LSLaunchFlags)aFlags asyncRefCon:(void *)asyncRefCon
{
	LSLaunchURLSpec		theLaunchSpec;
	NSURL						* theLaunchedURL = nil;

	theLaunchSpec.appURL = ( anApplication != nil ) ? (CFURLRef)anApplication : NULL;
	theLaunchSpec.itemURLs = ( anArray != nil ) ? (CFArrayRef)anArray : NULL;
	theLaunchSpec.launchFlags = ( aFlags ) ? aFlags : kLSLaunchDefaults;
	theLaunchSpec.asyncRefCon = asyncRefCon;

	if( aParams == nil )
	{
		theLaunchSpec.passThruParams = NULL;
		if( LSOpenFromURLSpec( &theLaunchSpec, (CFURLRef *)&theLaunchedURL) != noErr )
		{
			theLaunchedURL = nil;
		}
	}
	else
	{
		NSData		* theData;
		AEDesc		thePassThruParams;

		theData = [aParams data];

		if( AECreateDesc( [aParams descriptorType], [theData bytes], [theData length], &thePassThruParams ) == noErr )
		{
			theLaunchSpec.passThruParams = &thePassThruParams;

			if( LSOpenFromURLSpec( &theLaunchSpec, (CFURLRef *)&theLaunchedURL) != noErr )
			{
				theLaunchedURL = nil;
			}

			AEDisposeDesc( &thePassThruParams );
		}
	}

	return theLaunchedURL;
}

/*
 * -filetypeOfURL:
 */
- (OSType)filetypeOfURL:(NSURL *)aURL
{
	LSItemInfoRecord			theInfoRecord;
	return ( LSCopyItemInfoForURL( (CFURLRef)aURL, kLSRequestTypeCreator, &theInfoRecord) == noErr ) ? theInfoRecord.filetype : 0;
}

/*
 * -creatorOfURL:
 */
- (OSType)creatorOfURL:(NSURL *)aURL;
{
	LSItemInfoRecord			theInfoRecord;
	return ( LSCopyItemInfoForURL( (CFURLRef)aURL, kLSRequestTypeCreator, &theInfoRecord) == noErr ) ? theInfoRecord.filetype : 0;
}

/*
 * -extensionOfURL:
 */
- (NSString *)extensionOfURL:(NSURL *)aURL
{
	LSItemInfoRecord			theInfoRecord;
	return ( LSCopyItemInfoForURL( (CFURLRef)aURL, kLSRequestExtension, &theInfoRecord ) == noErr ) ? [(NSString *)theInfoRecord.extension autorelease] : nil;
}

@end

/*
 * class implementation NDLaunchServicesObject (LSItemInfoFlags)
 */
@implementation NDLaunchServicesObject (LSItemInfoFlags)

/*
 * -isPlainFileAtURL:
 */
- (BOOL)isPlainFileAtURL:(NSURL *)aURL
{
	return ([self itemInfoFlagAtURL:aURL whichInfo:kLSRequestBasicFlagsOnly] & kLSItemInfoIsPlainFile) != 0;
}
/*
 * -isPackageAtURL:
 */
- (BOOL)isPackageAtURL:(NSURL *)aURL
{
	return ([self itemInfoFlagAtURL:aURL whichInfo:kLSRequestBasicFlagsOnly] & kLSItemInfoIsPackage) != 0;
}
/*
 * -isApplicationAtURL:
 */
- (BOOL)isApplicationAtURL:(NSURL *)aURL
{
	return ([self itemInfoFlagAtURL:aURL whichInfo:kLSRequestAppTypeFlags] & kLSItemInfoIsApplication) != 0;
}
/*
 * -isContainerAtURL:
 */
- (BOOL)isContainerAtURL:(NSURL *)aURL
{
	return ([self itemInfoFlagAtURL:aURL whichInfo:kLSRequestBasicFlagsOnly] & kLSItemInfoIsContainer) != 0;
}
/*
 * -isAliasFileAtURL:
 */
- (BOOL)isAliasFileAtURL:(NSURL *)aURL
{
	return ([self itemInfoFlagAtURL:aURL whichInfo:kLSRequestBasicFlagsOnly] & kLSItemInfoIsAliasFile) != 0;
}
/*
 * -isSymlinkAtURL:
 */
- (BOOL)isSymlinkAtURL:(NSURL *)aURL
{
	return ([self itemInfoFlagAtURL:aURL whichInfo:kLSRequestBasicFlagsOnly] & kLSItemInfoIsSymlink) != 0;
}
/*
 * -isInvisibleAtURL:
 */
- (BOOL)isInvisibleAtURL:(NSURL *)aURL
{
	return ([self itemInfoFlagAtURL:aURL whichInfo:kLSRequestBasicFlagsOnly] & kLSItemInfoIsInvisible) != 0;
}
/*
 * -isNativeAppAtURL:
 */
- (BOOL)isNativeAppAtURL:(NSURL *)aURL
{
	return ([self itemInfoFlagAtURL:aURL whichInfo:kLSRequestAppTypeFlags] & kLSItemInfoIsNativeApp) != 0;
}
/*
 * -isClassicAppAtURL:
 */
- (BOOL)isClassicAppAtURL:(NSURL *)aURL
{
	return ([self itemInfoFlagAtURL:aURL whichInfo:kLSRequestAppTypeFlags] & kLSItemInfoIsClassicApp) != 0;
}
/*
 * -doesAppPrefersNativeAtURL:
 */
- (BOOL)doesAppPrefersNativeAtURL:(NSURL *)aURL
{
	return ([self itemInfoFlagAtURL:aURL whichInfo:kLSRequestAppTypeFlags] & kLSItemInfoAppPrefersClassic) != 0;
}
/*
 * -doesAppPrefersClassicAtURL:
 */
- (BOOL)doesAppPrefersClassicAtURL:(NSURL *)aURL
{
	return ([self itemInfoFlagAtURL:aURL whichInfo:kLSRequestAppTypeFlags] & kLSItemInfoAppPrefersClassic) != 0;
}
/*
 * -isAppIsScriptableAtURL:
 */
- (BOOL)isAppIsScriptableAtURL:(NSURL *)aURL
{
	return ([self itemInfoFlagAtURL:aURL whichInfo:kLSRequestAppTypeFlags] & kLSItemInfoAppIsScriptable) != 0;
}
/*
 * -isVolumeAtURL:
 */
- (BOOL)isVolumeAtURL:(NSURL *)aURL
{
	return ([self itemInfoFlagAtURL:aURL whichInfo:kLSRequestBasicFlagsOnly] & kLSItemInfoIsVolume) != 0;
}
/*
 * -isExtensionIsHiddenAtURL:
 */
- (BOOL)isExtensionIsHiddenAtURL:(NSURL *)aURL
{
	return ([self itemInfoFlagAtURL:aURL whichInfo:kLSRequestExtensionFlagsOnly] & kLSItemInfoExtensionIsHidden) != 0;
}

/*
 * -itemInfoFlagAtURL:
 */
- (LSItemInfoFlags)itemInfoFlagAtURL:(NSURL *)aURL whichInfo:(LSRequestedInfo)aWhichInfo
{
	LSItemInfoRecord		theItemInfo;
	
	if( LSCopyItemInfoForURL( (CFURLRef)aURL, aWhichInfo & ~kLSRequestExtension, &theItemInfo) != noErr)
		theItemInfo.flags = 0;

	return theItemInfo.flags;
}

/*
 * -basicItemInfoFlagAtURL:
 */
- (LSItemInfoFlags)basicItemInfoFlagAtURL:(NSURL *)aURL
{
	return [self itemInfoFlagAtURL:aURL whichInfo:kLSRequestBasicFlagsOnly];
}

@end


