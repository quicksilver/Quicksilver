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
		theResolvedAlias = (theWasAliased) ? [NSURL URLWithFSRef:&theRef] : nil;
	}

	return theResolvedAlias;
}

@end




