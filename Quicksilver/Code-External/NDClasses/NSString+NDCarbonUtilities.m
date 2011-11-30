/*
	NSString+NDCarbonUtilities.m

	Created by Nathan Day on 03.08.02 under a MIT-style license. 
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

#import "NSString+NDCarbonUtilities.h"

/*
 * class implementation NSString (NDCarbonUtilities)
 */
@implementation NSString (NDCarbonUtilities)

/*
	+ stringWithFSRef:
 */
+ (NSString *)stringWithFSRef:(const FSRef *)aFSRef
{
	NSString		* thePath = nil;
	CFURLRef theURL = CFURLCreateFromFSRef( kCFAllocatorDefault, aFSRef );
	if ( theURL )
	{
		thePath = [(NSURL *)theURL path];
		CFRelease ( theURL );
	}
	return thePath;
}

/*
	- getFSRef:
 */
- (BOOL)getFSRef:(FSRef *)aFSRef
{
	return FSPathMakeRef( (const UInt8 *)[self fileSystemRepresentation], aFSRef, NULL ) == noErr;
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
	- fileSystemPathHFSStyle
 */
- (NSString *)fileSystemPathHFSStyle
{
	CFStringRef theString = CFURLCopyFileSystemPath((CFURLRef)[NSURL fileURLWithPath:self], kCFURLHFSPathStyle);

	/* To support GC and non-GC, we need this contortion. */
	return [NSMakeCollectable(theString) autorelease];
}

/*
	- pathFromFileSystemPathHFSStyle
 */
- (NSString *)pathFromFileSystemPathHFSStyle
{
	NSString	* thePath = nil;
	CFURLRef	theURL = CFURLCreateWithFileSystemPath( kCFAllocatorDefault, (CFStringRef)self, kCFURLHFSPathStyle, [self hasSuffix:@":"] );
	if ( theURL )
	{
		thePath = [(NSURL*)theURL path];
		CFRelease( theURL );
	}
	
	return thePath;
}

/*
	- resolveAliasFile
 */
- (NSString *)resolveAliasFile
{
	FSRef			theRef;
	Boolean			theIsTargetFolder,
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
	+ stringWithPascalString:
 */
+ (NSString *)stringWithPascalString:( ConstStr255Param )aPStr
{
	CFStringRef	theString = CFStringCreateWithPascalString( kCFAllocatorDefault, aPStr, kCFStringEncodingMacRomanLatin1 );

	/* To support GC and non-GC, we need this contortion. */
	return [NSMakeCollectable(theString) autorelease];
}

/*
	- getPascalString:length:
 */
- (BOOL)getPascalString:(StringPtr)aBuffer length:(short)aLength
{
	return CFStringGetPascalString( (CFStringRef)self, aBuffer, aLength, kCFStringEncodingMacRomanLatin1) != 0;
}

/*
	- pascalString
 */
- (const char *)pascalString
{
	// Do not use this code in a Garbage Collected application!!!
	// The NSMutableData may be collected before this method even returns (since this method only returns an inner pointer).
#ifdef __OBJC_GC__
	NSLog (@"WARNING: do not use pascalString in GC apps");
#endif
	const unsigned int	kPascalStringLen = 256;
	NSMutableData		* theData = [NSMutableData dataWithCapacity:kPascalStringLen];
	return [self getPascalString:(StringPtr)[theData mutableBytes] length:kPascalStringLen] ? [theData bytes] : NULL;
}

/*
	- trimWhitespace
 */
- (NSString *)trimWhitespace
{
	NSMutableString		* theString = [[self mutableCopy] autorelease];
	CFStringTrimWhitespace( (CFMutableStringRef)theString );

	return theString;
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
	BOOL			theResult = NO;
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
	BOOL			theResult = NO;
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

@implementation NSString (NDCarbonUtilitiesFinderInfoFlags)

- (BOOL)hasCustomIconFinderInfoFlag
{
	UInt16		theFlags = 0;
	return [self finderInfoFlags:&theFlags type:NULL creator:NULL] && (theFlags & kHasCustomIcon) != 0;
}

- (BOOL)isStationeryFinderInfoFlag
{
	UInt16		theFlags = 0;
	return [self finderInfoFlags:&theFlags type:NULL creator:NULL] && (theFlags & kHasCustomIcon) != 0;
}

- (BOOL)hasNameLockedFinderInfoFlag
{
	UInt16		theFlags = 0;
	return [self finderInfoFlags:&theFlags type:NULL creator:NULL] && (theFlags & kNameLocked) != 0;
}

- (BOOL)hasBundleFinderInfoFlag
{
	UInt16		theFlags = 0;
	return [self finderInfoFlags:&theFlags type:NULL creator:NULL] && (theFlags & kHasBundle) != 0;
}

- (BOOL)isInvisibleFinderInfoFlag
{
	UInt16		theFlags = 0;
	return [self finderInfoFlags:&theFlags type:NULL creator:NULL] && (theFlags & kIsInvisible) != 0;
}

- (BOOL)isAliasFinderInfoFlag
{
	UInt16		theFlags = 0;
	return [self finderInfoFlags:&theFlags type:NULL creator:NULL] && (theFlags & kIsAlias) != 0;
}

- (BOOL)setHasCustomIconFinderInfoFlag:(BOOL)aFlag
{
	return [self setFinderInfoFlags:kHasCustomIcon mask:aFlag ? kHasCustomIcon : 0 type:0 creator:0];
}

- (BOOL)setIsStationeryFinderInfoFlag:(BOOL)aFlag
{
	return [self setFinderInfoFlags:kIsStationery mask:aFlag ? kIsStationery : 0 type:0 creator:0];
}

- (BOOL)setHasNameLockedFinderInfoFlag:(BOOL)aFlag
{
	return [self setFinderInfoFlags:kNameLocked mask:aFlag ? kNameLocked : 0 type:0 creator:0];
}

- (BOOL)setHasBundleFinderInfoFlag:(BOOL)aFlag
{
	return [self setFinderInfoFlags:kHasBundle mask:aFlag ? kHasBundle : 0 type:0 creator:0];
}

- (BOOL)setIsInvisibleFinderInfoFlag:(BOOL)aFlag
{
	return [self setFinderInfoFlags:kIsInvisible mask:aFlag ? kIsInvisible : 0 type:0 creator:0];
}

- (BOOL)setIsAliasFinderInfoFlag:(BOOL)aFlag
{
	return [self setFinderInfoFlags:kIsAlias mask:aFlag ? kIsAlias : 0 type:0 creator:0];
}


@end
