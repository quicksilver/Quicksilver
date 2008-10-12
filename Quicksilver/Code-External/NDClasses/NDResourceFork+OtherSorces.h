/*!
	@header NDResourceFork+OtherSorces
	@abstract Defines the interface for a category of the class <tt>NDResourceFork</tt>.
	@discussion Defines method for <tt>NDResourceFork</tt> for retrieving resource type data from non resource fork sources, at lest not directly. The category <tt>OtherSorces</tt> can be omitted from your project if the additonal functionalty is not desired.
	@copyright &#169; 2007 Nathan Day. All rights reserved.
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
