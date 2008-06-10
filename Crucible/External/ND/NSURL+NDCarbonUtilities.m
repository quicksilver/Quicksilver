/*
 *  NSURL+NDCarbonUtilities.m category
 *  AppleScriptObjectProject
 *
 *  Created by nathan on Wed Dec 05 2001.
 *  Copyright 2001-2007 Nathan Day. All rights reserved.
 */

#import "NSURL+NDCarbonUtilities.h"

/*
 * category implementation NSURL (NDCarbonUtilities)
 */
@implementation NSURL (NDCarbonUtilities)

/*
	+ URLWithFSRef:
 */
+ (NSURL *)URLWithFSRef:(const FSRef *)aFsRef
{
	CFURLRef theURL = CFURLCreateFromFSRef( kCFAllocatorDefault, aFsRef );

	/* With garbage collection, toll free bridging is not so perfect; must always match CFCreate...() and CFRelease().
	Put another way, don't autorelease objects created by CFCreate...() functions */
#ifndef __OBJC_GC__
	[(NSURL *)theURL autorelease];
#else
	CFMakeCollectable( theURL );
#endif

	return (NSURL*)theURL;
}

/*
	+ URLWithFileSystemPathHFSStyle:
 */
+ (NSURL *)URLWithFileSystemPathHFSStyle:(NSString *)aHFSString
{
	CFURLRef theURL = CFURLCreateWithFileSystemPath( kCFAllocatorDefault, (CFStringRef)aHFSString, kCFURLHFSPathStyle, [aHFSString hasSuffix:@":"] );

	/* With garbage collection, toll free bridging is not so perfect; must always match CFCreate...() and CFRelease().
	Put another way, don't autorelease objects created by CFCreate...() functions */
#ifndef __OBJC_GC__
	[(NSURL *)theURL autorelease];
#else
	CFMakeCollectable( theURL );
#endif

	return (NSURL*)theURL;
}

/*
	- getFSRef:
 */
- (BOOL)getFSRef:(FSRef *)aFsRef
{
	return CFURLGetFSRef( (CFURLRef)self, aFsRef ) != 0;
}

/*
	- getFSRef:
 */
- (BOOL)getFSSpec:(FSSpec *)aFSSpec
{
#if defined(__LP64__) && __LP64__
	(void)aFSSpec;
	return NO;
#else
	FSRef			aFSRef;

	return [self getFSRef:&aFSRef] && (FSGetCatalogInfo( &aFSRef, kFSCatInfoNone, NULL, NULL, aFSSpec, NULL ) == noErr);
#endif
}

/*
	- URLByDeletingLastPathComponent
 */
- (NSURL *)URLByDeletingLastPathComponent
{
	CFURLRef theURL = CFURLCreateCopyDeletingLastPathComponent( kCFAllocatorDefault, (CFURLRef)self);

	/* With garbage collection, toll free bridging is not so perfect; must always match CFCreate...() and CFRelease().
	Put another way, don't autorelease objects created by CFCreate...() functions */
#ifndef __OBJC_GC__
	[(NSURL *)theURL autorelease];
#else
	CFMakeCollectable( theURL );
#endif

	return (NSURL*)theURL;
}

/*
	- fileSystemPathHFSStyle
 */
- (NSString *)fileSystemPathHFSStyle
{
	CFStringRef	theString = CFURLCopyFileSystemPath((CFURLRef)self, kCFURLHFSPathStyle);
#ifndef __OBJC_GC__
	[(NSString *)theString autorelease];
#else
	CFMakeCollectable( theString );
#endif

	return (NSString*)theString;
}

/*
	- resolveAliasFile
 */
- (NSURL *)resolveAliasFile
{
	FSRef			theRef;
	Boolean		theIsTargetFolder,
					theWasAliased;
	NSURL			* theResolvedAlias = nil;;

	[self getFSRef:&theRef];

	if( (FSResolveAliasFile ( &theRef, YES, &theIsTargetFolder, &theWasAliased ) == noErr) )
	{
		theResolvedAlias = (theWasAliased) ? [NSURL URLWithFSRef:&theRef] : self;
	}

	return theResolvedAlias;
}

/*
	- finderInfoFlags:type:creator:
 */
- (BOOL)finderInfoFlags:(UInt16*)aFlags type:(OSType*)aType creator:(OSType*)aCreator
{
	FSRef			theFSRef;
	FSCatalogInfo	theInfo;

	if( [self getFSRef:&theFSRef] && FSGetCatalogInfo( &theFSRef, kFSCatInfoFinderInfo, &theInfo, NULL, NULL, NULL) == noErr )
	{
		FileInfo*	theFileInfo = (FileInfo*)(&theInfo.finderInfo);
		if( aFlags ) *aFlags = theFileInfo->finderFlags;
		if( aType ) *aType = theFileInfo->fileType;
		if( aCreator ) *aCreator = theFileInfo->fileCreator;

		return YES;
	}
	else
		return NO;
}

/*
	- finderLocation
 */
- (NSPoint)finderLocation
{
	FSRef			theFSRef;
	FSCatalogInfo	theInfo;
	NSPoint			thePoint = NSMakePoint( 0, 0 );

	if( [self getFSRef:&theFSRef] && FSGetCatalogInfo( &theFSRef, kFSCatInfoFinderInfo, &theInfo, NULL, NULL, NULL) == noErr )
	{
		FileInfo*	theFileInfo = (FileInfo*)(&theInfo.finderInfo);
		thePoint = NSMakePoint(theFileInfo->location.h, theFileInfo->location.v );
 	}

	return thePoint;
}

/*
	- setFinderInfoFlags:mask:type:creator:
 */
- (BOOL)setFinderInfoFlags:(UInt16)aFlags mask:(UInt16)aMask type:(OSType)aType creator:(OSType)aCreator
{
	BOOL				theResult = NO;
	FSRef			theFSRef;
	FSCatalogInfo	theInfo;

	if( [self getFSRef:&theFSRef] && FSGetCatalogInfo( &theFSRef, kFSCatInfoFinderInfo, &theInfo, NULL, NULL, NULL) == noErr )
	{
		FileInfo*	theFileInfo = (FileInfo*)(&theInfo.finderInfo);
		theFileInfo->finderFlags = ((aFlags & aMask) | (theFileInfo->finderFlags & ~aMask)) & ~kHasBeenInited;
		theFileInfo->fileType = aType;
		theFileInfo->fileCreator = aCreator;

		theResult = FSSetCatalogInfo( &theFSRef, kFSCatInfoFinderInfo, &theInfo) == noErr;
	}

	return theResult;
}

/*
	- setFinderLocation:
 */
- (BOOL)setFinderLocation:(NSPoint)aLocation
{
	BOOL				theResult = NO;
	FSRef			theFSRef;
	FSCatalogInfo	theInfo;

	if( [self getFSRef:&theFSRef] && FSGetCatalogInfo( &theFSRef, kFSCatInfoFinderInfo, &theInfo, NULL, NULL, NULL) == noErr )
	{
		FileInfo*	theFileInfo = (FileInfo*)(&theInfo.finderInfo);
		theFileInfo->location.h = aLocation.x;
		theFileInfo->location.v = aLocation.y;

		theResult = FSSetCatalogInfo( &theFSRef, kFSCatInfoFinderInfo, &theInfo) == noErr;
	}

	return theResult;
}

@end

@implementation NSURL (NDCarbonUtilitiesInfoFlags)

- (BOOL)hasCustomIcon
{
	UInt16	theFlags;
	return [self finderInfoFlags:&theFlags type:NULL creator:NULL] == YES && (theFlags & kHasCustomIcon) != 0;
}

@end



