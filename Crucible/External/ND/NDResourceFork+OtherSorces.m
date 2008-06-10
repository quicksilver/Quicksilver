/*
 *  NDResourceFork+OtherSorces.m category
 *  NDResourceFork
 *
 *  Created by Nathan Day on Thu Dec 05 2002.
 *  Copyright 2002-2007 Nathan Day. All rights reserved.
 */

#import "NDResourceFork+OtherSorces.h"
#import "NSURL+NDCarbonUtilities.h"

/*
 * category implementation NDResourceFork (OtherSorces)
 */
@implementation NDResourceFork (OtherSorces)

/*
 * +iconFamilyDataForURL:
 */
+ (NSData *)iconFamilyDataForURL:(NSURL *)aURL
{
	NSData					* theIconFamilyData = nil;
	FSRef					theFSRef;
	IconRef					theIconRef;
	SInt16					theOutLabel;
	IconFamilyHandle		theIconFamilyHandle;
	
	if( [aURL getFSRef:&theFSRef] )
	{
		if( noErr == GetIconRefFromFileInfo( &theFSRef, 0, NULL, kFSCatInfoFinderInfo, NULL, kIconServicesNormalUsageFlag, &theIconRef, &theOutLabel ) )
		{
			if( noErr == IconRefToIconFamily( theIconRef, kSelectorAllAvailableData, &theIconFamilyHandle ) )
			{
				HLock( (Handle)theIconFamilyHandle );
				theIconFamilyData = [NSData dataWithBytes:*theIconFamilyHandle length:GetHandleSize( (Handle)theIconFamilyHandle )];
				HUnlock( (Handle)theIconFamilyHandle );
				
            	DisposeHandle( (Handle)theIconFamilyHandle );
			}

			ReleaseIconRef( theIconRef );
		}
	}

	return theIconFamilyData;
}

/*
 * +iconFamilyDataForFile:
 */
+ (NSData *)iconFamilyDataForFile:(NSString *)aPath
{
	return [self iconFamilyDataForURL:[NSURL fileURLWithPath:aPath]];
}

@end


