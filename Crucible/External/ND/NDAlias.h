/*!
	@header NDAlias
	@abstract Declare the interface for the class NDAlias.
	@discussion <tt>NDAlias</tt> is a wrapper class for Apples Alias Manager.

	@author Nathan Day
	@date Wed Dec 05 2001
	@copyright &#169; 2001-2008 Nathan Day. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "NDSDKCompatibility.h"

/*!
	@class NDAlias
	@abstract A class to access the Alias Manager from Cocoa 
	@discussion Your application can use a <tt>NDAlias</tt> to refere to file system objects (that is, files, directories, and volumes) in a way that does expect the file system objects path to be maintained. The user then can move or rename the file system object with out your program lossing track of it. This behaviour is not always desirable, for intance with library resources. But for file system objects like documents of user folders, it is what Mac OS users have come to expect.
	@version 1.2
 */
@interface NDAlias : NSObject <NSCoding>
{
	AliasHandle		aliasHandle;
	Boolean			changed;
	unsigned long	mountFlags;
}

/*!
	@functiongroup Creating an alias
 */

/*!
	@method aliasWithURL:
	@abstract Creates and initalises a <tt>NDAlias</tt>.
	@discussion The method <tt>aliasWithURL:</tt> creates an <tt>NDAlias</tt> that contains only the minimum information necessary to describe the target: the target name, the parent directory ID, the volume name and creation date, and the volume mounting information. The <tt>aliasWithURL:</tt> method uses the standard alias record data structure, but it fills in only parts of the record.
	<p>The methods <tt>url</tt> and <tt>path</tt> never update a minimal alias record.</p>
	@param URL the file url for the target of the alias.
	@result A <tt>NDAlias</tt> instance, returns <tt>nil</tt> if <tt>NDAlias</tt> creation fails.
  */
+ (id)aliasWithURL:(NSURL *)URL;
/*!
	@method aliasWithURL:fromURL:
	 @abstract Creates and initalises a <tt>NDAlias</tt>.
	 @discussion  The method <tt>aliasWithURL:fromURL:</tt> creates a <tt>NDAlias</tt> that describes the specified target. <tt>aliasWithURL:fromURL:</tt> always records the name and file or directory ID of the target, its creation date, the parent directory name and ID, and the volume name and creation date. It also records the full pathname of the target and a collection of other information relevant to locating the target, verifying the target, and mounting the target's volume, if necessary. <tt>aliasWithURL:fromURL:</tt> also stores relative path information as well by supplying a starting point for a relative path.
	@param URL the file url for the target of the alias.
	@param fromURL The starting point for a relative path, to be used later in a relative search. The two file or directory url's, <tt>fromURL</tt> and <tt>URL</tt>, must reside on the same volume.
	@result A <tt>NDAlias</tt> instance, returns <tt>nil</tt> if <tt>NDAlias</tt> creation fails.
 */
+ (id)aliasWithURL:(NSURL *)URL fromURL:(NSURL *)fromURL;
/*!
	@method aliasWithPath:
	@abstract Creates and initalises a <tt>NDAlias</tt>.
	@discussion The method <tt>aliasWithPath:</tt> creates an <tt>NDAlias</tt> that contains only the minimum information necessary to describe the target: the target name, the parent directory ID, the volume name and creation date, and the volume mounting information. The <tt>aliasWithPath:</tt> method uses the standard alias record data structure, but it fills in only parts of the record.
	<p>The methods <tt>url</tt> and <tt>path</tt> never update a minimal alias record.</p>
	@param path the path for the target of the alias.
	@result A <tt>NDAlias</tt> instance, returns <tt>nil</tt> if <tt>NDAlias</tt> creation fails.
 */
+ (id)aliasWithPath:(NSString *)path;
/*!
	@method aliasWithPath:fromPath:
	 @abstract Creates and initalises a <tt>NDAlias</tt>.
	 @discussion  The method <tt>aliasWithPath:fromPath:</tt> creates a <tt>NDAlias</tt> that describes the specified target. <tt>aliasWithPath:fromPath:</tt> always records the name and file or directory ID of the target, its creation date, the parent directory name and ID, and the volume name and creation date. It also records the full pathname of the target and a collection of other information relevant to locating the target, verifying the target, and mounting the target's volume, if necessary. <tt>aliasWithPath:fromPath:</tt> also stores relative path information as well by supplying a starting point for a relative path.
	 @param URL the file url for the target of the alias.
	 @param fromPath The starting point for a relative path, to be used later in a relative search. The two file or directory url's, <tt>fromPath</tt> and <tt>URL</tt>, must reside on the same volume.
	 @result A NDAlias instance, returns <tt>nil</tt> if <tt>NDAlias</tt> creation fails.
 */
+ (id)aliasWithPath:(NSString *)path fromPath:(NSString *)fromPath;

