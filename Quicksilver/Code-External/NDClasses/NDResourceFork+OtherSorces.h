/*
	NDResourceFork+OtherSorces.m category

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

/*!
	@header NDResourceFork+OtherSorces
	@abstract Defines the interface for a category of the class <tt>NDResourceFork</tt>.
	@discussion Defines method for <tt>NDResourceFork</tt> for retrieving resource type data from non resource fork sources, at lest not directly. The category <tt>OtherSorces</tt> can be omitted from your project if the additonal functionalty is not desired.
 */

#import <Cocoa/Cocoa.h>
#import "NDResourceFork.h"
#import "NDSDKCompatibility.h"

/*!
	@category NDResourceFork(OtherSorces)
	@abstract A category of the class <tt>NDResourceFork</tt>.
	@discussion The category <tt>OtherSorces</tt> adds method to <tt>NDResourceFork</tt> for retrieving resource type data from non resource fork sources, at lest not directly. This category can be omitted from your project if the additonal functionalty is not desired.
 */
@interface NDResourceFork (OtherSorces)

/*!
	@method iconFamilyDataForURL:
	@abstract Gets a files or directories Icon Family Data.
	@discussion <tt>iconFamilyDataForURL:</tt> returns the Icon Family Data for any file or directory. The file does not have to have an actual resource fork with the Icon Family Data in it, neither does a directory have to have an Icon/r file with the Icon Family Data.
	@param URL The file url for which the Icon Family Data is required. 
	@result A <tt>NSData</tt> contain the Icon Family Data, returns <tt>nil</tt> if <tt>iconFamilyDataForURL:</tt> failed.
  */
+ (NSData *)iconFamilyDataForURL:(NSURL *)URL;
/*!
	@method iconFamilyDataForFile:
	@abstract Gets a files or directories Icon Family Data.
	@discussion <tt>iconFamilyDataForURL:</tt> returns the Icon Family Data for any file or directory. The file does not have to have an actual resource fork with the Icon Family Data in it, neither does a directory have to have an Icon/r file with the Icon Family Data.
	@param path The path for which the Icon Family Data is required.
	@result A <tt>NSData</tt> contain the Icon Family Data, returns <tt>nil</tt> if <tt>iconFamilyDataForURL:</tt> failed.
 */
+ (NSData *)iconFamilyDataForFile:(NSString *)path;

@end
