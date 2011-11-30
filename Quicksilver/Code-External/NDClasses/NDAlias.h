/*
	NDAlias.h

	Created by Nathan Day on 05.12.01 under a MIT-style license.
	Copyright (c) 2008-2011 Nathan Day

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
	@header NDAlias
	@abstract Declare the interface for the class NDAlias.
	@discussion <tt>NDAlias</tt> is a wrapper class for Apple's Alias Manager.

	@author Nathan Day
	@date Wed Dec 05 2001
 */

#import <Foundation/Foundation.h>
#import "NDSDKCompatibility.h"

/*!
	@class NDAlias
	@abstract A class to access the Alias Manager from Cocoa.
	@discussion Your application can use an <tt>NDAlias</tt> to refer to file system objects (that is, files, directories, and volumes) in a way that does expect the file system object's path to be maintained. The user then can move or rename the file system object without your program losing track of it. This behaviour is not always desirable, for instance with library resources. But for file system objects like documents or user folders, it is what Mac OS users have come to expect.
	@version 1.3
 */
@interface NDAlias : NSObject <NSCoding>
{
@private
	AliasHandle		aliasHandle;
	Boolean			changed;
	unsigned long	mountFlags;
}

/*!
	@functiongroup Creating an alias
 */

/*!
	@method aliasWithURL:
	@abstract Creates and initalises an <tt>NDAlias</tt>.
	@discussion The method <tt>aliasWithURL:</tt> creates an <tt>NDAlias</tt> that contains only the minimum information necessary to describe the target: the target name, the parent directory ID, the volume name and creation date, and the volume mounting information. The <tt>aliasWithURL:</tt> method uses the standard alias record data structure, but it fills in only parts of the record.
	<p>The methods <tt>URL</tt> and <tt>path</tt> never update a minimal alias record.</p>
	@param URL the file url for the target of the alias.
	@result An <tt>NDAlias</tt> instance, returns <tt>nil</tt> if <tt>NDAlias</tt> creation fails.
  */
+ (id)aliasWithURL:(NSURL *)URL;
/*!
	@method aliasWithURL:fromURL:
	 @abstract Creates and initalises an <tt>NDAlias</tt>.
	 @discussion  The method <tt>aliasWithURL:fromURL:</tt> creates an <tt>NDAlias</tt> that describes the specified target. <tt>aliasWithURL:fromURL:</tt> always records the name and file or directory ID of the target, its creation date, the parent directory name and ID, and the volume name and creation date. It also records the full pathname of the target and a collection of other information relevant to locating the target, verifying the target, and mounting the target's volume, if necessary. <tt>aliasWithURL:fromURL:</tt> also stores relative path information as well by supplying a starting point for a relative path.
	@param URL the file url for the target of the alias.
	@param fromURL The starting point for a relative path, to be used later in a relative search. The two file or directory url's, <tt>fromURL</tt> and <tt>URL</tt>, must reside on the same volume.
	@result An <tt>NDAlias</tt> instance, returns <tt>nil</tt> if <tt>NDAlias</tt> creation fails.
 */
+ (id)aliasWithURL:(NSURL *)URL fromURL:(NSURL *)fromURL;
/*!
	@method aliasWithPath:
	@abstract Creates and initalises an <tt>NDAlias</tt>.
	@discussion The method <tt>aliasWithPath:</tt> creates an <tt>NDAlias</tt> that contains only the minimum information necessary to describe the target: the target name, the parent directory ID, the volume name and creation date, and the volume mounting information. The <tt>aliasWithPath:</tt> method uses the standard alias record data structure, but it fills in only parts of the record.
	<p>The methods <tt>URL</tt> and <tt>path</tt> never update a minimal alias record.</p>
	@param path the path for the target of the alias.
	@result An <tt>NDAlias</tt> instance, returns <tt>nil</tt> if <tt>NDAlias</tt> creation fails.
 */
+ (id)aliasWithPath:(NSString *)path;
/*!
	@method aliasWithPath:fromPath:
	 @abstract Creates and initalises an <tt>NDAlias</tt>.
	 @discussion  The method <tt>aliasWithPath:fromPath:</tt> creates an <tt>NDAlias</tt> that describes the specified target. <tt>aliasWithPath:fromPath:</tt> always records the name and file or directory ID of the target, its creation date, the parent directory name and ID, and the volume name and creation date. It also records the full pathname of the target and a collection of other information relevant to locating the target, verifying the target, and mounting the target's volume, if necessary. <tt>aliasWithPath:fromPath:</tt> also stores relative path information as well by supplying a starting point for a relative path.
	 @param URL the file url for the target of the alias.
	 @param fromPath The starting point for a relative path, to be used later in a relative search. The two file or directory url's, <tt>fromPath</tt> and <tt>URL</tt>, must reside on the same volume.
	 @result A NDAlias instance, returns <tt>nil</tt> if <tt>NDAlias</tt> creation fails.
 */
