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
@implementation NSString (NDCarbonUtilitiesPaths)

/*
 * +stringWithFSRef:
 */
+ (NSString *)stringWithFSRef:(const FSRef *)aFSRef
{
	UInt8			thePath[PATH_MAX + 1];		// plus 1 for \0 terminator
	
	return (FSRefMakePath ( aFSRef, thePath, PATH_MAX ) == noErr) ? [NSString stringWithUTF8String:thePath] : nil;
}

/*
 * -getFSRef:
 */
- (BOOL)getFSRef:(FSRef *)aFSRef
{
	return FSPathMakeRef( [self UTF8String], aFSRef, NULL ) == noErr;
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
 * +stringWithPascalString:encoding:
 */
+ (NSString *)stringWithPascalString:(const ConstStr255Param )aPStr
{
	return (NSString*)CFStringCreateWithPascalString( kCFAllocatorDefault, aPStr, kCFStringEncodingMacRomanLatin1 );
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

	return (NSMutableString *)theString;
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





