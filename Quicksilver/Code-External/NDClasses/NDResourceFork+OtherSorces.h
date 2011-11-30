/*
 *  NDResourceFork+OtherSorces.h category
 *  NDResourceFork
 *
 *  Created by Nathan Day on Thu Dec 05 2002.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import <Cocoa/Cocoa.h>
#import "NDResourceFork.h"

/*!
	@header NDResourceFork(OtherSorces)
	@abstract Defines the interface for a category of the class <TT>NDResourceFork</TT>.
	@discussion Defines method for <TT>NDResourceFork</TT> for retrieving resource type data from non resource fork sources, at lest not directly. The category <TT>OtherSorces</TT> can be omitted from your project if the additonal functionalty is not desired.
 */

/*!
	@category NDResourceFork(OtherSorces)
	@abstract A category of the class <TT>NDResourceFork</TT>.
	@discussion The category <TT>OtherSorces</TT> adds method to <TT>NDResourceFork</TT> for retrieving resource type data from non resource fork sources, at lest not directly. This category can be omitted from your project if the additonal functionalty is not desired.
 */
@interface NDResourceFork (OtherSorces)

/*!
	@method iconFamilyDataForURL:
	@abstract Gets a files or directories Icon Family Data.
	@discussion <TT>iconFamilyDataForURL:</TT> returns the Icon Family Data for any file or directory. The file does not have to have an actual resource fork with the Icon Family Data in it, neither does a directory have to have an Icon/r file with the Icon Family Data.
	@param aURL The file url for which the Icon Family Data is required. 
	@result A <TT>NSData</TT> contain the Icon Family Data, returns <TT>nil</TT> if <TT>iconFamilyDataForURL:</TT> failed.
  */
+ (NSData *)iconFamilyDataForURL:(NSURL *)aURL;
/*!
	@method iconFamilyDataForFile:
	@abstract Gets a files or directories Icon Family Data.
	@discussion <TT>iconFamilyDataForURL:</TT> returns the Icon Family Data for any file or directory. The file does not have to have an actual resource fork with the Icon Family Data in it, neither does a directory have to have an Icon/r file with the Icon Family Data.
	@param aPath The path for which the Icon Family Data is required.
	@result A <TT>NSData</TT> contain the Icon Family Data, returns <TT>nil</TT> if <TT>iconFamilyDataForURL:</TT> failed.
 */
+ (NSData *)iconFamilyDataForFile:(NSString *)aPath;

@end