/*!
	@method aliasWithData:
	@abstract Creates and initalises a <tt>NDAlias</tt>.
	@discussion The method <tt>aliasWithData:</tt> creates a <tt>NDAlias</tt> that describes the specified target. <tt>aliasWithData:</tt> creates the <tt>NDAlias</tt> from the data that was returned from the method <tt>data</tt>
	@param data The <tt>NSData</tt> instances that contains the data returned previously from the method <tt>data</tt>.
	@result A NDAlias instance, returns <tt>nil</tt> if <tt>NDAlias</tt> creation fails.
  */
+ (id)aliasWithData:(NSData *)data;

/*!
	@method aliasWithFSRef:
	@abstract Creates and initalises a <tt>NDAlias</tt>.
	@discussion The method <tt>aliasWithFSRef:</tt> creates a <tt>NDAlias</tt> that describes the specified target. <tt>aliasWithFSRef:</tt> creates the <tt>NDAlias</tt> from the provided FSRef.
	@param aFSRef An <tt>FSRef</tt> instance that points to the object to make an alias of.
	@result A NDAlias instance, returns <tt>nil</tt> if <tt>NDAlias</tt> creation fails.
  */
+ (id)aliasWithFSRef:(FSRef *)aFSRef;

/*!
	@method initWithURL:
	@abstract Initalises a <tt>NDAlias</tt>.
	@discussion The method <tt>initWithURL:</tt> initalises an <tt>NDAlias</tt> that contains only the minimum information necessary to describe the target: the target name, the parent directory ID, the volume name and creation date, and the volume mounting information. The <tt>initWithURL:</tt> method uses the standard alias record data structure, but it fills in only parts of the record.
	 <p>The methods <tt>url</tt> and <tt>path</tt> never update a minimal alias record.</p>
	@param URL the file url for the target of the alias.
	@result A <tt>NDAlias</tt> instance, returns <tt>nil</tt> if <tt>NDAlias</tt> creation fails.
 */
- (id)initWithURL:(NSURL *)URL;
/*!
	@method initWithPath:fromURL:
	 @abstract Initalises a <tt>NDAlias</tt>.
	 @discussion  The method <tt>initWithPath:fromURL:</tt> initalises a <tt>NDAlias</tt> that describes the specified target. <tt>initWithPath:fromURL:</tt> always records the name and file or directory ID of the target, its creation date, the parent directory name and ID, and the volume name and creation date. It also records the full pathname of the target and a collection of other information relevant to locating the target, verifying the target, and mounting the target's volume, if necessary. <tt>initWithPath:fromURL:</tt> also stores relative path information as well by supplying a starting point for a relative path.
	 @param URL the file url for the target of the alias.
	 @param fromURL The starting point for a relative path, to be used later in a relative search. The two file or directory url's, <tt>fromURL</tt> and <tt>URL</tt>, must reside on the same volume.
	@result An initalised <tt>NDAlias</tt>, returns <tt>nil</tt> if initialisation fails.
 */
- (id)initWithURL:(NSURL *)URL fromURL:(NSURL *)fromURL;
/*!
	@method initWithPath:
	 @abstract Initalises a <tt>NDAlias</tt>.
	 @discussion The method <tt>initWithPath:</tt> initalises an <tt>NDAlias</tt> that contains only the minimum information necessary to describe the target: the target name, the parent directory ID, the volume name and creation date, and the volume mounting information. The <tt>initWithPath:</tt> method uses the standard alias record data structure, but it fills in only parts of the record.
	 <p>The methods <tt>url</tt> and <tt>path</tt> never update a minimal alias record.</p>
	 @param path the path for the target of the alias.
	@result An initalised <tt>NDAlias</tt>, returns <tt>nil</tt> if initialisation fails.
 */
- (id)initWithPath:(NSString *)path;
/*!
	@method initWithPath:fromPath:
	 @abstract Initalises a <tt>NDAlias</tt>.
	 @discussion  The method <tt>initWithPath:fromPath:</tt> initalises a <tt>NDAlias</tt> that describes the specified target. <tt>initWithPath:fromPath:</tt> always records the name and file or directory ID of the target, its creation date, the parent directory name and ID, and the volume name and creation date. It also records the full pathname of the target and a collection of other information relevant to locating the target, verifying the target, and mounting the target's volume, if necessary. <tt>initWithPath:fromPath:</tt> also stores relative path information as well by supplying a starting point for a relative path.
	 @param path the file url for the target of the alias.
	 @param fromPath The starting point for a relative path, to be used later in a relative search. The two file or directory url's, <tt>fromPath</tt> and <tt>path</tt>, must reside on the same volume.
	@result An initalised <tt>NDAlias</tt>, returns <tt>nil</tt> if initialisation fails.
 */
- (id)initWithPath:(NSString *)path fromPath:(NSString *)fromPath;