+ (id)aliasWithPath:(NSString *)path fromPath:(NSString *)fromPath;

/*!
	@method aliasWithData:
	@abstract Creates and initalises an <tt>NDAlias</tt>.
	@discussion The method <tt>aliasWithData:</tt> creates an <tt>NDAlias</tt> that describes the specified target. <tt>aliasWithData:</tt> creates the <tt>NDAlias</tt> from the data that was returned from the method <tt>data</tt>
	@param data The <tt>NSData</tt> instances that contains the data returned previously from the method <tt>data</tt>.
	@result A NDAlias instance, returns <tt>nil</tt> if <tt>NDAlias</tt> creation fails.
  */
+ (id)aliasWithData:(NSData *)data;

/*!
	@method aliasWithFSRef:
	@abstract Creates and initalises an <tt>NDAlias</tt>.
	@discussion The method <tt>aliasWithFSRef:</tt> creates an <tt>NDAlias</tt> that describes the specified target. <tt>aliasWithFSRef:</tt> creates the <tt>NDAlias</tt> from the provided FSRef.
	@param aFSRef An <tt>FSRef</tt> instance that points to the object to make an alias of.
	@result A NDAlias instance, returns <tt>nil</tt> if <tt>NDAlias</tt> creation fails.
  */
+ (id)aliasWithFSRef:(FSRef *)aFSRef;

/*!
	@method initWithURL:
	@abstract Initalises an <tt>NDAlias</tt>.
	@discussion The method <tt>initWithURL:</tt> initalises an <tt>NDAlias</tt> that contains only the minimum information necessary to describe the target: the target name, the parent directory ID, the volume name and creation date, and the volume mounting information. The <tt>initWithURL:</tt> method uses the standard alias record data structure, but it fills in only parts of the record.
	 <p>The methods <tt>URL</tt> and <tt>path</tt> never update a minimal alias record.</p>
	@param URL the file url for the target of the alias.
	@result An <tt>NDAlias</tt> instance, returns <tt>nil</tt> if <tt>NDAlias</tt> creation fails.
 */
- (id)initWithURL:(NSURL *)URL;
/*!
	@method initWithPath:fromURL:
	 @abstract Initalises an <tt>NDAlias</tt>.
	 @discussion  The method <tt>initWithPath:fromURL:</tt> initalises an <tt>NDAlias</tt> that describes the specified target. <tt>initWithPath:fromURL:</tt> always records the name and file or directory ID of the target, its creation date, the parent directory name and ID, and the volume name and creation date. It also records the full pathname of the target and a collection of other information relevant to locating the target, verifying the target, and mounting the target's volume, if necessary. <tt>initWithPath:fromURL:</tt> also stores relative path information as well by supplying a starting point for a relative path.
	 @param URL the file url for the target of the alias.
	 @param fromURL The starting point for a relative path, to be used later in a relative search. The two file or directory url's, <tt>fromURL</tt> and <tt>URL</tt>, must reside on the same volume.
	@result An initalised <tt>NDAlias</tt>, returns <tt>nil</tt> if initialisation fails.
 */
- (id)initWithURL:(NSURL *)URL fromURL:(NSURL *)fromURL;
/*!
	@method initWithPath:
	 @abstract Initalises an <tt>NDAlias</tt>.
	 @discussion The method <tt>initWithPath:</tt> initalises an <tt>NDAlias</tt> that contains only the minimum information necessary to describe the target: the target name, the parent directory ID, the volume name and creation date, and the volume mounting information. The <tt>initWithPath:</tt> method uses the standard alias record data structure, but it fills in only parts of the record.
	 <p>The methods <tt>URL</tt> and <tt>path</tt> never update a minimal alias record.</p>
	 @param path the path for the target of the alias.
	@result An initalised <tt>NDAlias</tt>, returns <tt>nil</tt> if initialisation fails.
 */
- (id)initWithPath:(NSString *)path;
/*!
	@method initWithPath:fromPath:
	 @abstract Initalises an <tt>NDAlias</tt>.
	 @discussion  The method <tt>initWithPath:fromPath:</tt> initalises an <tt>NDAlias</tt> that describes the specified target. <tt>initWithPath:fromPath:</tt> always records the name and file or directory ID of the target, its creation date, the parent directory name and ID, and the volume name and creation date. It also records the full pathname of the target and a collection of other information relevant to locating the target, verifying the target, and mounting the target's volume, if necessary. <tt>initWithPath:fromPath:</tt> also stores relative path information as well by supplying a starting point for a relative path.
	 @param path the file url for the target of the alias.
	 @param fromPath The starting point for a relative path, to be used later in a relative search. The two file or directory url's, <tt>fromPath</tt> and <tt>path</tt>, must reside on the same volume.
	@result An initalised <tt>NDAlias</tt>, returns <tt>nil</tt> if initialisation fails.
 */
