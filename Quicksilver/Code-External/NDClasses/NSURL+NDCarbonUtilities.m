/*
	NSURL+NDCarbonUtilities.m

	Created by Nathan Day on 05.12.01 under a MIT-style license. 
	Copyright (c) 2008 Nathan Day

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
 */

#import "NSURL+NDCarbonUtilities.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

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

	/* To support GC and non-GC, we need this contortion. */
	return [NSMakeCollectable(theURL) autorelease];
}

/*
	+ URLWithFileSystemPathHFSStyle:
 */
+ (NSURL *)URLWithFileSystemPathHFSStyle:(NSString *)aHFSString
{
	CFURLRef theURL = CFURLCreateWithFileSystemPath( kCFAllocatorDefault, (CFStringRef)aHFSString, kCFURLHFSPathStyle, [aHFSString hasSuffix:@":"] );

	/* To support GC and non-GC, we need this contortion. */
	return [NSMakeCollectable(theURL) autorelease];
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

	/* To support GC and non-GC, we need this contortion. */
	return [NSMakeCollectable(theURL) autorelease];
}

/*
	- fileSystemPathHFSStyle
 */
- (NSString *)fileSystemPathHFSStyle
{
	CFStringRef	theString = CFURLCopyFileSystemPath((CFURLRef)self, kCFURLHFSPathStyle);

	/* To support GC and non-GC, we need this contortion. */
	return [NSMakeCollectable(theString) autorelease];
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


#pragma clang diagnostic pop