/*!
	@method initWithData:
	@abstract Initalises a <tt>NDAlias</tt>.
	@discussion The method <tt>initWithData:</tt> initalises a <tt>NDAlias</tt> that describes the specified target. <tt>initWithData:</tt> creates the <tt>NDAlias</tt> from the data that was returned from the method <tt>data</tt>
	@param data The <tt>NSData</tt> instances that contains the data returned previously from the method <tt>data</tt>.
	@result An initalised <tt>NDAlias</tt>, returns <tt>nil</tt> if initialisation fails.
*/
- (id)initWithData:(NSData *)data;

/*!
	@method initWithFSRef:
	@abstract Initalises a <tt>NDAlias</tt>.
	@discussion The method <tt>initWithFSRef:</tt> initalises a <tt>NDAlias</tt> that describes the specified target. <tt>initWithFSRef:</tt> creates the <tt>NDAlias</tt> from the provided FSRef.
	@param aFSRef An <tt>FSRef</tt> instance that points to the object to make an alias of.
	@result An initalised <tt>NDAlias</tt>, returns <tt>nil</tt> if initialisation fails.
*/
- (id)initWithFSRef:(FSRef *)aFSRef;

/*!
	@functiongroup Setting the way the alias is resolved
*/

/*!
	@method setAllowUserInteraction:
	@abstract Option controls how the alias is resolved
	@discussion Sets resolve the alias, presenting a user interface if necessary. By default user interaction is allowed.
	@param flag <tt>YES</tt> to stop any user interaction.
 */
- (void)setAllowUserInteraction:(BOOL)flag;

/*!
	@method setTryFileIDFirst:
	@abstract Option controls how the alias is resolved
	@discussion Search for the alias target using file IDs before searching using the path. By default search by path occurs first.
	@param flag <tt>YES</tt> to resolve the alias by trying file ID first, <tt>NO</tt> to try path first.
 */
- (void)setTryFileIDFirst:(BOOL)flag;

/*!
	@method tryFileIDFirst
	@abstract Option controls how the alias is resolved
	@discussion Search for the alias target using file IDs before searching using the path. By default search by path occurs first.
	@result <tt>YES</tt> to resolve the alias by trying file ID first, <tt>NO</tt> to try path first.
 */
- (BOOL)tryFileIDFirst;
/*!
	@functiongroup Information about an alias
 */

/*!
	@method allowUserInteraction
	@abstract Option controls how the alias is resolved
	@discussion Resolve the alias, presenting a user interface if necessary. By default user interaction is allowed.
	@result Returns <tt>YES</tt> if user interaction is allowed.
 */
- (BOOL)allowUserInteraction;

/*!
	@method changed
	@abstract Reports whether the receiver was updated.
	@discussion The method <tt>changed</tt> indicates whether the receiver was updated because it contained some outdated information about the target. If it the receiver is updated, <tt>YES</tt> is returned. Otherwise, it return <tt>NO</tt>. (<tt>url</tt> and <tt>path</tt> never update a <tt>NDAlias</tt> that was created with no relative path.) 
	@result <tt>YES</tt> if the receiver was updated, <tt>NO</tt> if it was not updated.
  */
- (BOOL)changed;

/*!
	@functiongroup Obtain the path the alias points to.
 */

/*!
	This method is deprecated.  Use -URL instead.  Why?  For consistency with Cocoa classes, which spell it in caps.
  */
- (NSURL *)url DEPRECATED_ATTRIBUTE;
/*!
	@method URL
	@abstract Returns the single most likely target for the receiver.
	@discussion  The <tt>url</tt> method performs a fast search for the target of the receiver. If the resolution is successful, <tt>url</tt> returns a file <tt>NSURL</tt> for the target file system object, updates the receiver if necessary, and reports (through the method <tt>changed</tt>) whether the receiver was updated. If the target is on an unmounted AppleShare volume, <tt>url</tt> automatically mounts the volume. If the target is on an unmounted ejectable volume, <tt>url</tt> asks the user to insert the volume.
	<p>After it identifies a target, <tt>url</tt> compares some key information about the target with the information in the receiver. If the information differs, <tt>url</tt> updates the receiver to match the target.</p>
	<p>The <tt>url</tt> method displays the standard dialog boxes when it needs input from the user, such as a name and password for mounting a remote volume. The user can cancel the resolution through these dialog boxes.</p>
	@result A file <tt>NSURL</tt> to the target of the receiver. <tt>nil</tt> is returned if no target could be found. 
  */