- (id)initWithPath:(NSString *)path fromPath:(NSString *)fromPath;

/*!
	@method initWithData:
	@abstract The designated initializer. Initalises an <tt>NDAlias</tt>.
	@discussion The method <tt>initWithData:</tt> initalises an <tt>NDAlias</tt> that describes the specified target. The NSData must be a flattened <tt>AliasHandle</tt>, which is also the format returned by the <tt>data</tt> method.
	@param data The <tt>NSData</tt> instances that contains the data returned previously from the method <tt>data</tt>.
	@result An initalised <tt>NDAlias</tt>, returns <tt>nil</tt> if initialisation fails.
*/
- (id)initWithData:(NSData *)data;

/*!
	@method initWithFSRef:
	@abstract Initalises an <tt>NDAlias</tt>.
	@discussion The method <tt>initWithFSRef:</tt> initalises an <tt>NDAlias</tt> that describes the specified target. <tt>initWithFSRef:</tt> creates the <tt>NDAlias</tt> from the provided FSRef.
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
	@discussion Sets whether the OS may present a user interface when resolving the receiver. By default, as of version 1.3, user interaction is not allowed. In previous versions, the default was to allow user interaction.
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
	@discussion Gets whether the OS may present a user interface when resolving the receiver. By default, as of version 1.3, user interaction is not allowed. In previous versions, the default was to allow user interaction.
	@result Returns <tt>YES</tt> if user interaction is allowed.
 */
- (BOOL)allowUserInteraction;

/*!
	@method changed
	@abstract Reports whether the receiver was updated.
	@discussion The method <tt>changed</tt> indicates whether the receiver was updated because it contained some outdated information about the target. If it the receiver is updated, <tt>YES</tt> is returned. Otherwise, it return <tt>NO</tt>. (<tt>URL</tt> and <tt>path</tt> never update an <tt>NDAlias</tt> that was created with no relative path.)
	@result <tt>YES</tt> if the receiver was updated, <tt>NO</tt> if it was not updated.
  */
- (BOOL)changed;

/*!
	@functiongroup Obtain the path the alias points to.
 */

/*!
	@method getFSRef:
	@abstract Get a <tt>FSRef</tt> for the receiver.
	@discussion Initializes an <tt>FSRef</tt>.
	@param fsRef a pointer to a <tt>FSRef</tt>.
	@result Returns <tt>YES</tt> if the method was successful, if the function returns <tt>NO</tt> then the <tt>FSRef</tt> pointed to by <tt>fsRef</tt> is garbage.
  */
- (BOOL)getFSRef:(FSRef *)aFsRef;

/*!
	This method is deprecated.  Use -URL instead.  Why?  For consistency with Cocoa classes, which spell it in caps.
  */
- (NSURL *)url DEPRECATED_ATTRIBUTE;
/*!
	@method URL
	@abstract Returns the single most likely target for the receiver.
	@discussion  The <tt>URL</tt> method performs a fast search for the target of the receiver. If the resolution is successful, <tt>URL</tt> returns a file <tt>NSURL</tt> for the target file system object, updates the receiver if necessary, and reports (through the method <tt>changed</tt>) whether the receiver was updated. If the target is on an unmounted AppleShare volume, <tt>URL</tt> automatically mounts the volume. If the target is on an unmounted ejectable volume, <tt>URL</tt> asks the user to insert the volume.
	<p>After it identifies a target, <tt>URL</tt> compares some key information about the target with the information in the receiver. If the information differs, <tt>URL</tt> updates the receiver to match the target.</p>
	<p>The <tt>URL</tt> method displays the standard dialog boxes when it needs input from the user, such as a name and password for mounting a remote volume. The user can cancel the resolution through these dialog boxes.</p>
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
	 @discussion The method <tt>setURL:</tt> rebuilds the entire reciever's alias record .
	 @param URL the file url for the target of the alias.
	 @result Returns <tt>YES</tt> if setting the target succeeded, otherwise returns <tt>NO</tt>.
 */
