/*
 *  NSURL+NDCarbonUtilities.m category
 *  AppleScriptObjectProject
 *
 *  Created by nathan on Wed Dec 05 2001.
 *  Copyright (c) 2001 __CompanyName__. All rights reserved.
 */

#import "NSURL+NDCarbonUtilities.h"

/*
 * category implementation NSURL (NDCarbonUtilities)
 */
@implementation NSURL (NDCarbonUtilities)

/*
 * +URLWithFSRef:
 */
+ (NSURL *)URLWithFSRef:(const FSRef *)aFsRef
{
	return [(NSURL *)CFURLCreateFromFSRef( kCFAllocatorDefault, aFsRef ) autorelease];
}

/*
 * +URLWithFileSystemPathHFSStyle:
 */
+ (NSURL *)URLWithFileSystemPathHFSStyle:(NSString *)aHFSString
{
	return [(NSURL *)CFURLCreateWithFileSystemPath( kCFAllocatorDefault, (CFStringRef)aHFSString, kCFURLHFSPathStyle, [aHFSString hasSuffix:@":"] ) autorelease];
}

/*
 * -getFSRef:
 */
- (BOOL)getFSRef:(FSRef *)aFsRef
{
	return CFURLGetFSRef( (CFURLRef)self, aFsRef ) != 0;
}

/*
 * -getFSRef:
 */
- (BOOL)getFSSpec:(FSSpec *)aFSSpec
{
	FSRef			aFSRef;

	return [self getFSRef:&aFSRef] && (FSGetCatalogInfo( &aFSRef, kFSCatInfoNone, NULL, NULL, aFSSpec, NULL ) == noErr);
}

/*
 * -URLByDeletingLastPathComponent
 */
- (NSURL *)URLByDeletingLastPathComponent
{
	return [(NSURL *)CFURLCreateCopyDeletingLastPathComponent( kCFAllocatorDefault, (CFURLRef)self) autorelease];
}

/*
 * -fileSystemPathHFSStyle
 */
- (NSString *)fileSystemPathHFSStyle
{
    return [(NSString *)CFURLCopyFileSystemPath((CFURLRef)self, kCFURLHFSPathStyle) autorelease];
}

/*
 * -resolveAliasFile
 */
- (NSURL *)resolveAliasFile
{
	FSRef			theRef;
	Boolean		theIsTargetFolder,
					theWasAliased = NO;
	NSURL			* theResolvedAlias = self;;

	[self getFSRef:&theRef];

	if( (FSResolveAliasFile ( &theRef, YES, &theIsTargetFolder, &theWasAliased ) == noErr) )
	{
		theResolvedAlias = (theWasAliased) ? [NSURL URLWithFSRef:&theRef] : self;
	}
	else
		NSLog( @"Failed to resolve file %@ as alias file", self );

	return theResolvedAlias;
}

/*
 * -finderInfoFlags:type:creator:
 */
- (BOOL)finderInfoFlags:(UInt16*)aFlags type:(OSType*)aType creator:(OSType*)aCreator
{
	FSRef			theRef;
	FSCatalogInfo	theCatalogInfo = {0};
	FileInfo			* theInfo = (FileInfo*)&theCatalogInfo.finderInfo;

	if( [self getFSRef:&theRef]
		&& FSGetCatalogInfo( &theRef, kFSCatInfoFinderInfo, &theCatalogInfo, NULL, NULL, NULL ) == noErr )	
	{
		if( aFlags ) *aFlags = theInfo->fileCreator;
		if( aType ) *aType = theInfo->fileType;
		if( aCreator ) *aCreator = theInfo->finderFlags;

		return YES;
	}
	else
		return NO;
}

/*
 * -finderLocation
 */
- (NSPoint)finderLocation
{
	FSRef				theRef;
	FSCatalogInfo	theCatalogInfo = {0};
	FileInfo			* theInfo = (FileInfo*)&theCatalogInfo.finderInfo;
	NSPoint			thePoint = NSMakePoint( 0, 0 );

	if( [self getFSRef:&theRef] && FSGetCatalogInfo( &theRef, kFSCatInfoFinderInfo, &theCatalogInfo, NULL, NULL, NULL ) == noErr )
	{
		thePoint = NSMakePoint(theInfo->location.h, theInfo->location.v );
 	}

	return thePoint;
}

/*
 * -setFinderInfoFlags:mask:type:creator:
 */
- (BOOL)setFinderInfoFlags:(UInt16)aFlags mask:(UInt16)aMask type:(OSType)aType creator:(OSType)aCreator
{
	BOOL				theResult = NO;
	FSRef				theRef;
	FSCatalogInfo	theCatalogInfo = {0};
	FileInfo			* theInfo = (FileInfo*)&theCatalogInfo.finderInfo;
	
//	if( [self getFSSpec:&theFSSpec] && FSpGetFInfo( &theFSSpec, &theInfo) == noErr )
	if( [self getFSRef:&theRef]
		 && FSGetCatalogInfo( &theRef, kFSCatInfoFinderInfo, &theCatalogInfo, NULL, NULL, NULL ) == noErr )	
	{
		theInfo->finderFlags = (aFlags & aMask) | (theInfo->finderFlags & !aMask);
		theInfo->fileType = aType;
		theInfo->fileCreator = aCreator;

		theResult = FSSetCatalogInfo(&theRef, kFSCatInfoFinderInfo, &theCatalogInfo)  == noErr;
//		theResult = FSpSetFInfo( &theFSSpec, &theInfo) == noErr;
	}

	return theResult;
}

/*
 * -setFinderLocation:
 */
- (BOOL)setFinderLocation:(NSPoint)aLocation
{
	BOOL				theResult = NO;
	FSRef				theRef;
	FSCatalogInfo	theCatalogInfo = {0};
	FileInfo			* theInfo = (FileInfo*)&theCatalogInfo.finderInfo;

//	if( [self getFSSpec:&theFSSpec] && FSpGetFInfo( &theFSSpec, &theInfo) == noErr )
	if( [self getFSRef:&theRef]
			 && FSGetCatalogInfo( &theRef, kFSCatInfoFinderInfo, &theCatalogInfo, NULL, NULL, NULL ) == noErr )	
	{
		theInfo->location.h = aLocation.x;
		theInfo->location.v = aLocation.y;

		theResult = FSSetCatalogInfo(&theRef, kFSCatInfoFinderInfo, &theCatalogInfo)  == noErr;
//		theResult = FSpSetFInfo( &theFSSpec, &theInfo) == noErr;
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