- (NSURL *)URL;
/*!
	@method path
	 @abstract Returns the single most likely target for the receiver.
	 @discussion  The method <tt>path</tt> performs a fast search for the target of the receiver. If the resolution is successful, <tt>path</tt> returns a path <tt>NSString</tt> for the target file system object, updates the receiver if necessary, and reports (through the method <tt>changed</tt>) whether the receiver was updated. If the target is on an unmounted AppleShare volume, <tt>path</tt> automatically mounts the volume. If the target is on an unmounted ejectable volume, <tt>path</tt> asks the user to insert the volume.
	 <p>After it identifies a target, <tt>path</tt> compares some key information about the target with the information in the receiver. If the information differs, <tt>path</tt> updates the receiver to match the target.</p>
	 <p>The <tt>path</tt> method displays the standard dialog boxes when it needs input from the user, such as a name and password for mounting a remote volume. The user can cancel the resolution through these dialog boxes.</p>
	 @result A path <tt>NSString</tt> to the target of the receiver. <tt>nil</tt> is returned if no target could be found.
 */
- (NSString *)path;

/*!
	@functiongroup Update the path of the alias
 */

/*!
	@method setURL:
	 @abstract Updates an the reciever with a new target.
	 @discussion The method <tt>setURL:</tt> rebuilds the entire recievers alias record .
	 @param URL the file url for the target of the alias.
	 @result Returns <tt>YES</tt> if setting the target succeeded, otherwise returns <tt>NO</tt>.
 */
- (BOOL)setURL:(NSURL *)URL;
/*!
	@method setURL:fromURL:
	@abstract Updates an the reciever with a new target.
	@discussion The method <tt>setURL:fromURL:</tt> rebuilds the entire recievers alias record .
	<p>The <tt>setURL:fromURL:</tt> function always creates a complete alias record. When you use <tt>setURL:fromURL:</tt> to update a minimal alias record, you convert the minimal record to a complete record.</p>
	@param URL the file url for the target of the reciever.
	@param fromURL The starting point for a relative path, to be used later in a relative search. The two file or directory url's, <tt>fromURL</tt> and <tt>URL</tt>, must reside on the same volume.
	@result Returns <tt>YES</tt> if setting the target succeeded, otherwise returns <tt>NO</tt>.
  */
- (BOOL)setURL:(NSURL *)URL fromURL:(NSURL *)fromURL;
/*!
	@method setPath:
	@abstract Updates an the reciever with a new target.
	@discussion The method <tt>setPath:</tt> rebuilds the entire recievers alias record .
	@param path the path for the target of the reciever.
	@result Returns <tt>YES</tt> if setting the target succeeded, otherwise returns <tt>NO</tt>.
 */
- (BOOL)setPath:(NSString *)path;
/*!
	@method setURL:fromURL:
	 @abstract Updates an the reciever with a new target.
	 @discussion The method <tt>setURL:fromURL:</tt> rebuilds the entire recievers alias record .
	 <p>The <tt>setURL:fromURL:</tt> function always creates a complete alias record. When you use <tt>setURL:fromURL:</tt> to update a minimal alias record, you convert the minimal record to a complete record.</p>
	 @param path the path for the target of the reciever.
	 @param fromPath The starting point for a relative path, to be used later in a relative search. The two file or directory paths, <tt>fromPath</tt> and <tt>path</tt>, must reside on the same volume.
	 @result Returns <tt>YES</tt> if setting the target succeeded, otherwise returns <tt>NO</tt>.
 */
- (BOOL)setPath:(NSString *)path fromPath:(NSString *)fromPath;

/*!
	@functiongroup Obtain the aliases data
 */

/*!
	@method data
	@abstract Returns a <tt>NSData</tt> instance for the reciever.
	@discussion The method <tt>data</tt> returns the contents of the recievers as an <tt>NSData</tt>, this can be used for archiving perposes though <tt>NDAlias</tt> does implement the <tt>NSCoding</tt> protocol.
	@result Returns an <tt>NSData</tt> instance.
  */
- (NSData *)data;

/*!
	@functiongroup Miscellaneous
 */

/*!
	@method displayName
	@abstract Returns a <tt>NSString</tt> of the receiver's filename in the correct localized form.
	@discussion The method <tt>displayName</tt> returns the filename in the correct localized form, taking into account ':' <-> '/' transformations and localized display names.
	@result Returns an <tt>NSString</tt> instance.
  */
- (NSString *)displayName;

/*!
	@method lastKnownName
	@abstract 
	@discussion 
	@result 
  */
- (NSString *)lastKnownPath;

/*!
	@method lastKnownName
	@abstract 
	@discussion 
	@result 
  */
- (NSString *)lastKnownName;

/*!
	@method resolveIfIsAliasFile
	@abstract 
	@discussion If the receiver points to an alias file and it can be resolved, returns a new <tt>NDAlias</tt> to the original; else returns itself. wasSuccessful will be set to NO if some kind of error occured, such as the receiver being an alias file but unresolvable. If this is not of interest, you may pass NULL. 
	@result 
  */
- (NDAlias *)resolveIfIsAliasFile:(BOOL *)wasSuccessful;

@end
