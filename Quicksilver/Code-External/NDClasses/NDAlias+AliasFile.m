/*
	NDAlias+AliasFile.m category

	Created by Nathan Day on 05.12.01 under a MIT-style license. 
	Copyright (c) 2008-2010 Nathan Day

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

#import "NDAlias+AliasFile.h"
#import "NDResourceFork.h"
#import "NSURL+NDCarbonUtilities.h"
#import "NDResourceFork+OtherSorces.h"

//const ResType	aliasResourceType = 'alis';
const OSType	finderCreatorCode = 0x4D414353; // 'MACS'
const short		aliasRecordId = 0;
//					customIconID = -16496;

@implementation NDAlias (AliasFile)

OSType aliasOSTypeFor( NSURL * aURL );

+ (id)aliasWithContentsOfFile:(NSString *)aPath
{
	return [[[self alloc] initWithContentsOfFile:aPath] autorelease];
}

+ (id)aliasWithContentsOfURL:(NSURL *)aURL
{
	return [[[self alloc] initWithContentsOfURL:aURL] autorelease];
}

- (id)initWithContentsOfFile:(NSString *)aPath
{
	NDResourceFork		* theResourceFork;
	theResourceFork = [[NDResourceFork alloc] initForReadingAtPath:aPath];

	self = [self initWithData:[theResourceFork dataForType:formAlias Id:aliasRecordId]];

	[theResourceFork closeFile];
	[theResourceFork release];

	return self;
}

- (id)initWithContentsOfURL:(NSURL *)aURL
{
	NDResourceFork		* theResourceFork;
	theResourceFork = [[NDResourceFork alloc] initForReadingAtURL:aURL];

	self = [self initWithData:[theResourceFork dataForType:formAlias Id:aliasRecordId]];

	[theResourceFork closeFile];
	[theResourceFork release];

	return self;
}

- (BOOL)writeToFile:(NSString *)aPath
{
	return [self writeToURL:[NSURL fileURLWithPath:aPath] includeCustomIcon:YES];
}

- (BOOL)writeToFile:(NSString *)aPath includeCustomIcon:(BOOL)aCustomIcon
{
	return [self writeToURL:[NSURL fileURLWithPath:aPath] includeCustomIcon:aCustomIcon];
}

- (BOOL)writeToURL:(NSURL *)aURL
{
	return [self writeToURL:(NSURL *)aURL includeCustomIcon:YES];
}

- (BOOL)writeToURL:(NSURL *)aURL includeCustomIcon:(BOOL)aCustomIcon
{
	BOOL				theSuccess;
	NDResourceFork		* theResourceFork;
	
	theResourceFork = [[NDResourceFork alloc] initForWritingAtURL:aURL];
	theSuccess = [theResourceFork addData:[self data] type:formAlias Id:aliasRecordId name:@"created by NDAlias"];

	if( theSuccess )
	{
		UInt16		theFlags;
		OSType		theAliasType,
						theAliasCreator,
						theTargetType,
						theTargetCreator;
		NSURL			* theTargetURL;

		theTargetURL = [self URL];

		[[self URL] finderInfoFlags:&theFlags type:&theTargetType creator:&theTargetCreator];

		theAliasType = aliasOSTypeFor( theTargetURL );	// get the alias type

		if( theAliasType == 0 )	// 0 alias type means doc which just takes the targets type
		{
			theAliasCreator = theTargetCreator;
			theAliasType = theTargetType;
		}
		else	// special alias types take the finder creator code
		{
			theAliasCreator = finderCreatorCode;
		}

		// item with custom icon as well as apps need to have a custoime icon for the alias
		if( aCustomIcon && ((theAliasType == 0 ) || (theFlags & kHasCustomIcon) || (theAliasType == kAppPackageAliasType) || (theAliasType == kApplicationAliasType)) )
		{
			NSData		* theIconFamilyData;
			
			theIconFamilyData = [NDResourceFork iconFamilyDataForURL:theTargetURL];
			
			if( [theResourceFork addData:theIconFamilyData type:kIconFamilyType Id:kCustomIconResource name:@""] )
				[aURL setFinderInfoFlags:kIsAlias | kHasCustomIcon mask:kIsAlias | kHasCustomIcon type:theAliasType creator:theAliasCreator];
		}
		else
		{
			[aURL setFinderInfoFlags:kIsAlias mask:kIsAlias | kHasCustomIcon type:theAliasType creator:theAliasCreator];
		}
	}

	[theResourceFork closeFile];
	[theResourceFork release];
	return theSuccess;
}

OSType aliasOSTypeFor( NSURL * aURL )
{
	LSItemInfoRecord	theItemInfo;
	OSType				theType = kContainerFolderAliasType;
		
	/*
	* alias files to documents take on the targets type and creator
	* alias files to others take on special types and finder creator
	*/
	if( LSCopyItemInfoForURL( (CFURLRef)aURL, kLSRequestBasicFlagsOnly, &theItemInfo) == noErr)
	{
		if( (theItemInfo.flags & kLSItemInfoIsApplication) && (theItemInfo.flags & kLSItemInfoIsPackage) )	// package app
		{
			theType = kAppPackageAliasType;
		}
		else if( theItemInfo.flags & kLSItemInfoIsApplication )	// straight app
		{
			theType = kApplicationAliasType;
		}
		else if( theItemInfo.flags & kLSItemInfoIsPlainFile )	// document
		{
			theType = 0;		// straight documents don't have a special alias type
		}
		else if( theItemInfo.flags & kLSItemInfoIsPackage )	// package
		{
			theType = kPackageAliasType;
		}
		else if( theItemInfo.flags & kLSItemInfoIsVolume )	// disk
		{
			theType = kContainerHardDiskAliasType;
		}
	}

	return theType;
}

@end

