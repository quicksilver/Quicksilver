/*
 *  NSString+NDCarbonUtilities.m category
 *
 *  Created by Nathan Day on Sat Aug 03 2002.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "NSString+NDCarbonUtilities.h"

/*
 * class implementation NSString (NDCarbonUtilities)
 */
@implementation NSString (NDCarbonUtilities)

/*
 * +stringWithFSRef:
 */
+ (NSString *)stringWithFSRef:(const FSRef *)aFSRef
{
	UInt8			thePath[PATH_MAX + 1];		// plus 1 for \0 terminator
	
	return (FSRefMakePath ( aFSRef, thePath, PATH_MAX ) == noErr) ? [NSString stringWithUTF8String:(const char*)thePath] : nil;
}

/*
 * -getFSRef:
 */
- (BOOL)getFSRef:(FSRef *)aFSRef
{
	return FSPathMakeRef( (const UInt8 *)[self UTF8String], aFSRef, NULL ) == noErr;
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
 * -fileSystemPathHFSStyle
 */
- (NSString *)fileSystemPathHFSStyle
{
	return [(NSString *)CFURLCopyFileSystemPath((CFURLRef)[NSURL fileURLWithPath:self], kCFURLHFSPathStyle) autorelease];
}

/*
 * -pathFromFileSystemPathHFSStyle
 */
- (NSString *)pathFromFileSystemPathHFSStyle
{
	return [[(NSURL *)CFURLCreateWithFileSystemPath( kCFAllocatorDefault, (CFStringRef)self, kCFURLHFSPathStyle, [self hasSuffix:@":"] ) autorelease] path];
}

/*
 * -resolveAliasFile
 */
- (NSString *)resolveAliasFile
{
	FSRef			theRef;
	Boolean		theIsTargetFolder,
					theWasAliased;
	NSString		* theResolvedAlias = nil;;

	[self getFSRef:&theRef];

	if( (FSResolveAliasFile( &theRef, YES, &theIsTargetFolder, &theWasAliased ) == noErr) )
	{
		theResolvedAlias = (theWasAliased) ? [NSString stringWithFSRef:&theRef] : self;
	}

	return theResolvedAlias ? theResolvedAlias : self;
}

/*
 * +stringWithPascalString:
 */
+ (NSString *)stringWithPascalString:(const ConstStr255Param )aPStr
{
	return [(NSString*)CFStringCreateWithPascalString( kCFAllocatorDefault, aPStr, kCFStringEncodingMacRomanLatin1 ) autorelease];
}

/*
 * -getPascalString:length:
 */
- (BOOL)getPascalString:(StringPtr)aBuffer length:(short)aLength
{
	return CFStringGetPascalString( (CFStringRef)self, aBuffer, aLength, kCFStringEncodingMacRomanLatin1) != 0;
}

/*
 * -pascalString
 */
- (const char *)pascalString
{
	const unsigned int	kPascalStringLen = 256;
	NSMutableData		* theData = [NSMutableData dataWithCapacity:kPascalStringLen];
	return [self getPascalString:(StringPtr)[theData mutableBytes] length:kPascalStringLen] ? [theData bytes] : NULL;
}

/*
 * -trimWhitespace
 */
- (NSString *)trimWhitespace
{
	CFMutableStringRef 		theString;

	theString = CFStringCreateMutableCopy( kCFAllocatorDefault, 0, (CFStringRef)self);
	CFStringTrimWhitespace( theString );

	return [(NSString *)theString autorelease];
}

/*
 * -finderInfoFlags:type:creator:
 */
- (BOOL)finderInfoFlags:(UInt16*)aFlags type:(OSType*)aType creator:(OSType*)aCreator
{
	FSRef				theFSRef;
	FSCatalogInfo	theCatalogInfo;
	struct FInfo	* theInfo = (struct FInfo*)&theCatalogInfo.finderInfo;

	if( [self getFSRef:&theFSRef] && FSGetCatalogInfo ( &theFSRef, kFSCatInfoFinderInfo, &theCatalogInfo, NULL, NULL, NULL ) == noErr )
	{
		if( aFlags ) *aFlags = theInfo->fdFlags;
		if( aType ) *aType = theInfo->fdType;
		if( aCreator ) *aCreator = theInfo->fdCreator;

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
	FSRef				theFSRef;
	FSCatalogInfo	theCatalogInfo;
	struct FInfo	* theInfo = (struct FInfo*)&theCatalogInfo.finderInfo;
	NSPoint			thePoint = NSMakePoint( 0, 0 );

	if( [self getFSRef:&theFSRef] && FSGetCatalogInfo ( &theFSRef, kFSCatInfoFinderInfo, &theCatalogInfo, NULL, NULL, NULL ) == noErr )
	{
		thePoint = NSMakePoint(theInfo->fdLocation.h, theInfo->fdLocation.v );
	}

	return thePoint;
}

/*
 * -setFinderInfoFlags:mask:type:creator:
 */
- (BOOL)setFinderInfoFlags:(UInt16)aFlags mask:(UInt16)aMask type:(OSType)aType creator:(OSType)aCreator
{
	BOOL				theResult = NO;
	FSRef				theFSRef;
	FSCatalogInfo	theCatalogInfo;
	struct FInfo	* theInfo = (struct FInfo*)&theCatalogInfo.finderInfo;

	if( [self getFSRef:&theFSRef] && FSGetCatalogInfo ( &theFSRef, kFSCatInfoFinderInfo, &theCatalogInfo, NULL, NULL, NULL ) == noErr )
	{
		theInfo->fdFlags = (aFlags & aMask) | (theInfo->fdFlags & !aMask);
		theInfo->fdType = aType;
		theInfo->fdCreator = aCreator;

		theResult = FSSetCatalogInfo( &theFSRef, kFSCatInfoFinderInfo, &theCatalogInfo ) == noErr;
	}

	return theResult;
}

/*
 * -setFinderLocation:
 */
- (BOOL)setFinderLocation:(NSPoint)aLocation
{
	BOOL				theResult = NO;
	FSRef				theFSRef;
	FSCatalogInfo	theCatalogInfo;
	struct FInfo	* theInfo = (struct FInfo*)&theCatalogInfo.finderInfo;

	if( [self getFSRef:&theFSRef] && FSGetCatalogInfo ( &theFSRef, kFSCatInfoFinderInfo, &theCatalogInfo, NULL, NULL, NULL ) == noErr )
	{
		theInfo->fdLocation.h = aLocation.x;
		theInfo->fdLocation.v = aLocation.y;

		theResult = FSSetCatalogInfo( &theFSRef, kFSCatInfoFinderInfo, &theCatalogInfo ) == noErr;
	}

	return theResult;
}

@end