- (BOOL)setURL:(NSURL *)URL;
/*!
	@method setURL:fromURL:
	@abstract Updates an the reciever with a new target.
	@discussion The method <tt>setURL:fromURL:</tt> rebuilds the entire reciever's alias record .
	<p>The <tt>setURL:fromURL:</tt> function always creates a complete alias record. When you use <tt>setURL:fromURL:</tt> to update a minimal alias record, you convert the minimal record to a complete record.</p>
	@param URL the file url for the target of the reciever.
	@param fromURL The starting point for a relative path, to be used later in a relative search. The two file or directory url's, <tt>fromURL</tt> and <tt>URL</tt>, must reside on the same volume.
	@result Returns <tt>YES</tt> if setting the target succeeded, otherwise returns <tt>NO</tt>.
  */
- (BOOL)setURL:(NSURL *)URL fromURL:(NSURL *)fromURL;
/*!
	@method setPath:
	@abstract Updates an the reciever with a new target.
	@discussion The method <tt>setPath:</tt> rebuilds the entire reciever's alias record .
	@param path the path for the target of the reciever.
	@result Returns <tt>YES</tt> if setting the target succeeded, otherwise returns <tt>NO</tt>.
 */
- (BOOL)setPath:(NSString *)path;
/*!
	@method setURL:fromURL:
	 @abstract Updates an the reciever with a new target.
	 @discussion The method <tt>setURL:fromURL:</tt> rebuilds the entire reciever's alias record .
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
	@discussion The method <tt>data</tt> returns an <tt>NSData</tt> representation of the reciever's <tt>AliasHandle</tt>, this can be used for archiving purposes since <tt>NDAlias</tt> does implement the <tt>NSCoding</tt> protocol.
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
	@method lastKnownPath
	@abstract Return path from an alias record
	@discussion This method returns the path from the alias record. The information is gathered only from the alias record, so it may not match what is on disk. No disk input/output is performed.
  */
- (NSString *)lastKnownPath;

/*!
	@method lastKnownName
	@abstract Return name from an alias record
	@discussion This method returns the name from the alias record. The information is gathered only from the alias record, so it may not match what is on disk. No disk input/output is performed.
  */
- (NSString *)lastKnownName;

/*!
	@method lastKnownVolumeName
	@abstract Return volume from an alias record
	@discussion This method returns the volume from the alias record. The information is gathered only from the alias record, so it may not match what is on disk. No disk input/output is performed.
	@result <#result#>
  */
- (NSString *)lastKnownVolumeName;

/*!
	@method resolveIfIsAliasFile
	@abstract Resolve alias file target.
	@discussion If the receiver points to an alias file and it can be resolved, returns a new <tt>NDAlias</tt> to the original; else returns itself. wasSuccessful will be set to NO if some kind of error occured, such as the receiver being an alias file but unresolvable. If this is not of interest, you may pass NULL.
	@result A new NDAlias or the reserver
  */
- (NDAlias *)resolveIfIsAliasFile:(BOOL *)wasSuccessful;

/*!
	@method isEqualToAlias:
	@abstract Test alias equality
	@discussion Returns YES if the receiver is equal to the passed object. Two NDAliases are defined as equal if and only if they resolve to equal FSRefs.  Alias resolution is performed on both aliases, if there is any error, NO is returned.
  */
- (BOOL)isEqualToAlias:(id)anOtherObject;

/*!
	@method isAliasCollectionResolvable:
	@abstract Tests if all NDAliases in the collection (ex: NSArray or NSSet) can be resolved.
	@discussion Returns YES if and only if each alias can be resolved, returns NO otherwise.
  */
+ (BOOL)isAliasCollectionResolvable:(NSObject<NSFastEnumeration>*)aCollection;

/*!
	@method isAliasCollection:equalToAliasCollection:
	@abstract Tests if two collections (NSArray or NSSet) of NDAliases are the same.
	@discussion Returns YES if and only if each collection has the same number of items and each item of one collection matches (according to isEqualToAlias:) an item in the other collection.
  */
+ (BOOL)isAliasCollection:(id)aCollection1 equalToAliasCollection:(id)aCollection2;

/*!
	@method arrayOfAliasesFromArrayOfData:
	@abstract Returns an NSArray of NDAliases from the given NSArray of NSData.
	@discussion The given NSData is expected to be an archived NDAlias.  Never returns nil; but, if errors occur, may return less items (down to 0) than the given array.
  */
+ (NSArray*)arrayOfAliasesFromArrayOfData:(NSArray*)aDataArray;

/*!
	@method arrayOfDataFromArrayOfAliases:
	@abstract Returns an NSArray of NSData from the given NSArray of NDAlias.
	@discussion The created NSData are archived NDAliases.  Never returns nil; but, if errors occur, may return less items (down to 0) than the given array.
  */
+ (NSArray*)arrayOfDataFromArrayOfAliases:(NSArray*)anAliasArray;

@end
