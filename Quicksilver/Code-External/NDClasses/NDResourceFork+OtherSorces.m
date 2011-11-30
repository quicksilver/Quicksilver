/*
	NDResourceFork+OtherSorces.h category

	Created by Nathan Day on 05.12.02 under a MIT-style license. 
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
				theIconFamilyData = [NSData dataWithBytes:*theIconFamilyHandle length:GetHandleSize( (Handle)theIconFamilyHandle )];
				
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


