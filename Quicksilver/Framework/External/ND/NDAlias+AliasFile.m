/*
 *  NDAlias+AliasFile.m category
 *  NDAliasProject
 *
 *  Created by Nathan Day on Tue Dec 03 2002.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "NDAlias+AliasFile.h"
#import "NDResourceFork.h"
#import "NSURL+NDCarbonUtilities.h"
#import "NDResourceFork+OtherSorces.h"

//const ResType	aliasResourceType = 'alis';
const OSType	finderCreatorCode = 'MACS';
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
	NDResourceFork		* theResourcFork;
	theResourcFork = [[NDResourceFork alloc] initForReadingAtPath:aPath];

	self = [self initWithData:[theResourcFork dataForType:formAlias Id:aliasRecordId]];

	[theResourcFork release];

	return self;
}

- (id)initWithContentsOfURL:(NSURL *)aURL
{
	NDResourceFork		* theResourcFork;
	theResourcFork = [[NDResourceFork alloc] initForReadingAtURL:aURL];

	self = [self initWithData:[theResourcFork dataForType:formAlias Id:aliasRecordId]];

	[theResourcFork release];

	return self;
}

- (BOOL)writeToFile:(NSString *)aPath
{
	return [self writeToURL:[NSURL fileURLWithPath:aPath]];
}

- (BOOL)writeToURL:(NSURL *)aURL
{
	BOOL					theSuccess;
	NDResourceFork		* theResourcFork;
	
	theResourcFork = [[NDResourceFork alloc] initForWritingAtURL:aURL];
	theSuccess = [theResourcFork addData:[self data] type:formAlias Id:aliasRecordId name:@"created by NDAlias"];

	if( theSuccess )
	{
		UInt16		theFlags;
		OSType		theAliasType,
						theAliasCreator,
						theTargetType,
						theTargetCreator;
		NSURL			* theTargetURL;

		theTargetURL = [self url];

		[[self url] finderInfoFlags:&theFlags type:&theTargetType creator:&theTargetCreator];

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
		if( (theAliasType == 0 ) || (theFlags & kHasCustomIcon) || (theAliasType == kAppPackageAliasType) || (theAliasType == kApplicationAliasType) )
		{
			NSData		* theIconFamilyData;
			
			theIconFamilyData = [NDResourceFork iconFamilyDataForURL:theTargetURL];
			
			if( [theResourcFork addData:theIconFamilyData type:kIconFamilyType Id:kCustomIconResource name:@""] )
				[aURL setFinderInfoFlags:kIsAlias | kHasCustomIcon mask:kIsAlias | kHasCustomIcon type:theAliasType creator:theAliasCreator];
		}
		else
		{
			[aURL setFinderInfoFlags:kIsAlias mask:kIsAlias | kHasCustomIcon type:theAliasType creator:theAliasCreator];
		}
	}

	[theResourcFork release];
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

