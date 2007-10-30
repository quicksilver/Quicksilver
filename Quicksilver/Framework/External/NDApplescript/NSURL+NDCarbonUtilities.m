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
 * -finderInfoFlags:type:creator:
 */
- (BOOL)finderInfoFlags:(UInt16*)aFlags type:(OSType*)aType creator:(OSType*)aCreator
{
	FSSpec			theFSSpec;
	struct FInfo	theInfo;

	if( [self getFSSpec:&theFSSpec] && FSpGetFInfo( &theFSSpec, &theInfo) == noErr )
	{
		if( aFlags ) *aFlags = theInfo.fdFlags;
		if( aType ) *aType = theInfo.fdType;
		if( aCreator ) *aCreator = theInfo.fdCreator;

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
	FSSpec			theFSSpec;
	struct FInfo	theInfo;
	NSPoint			thePoint = NSMakePoint( 0, 0 );

	if( [self getFSSpec:&theFSSpec] && FSpGetFInfo( &theFSSpec, &theInfo) == noErr )
	{
		thePoint = NSMakePoint(theInfo.fdLocation.h, theInfo.fdLocation.v );
 	}

	return thePoint;
}

/*
 * -setFinderInfoFlags:mask:type:creator:
 */
- (BOOL)setFinderInfoFlags:(UInt16)aFlags mask:(UInt16)aMask type:(OSType)aType creator:(OSType)aCreator
{
	BOOL				theResult = NO;
	FSSpec			theFSSpec;
	struct FInfo	theInfo = { 0 };

	if( [self getFSSpec:&theFSSpec] && FSpGetFInfo( &theFSSpec, &theInfo) == noErr )
	{
		theInfo.fdFlags = (aFlags & aMask) | (theInfo.fdFlags & !aMask);
		theInfo.fdType = aType;
		theInfo.fdCreator = aCreator;

		theResult = FSpSetFInfo( &theFSSpec, &theInfo) == noErr;
	}

	return theResult;
}

/*
 * -setFinderLocation:
 */
- (BOOL)setFinderLocation:(NSPoint)aLocation
{
	BOOL				theResult = NO;
	FSSpec			theFSSpec;
	struct FInfo	theInfo = { 0 };

	if( [self getFSSpec:&theFSSpec] && FSpGetFInfo( &theFSSpec, &theInfo) == noErr )
	{
		theInfo.fdLocation.h = aLocation.x;
		theInfo.fdLocation.v = aLocation.y;

		theResult = FSpSetFInfo( &theFSSpec, &theInfo) == noErr;
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



