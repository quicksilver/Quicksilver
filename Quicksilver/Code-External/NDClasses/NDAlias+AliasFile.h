/*!
	@header NDAlias+AliasFile
	@abstract Defines a category of <tt>NDAlias</tt>
	@discussion The category <tt>NDAlias+AliasFile</tt> add methods for reading and saving alias files.

	@author Nathan Day
	@date Wed Dec 05 2001
	@copyright &#169; 2001-2007 Nathan Day. All rights reserved.
 */

#import <Cocoa/Cocoa.h>
#import "NDAlias.h"
#import "NDSDKCompatibility.h"

/*!
	@category NDAlias(AliasFile)
	@abstract A category of the class <tt>NDAlias</tt>
	@discussion This category add aditional functionality to <tt>NDAlias</tt> for reading and writting <tt>NDAlias</tt> instances to Finder alias files. Though this could be used for archiving purposed, the methods of the adopted protocol <tt>NSCoding</tt> are proble better suited. The method of <tt>NDAlias (AliasFile)</tt> are mainly for creating alias files that are visible in Finder to the user.
	<P>As well as the class <tt>NDAlias</tt> and the classes and categories it uses, <tt>NDAlias (AliasFile)</tt> also requires the class <tt>NDResourceFork</tt> and it's category <tt>NDResourceFork (OtherSorces)</tt>. If the additional functioanlity of <tt>NDAlias (AliasFile)</tt> is not required then the files for <tt>NDAlias (AliasFile)</tt>, <tt>NDResourceFork</tt> and <tt>NDResourceFork (OtherSorces)</tt> can be excluded from your project.</P>
	@helperclass NDResourceFork is requried to read and write to the alias file resource fork.
 */
@interface NDAlias (AliasFile)

/*!
	@functiongroup Creating an alias from an alias file
 */

/*!
	@method aliasWithContentsOfFile:
	@abstract Creates and initalises a <tt>NDAlias</tt>.
	@discussion The method <tt>aliasWithContentsOfFile:</tt> allocates and initalises an <tt>NDAlias</tt> with the alias record data within the Finder alias file pointed to by the <tt>NSString</tt> path <tt>path</tt>.
	@param path the path to an alias file.
	@result A <tt>NDAlias</tt> instance, returns <tt>nil</tt> if <tt>NDAlias</tt> creation fails.
 */
+ (id)aliasWithContentsOfFile:(NSString *)path;
	/*!
  @method aliasWithContentsOfURL:
	@abstract Initalises a <tt>NDAlias</tt>.
	@discussion The method <tt>aliasWithContentsOfURL:</tt> allocates and initalises an <tt>NDAlias</tt> with the alias record data within the Finder <tt>NSURL</tt> alias file pointed to pay the file url <tt>URL</tt>
	@param URL the file url to the alias file.
	@result A <tt>NDAlias</tt> instance, returns <tt>nil</tt> if <tt>NDAlias</tt> creation fails.
 */
+ (id)aliasWithContentsOfURL:(NSURL *)URL;

/*!
	@method initWithContentsOfFile:
	@abstract Initalises a <tt>NDAlias</tt>.
	@discussion The method <tt>initWithContentsOfFile:</tt> initalises the reciever with the alias record data within the Finder alias file pointed to by the <tt>NSString</tt> path <tt>path</tt>
	@param path the path to the alias file.
	@result An initalises <tt>NDAlias</tt>, returns <tt>nil</tt> if initalises fails.
  */
- (id)initWithContentsOfFile:(NSString *)path;
/*!
	@method initWithContentsOfURL:
	@abstract Initalises a <tt>NDAlias</tt>.
	@discussion The method <tt>initWithContentsOfURL:</tt> initalises the reciever with the alias record data within the Finder <tt>NSURL</tt> alias file pointed to pay the file url <tt>URL</tt>.
	@param URL the file url to the alias file.
	@result An initalises <tt>NDAlias</tt>, returns <tt>nil</tt> if initalises fails.
 */
- (id)initWithContentsOfURL:(NSURL *)URL;

/*!
	@functiongroup Create an alias file from an alias
 */

/*!
	@method writeToFile:
	@abstract Writes an <tt>NDAlias</tt> to a Finder alias file.
	@discussion Calls <tt>writeToFile:includeCustomIcon:</tt> with the parameter <tt><i>customIcon</i></tt> set to <tt><i>YES</i></tt>.
	@param path the path for the alias file. Not the path the alias record represents.
	@result <#result#>
  */
- (BOOL)writeToFile:(NSString *)path;
/*!
	@method writeToFile:includeCustomIcon:
	@abstract Writes an <tt>NDAlias</tt> to a Finder alias file.
	@discussion The method <tt>writeToFile:</tt> writes the alias record data contained within the reciever to a Finder alias file at the path <tt>path</tt>. <tt>writeToFile:</tt> can be used to create alias files that the user can see in Finder and use. If the target file of for the alias has a custom icon or is an application then the <tt><i>customIcon</i></tt> can be used to included a custom icon for the alias identical to the target.
	@param path the path for the alias file. Not the path the alias record represents.
	@param customIcon inlcude custom icon if required.
	@result <#result#>
  */
- (BOOL)writeToFile:(NSString *)path includeCustomIcon:(BOOL)customIcon;
/*!
	@method writeToURL:
	@abstract Writes an <tt>NDAlias</tt> to a Finder alias file.
	@discussion Calls <tt>writeToFile:includeCustomIcon:</tt> with the parameter <tt><i>customIcon</i></tt> set to <tt><i>YES</i></tt>.
	@param URL the file url for the alias file. Not the file url the alias record represents.
	@result <#result#>
 */
- (BOOL)writeToURL:(NSURL *)URL;
/*!
	@method writeToURL:includeCustomIcon:
	@abstract Writes an <tt>NDAlias</tt> to a Finder alias file.
	@discussion The method <tt>writeToURL:</tt> writes the alias record data contained within the reciever to a Finder alias file at the file url <tt>URL</tt>. <tt>writeToFile:</tt> can be used to create alias files that the user can see in Finder and use.. If the target file of for the alias has a custom icon or is an application then the <tt><i>customIcon</i></tt> can be used to included a custom icon for the alias identical to the target.
	@param URL the file url for the alias file. Not the file url the alias record represents.
	@param customIcon inlcude custom icon if required.
	@result <#result#>
 */
- (BOOL)writeToURL:(NSURL *)URL includeCustomIcon:(BOOL)customIcon;

@end
