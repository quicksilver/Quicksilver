/*
	NSString+NDCarbonUtilities.h

	Created by Nathan Day on 03.08.02 under a MIT-style license. 
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
	@header NSString+NDCarbonUtilities
	@abstract Decalres the category <tt>NSString (NDCarbonUtilities)</tt>
	@discussion Provides method for interacting with Carbon APIs.
	@author Nathan Day
 */

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import "NDSDKCompatibility.h"

/*!
	@category NSString(NDCarbonUtilities)
	@abstract Provides method for interacting with Carbon APIs.
	@discussion Methods for dealing with <tt>FSRef</tt>&rsquo;s and pascal string as well as making some other core foundation methods accessable in Objective-C syntax.
 */
@interface NSString (NDCarbonUtilities)

/*!
	@method stringWithFSRef:
	@abstract Alloc and initialize an <tt>NSString</tt>.
	@discussion Creats a <tt>NSString</tt> containing a POSIX style path from a <tt>FSRef</tt>
	@param fsRef a pointer to a <tt>FSRef</tt>.
	@result A <tt>NSString</tt> containing a POSIX path.
  */
+ (NSString *)stringWithFSRef:(const FSRef *)fsRef;
/*!
	@method getFSRef:
	@abstract Get a <tt>FSRef</tt> for a path <tt>NSString</tt>.
	@discussion Initializes an <tt>FSRef</tt> for a POSIX style path <tt>NSString</tt>.
	@param fsRef a pointer to a <tt>FSRef</tt>.
	@result Return <tt>YES</tt> if the method was successful, if the function returns <tt>NO</tt> then the <tt>FSRef</tt> pointed to by <tt>fsRef</tt> is garbage.
  */
- (BOOL)getFSRef:(FSRef *)fsRef;

/*!
	@method getFSSpec:
	@abstract Get a <tt>FSSpec</tt>.
	@discussion Obtain a <tt>FSSpec</tt> for a POSIX path.
	@deprecated in version 10.5
	@param fsSpec A pointer to a <tt>FSSpec</tt> struct, to be filled by the method.
	@result Returns <tt>YES</tt> if successful, if the method returns <tt>NO</tt> then <tt>fsSpec</tt> contains garbage.
 */
- (BOOL)getFSSpec:(FSSpec *)fsSpec AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED;

/*!
	@method fileSystemPathHFSStyle
	@abstract Returns a HFS style path.
	@discussion Returns a <tt>NSString</tt> containg a HFS style path (e.g. <tt>Macitosh HD:Users:</tt>) useful for display purposes.
	@result A new <tt>NSString</tt> containing a HFS style path for the same file or directory as the receiver.
 */
- (NSString *)fileSystemPathHFSStyle;
/*!
	@method pathFromFileSystemPathHFSStyle
	@abstract Get a path from a HFS style path.
	@discussion <tt>pathFromFileSystemPathHFSStyle</tt> returns a POSIX style path from a HFS style path.
	@result A <tt>NSString</tt> containing a POSIX style path.
  */
- (NSString *)pathFromFileSystemPathHFSStyle;
/*!
	@method resolveAliasFile
	@abstract Resolve an alias file.
	@discussion Returns an POSIX path <tt>NSString</tt> refered to by the receveive if the receveive refers to an alias file. If it does not refer to an alias file the a string identical to the receveive is returned.
	@result An POSIX path <tt>NSString</tt>.
  */
- (NSString *)resolveAliasFile;

/*!
	@method stringWithPascalString:
	@abstract Alloc and initialize an <tt>NSString</tt>.
	@discussion Reurns a new <tt>NSString</tt> equivelent to the passed in pascal string.
	@param pStr A pascal string of type <tt>ConstStr255Param</tt>.
	@result A <tt>NSString</tt>.
 */
+ (NSString *)stringWithPascalString:(ConstStr255Param)pStr;

/*!
	@method getPascalString:length:
	@abstract Obtain a pascal string equivelent to the receveiver.
	@discussion Fill the <tt>StringPtr</tt> with a pascal string equivelent to the receveiver.
	@param buffer A <tt>StringPtr</tt> that contains the pascal string on completion.
	@param length The maximum length the string can be. Pascal string can be no longer than <tt>255</tt> bytes long, <tt>256</tt> if you include the first length byte.
	@result Returns <tt>YES</tt> if the method was successful, if <tt>NO</tt> is returns then <tt>buffer</tt> contains garbage.
 */
- (BOOL)getPascalString:(StringPtr)buffer length:(short)length;

/*!
	@method pascalString
	@abstract Obtain a pascal string equivelent to the receveiver.
	@discussion  Returns a representation of the receiver as a pascal string. The returned pascal string will be automatically freed just as a returned object would be released; your code should copy the pascal string or use <tt>getPascalString:length:</tt> if it needs to store the pascal string outside of the autorelease context in which the pascal string is create.
	@deprecated in version 10.5
	@result A pointer to a pascal string.
 */
- (const char *)pascalString AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED;

/*!
	@method trimWhitespace
	@abstract Trims white space from a <tt>NSString</tt>.
	@discussion Returns a new <tt>NSString</tt> equivelent to the receveiver but without any white space (return, new line, space, tab) at the begining or end of the string.
	@result A new <tt>NSString</tt>.
 */
- (NSString *)trimWhitespace;
/*!
	@method finderInfoFlags:type:creator:
	@abstract Get finder info flags creator and type.
	@discussion The bits of the finder info flag are
	<blockquote>
		<table border = "1"  width = "90%">
			<thead><tr><th>Name</th><th>Description</th></tr></thead>
			<tr><td align = "center"><tt>kIsOnDesk</tt></td><td>Files and folders (System 6)</td><tr>
			<tr><td align = "center"><tt>kColor</tt></td><td>Files and folders</td><tr>
			<tr><td align = "center"><tt>kIsShared</tt></td><td>Files only (Applications only)<br>
					If clear, the application needs to write to its resource fork, and therefore cannot be shared on a server</td><tr>
			<tr><td align = "center"><tt>kHasNoINITs</tt></td><td>Files only (Extensions/Control Panels only)<br>
					This file contains no INIT resource</td><tr>
			<tr><td align = "center"><tt>kHasBeenInited</tt></td><td>Files only<br>
					Clear if the file contains desktop database resources ('BNDL', 'FREF', 'open', 'kind'...) that have not been added yet. Set only by the Finder</td><tr>
			<tr><td align = "center"><tt>kHasCustomIcon</tt></td><td>Files and folders</td><tr>
			<tr><td align = "center"><tt>kIsStationery</tt></td><td>Files only</td><tr>
			<tr><td align = "center"><tt>kNameLocked</tt></td><td>Files and folders</td><tr>
			<tr><td align = "center"><tt>kHasBundle</tt></td><td>Files only</td><tr>
			<tr><td align = "center"><tt>kIsInvisible</tt></td><td>Files and folders</td><tr>
			<tr><td align = "center"><tt>kIsAlias</tt></td><td>Files only.</td><tr>
		</table>
	</blockquote>
	@param flags Contains finder flags on return.
	@param type Contains finder type on return.
	@param creator Contains creator on return.
	@result Return <tt>YES</tt> if successful, otherwise <tt>NO</tt> and the returned values are invalid.
 */
- (BOOL)finderInfoFlags:(UInt16*)flags type:(OSType*)type creator:(OSType*)creator;

/*!
	@method finderLocation
	@abstract Return a finder items location.
	@discussion Returns a finder items location within its parent window.
	@result A <tt>NSPoint</tt>
 */
- (NSPoint)finderLocation;

/*!
	@method setFinderInfoFlags:mask:type:creator:
	@abstract Set finder info flags, creator and type.
	@discussion The bits of the finder info flag are
	<blockquote>
		<table border = "1"  width = "90%">
			<thead><tr><th>Name</th><th>Description</th></tr></thead>
			<tr><td align = "center"><tt>kIsOnDesk</tt></td><td>Files and folders (System 6)</td><tr>
			<tr><td align = "center"><tt>kColor</tt></td><td>Files and folders</td><tr>
			<tr><td align = "center"><tt>kIsShared</tt></td><td>Files only (Applications only)<br>
					If clear, the application needs to write to its resource fork, and therefore cannot be shared on a server</td><tr>
			<tr><td align = "center"><tt>kHasNoINITs</tt></td><td>Files only (Extensions/Control Panels only)<br>
					This file contains no INIT resource</td><tr>
			<tr><td align = "center"><tt>kHasBeenInited</tt></td><td>Files only<br>
					Clear if the file contains desktop database resources ('BNDL', 'FREF', 'open', 'kind'...) that have not been added yet. Set only by the Finder</td><tr>
			<tr><td align = "center"><tt>kHasCustomIcon</tt></td><td>Files and folders</td><tr>
			<tr><td align = "center"><tt>kIsStationery</tt></td><td>Files only</td><tr>
			<tr><td align = "center"><tt>kNameLocked</tt></td><td>Files and folders</td><tr>
			<tr><td align = "center"><tt>kHasBundle</tt></td><td>Files only</td><tr>
			<tr><td align = "center"><tt>kIsInvisible</tt></td><td>Files and folders</td><tr>
			<tr><td align = "center"><tt>kIsAlias</tt></td><td>Files only.</td><tr>
		</table>
	</blockquote>
	@param flags Finder flags.
	@param aMask Mask for Finder flags
	@param type The Finder file type
	@param creator The application creator code
	@result Returns <tt>YES</tt> if successful.
 */
- (BOOL)setFinderInfoFlags:(UInt16)flags mask:(UInt16)aMask type:(OSType)type creator:(OSType)creator;

/*!
	@method setFinderLocation:
	@abstract Sets the location a finder item.
	@discussion Set the location of a finder item within in container.
	@param location The location
	@result Returns <tt>YES</tt> if successful.
 */
- (BOOL)setFinderLocation:(NSPoint)location;

@end

@interface NSString (NDCarbonUtilitiesFinderInfoFlags)

/*!
	@method hasCustomIconFinderInfoFlag
	@abstract <#abstract#>
	@discussion <#discussion#>
	@result <#result#>
 */
- (BOOL)hasCustomIconFinderInfoFlag;
/*!
	@method isStationeryFinderInfoFlag
	@abstract <#abstract#>
	@discussion <#discussion#>
	@result <#result#>
 */
- (BOOL)isStationeryFinderInfoFlag;
/*!
	@method hasNameLockedFinderInfoFlag
	@abstract <#abstract#>
	@discussion <#discussion#>
	@result <#result#>
 */
- (BOOL)hasNameLockedFinderInfoFlag;
/*!
	@method hasBundleFinderInfoFlag
	@abstract <#abstract#>
	@discussion <#discussion#>
	@result <#result#>
 */
- (BOOL)hasBundleFinderInfoFlag;
/*!
	@method isInvisibleFinderInfoFlag
	@abstract <#abstract#>
	@discussion <#discussion#>
	@result <#result#>
 */
- (BOOL)isInvisibleFinderInfoFlag;
/*!
	@method isAliasFinderInfoFlag
	@abstract <#abstract#>
	@discussion <#discussion#>
	@result <#result#>
 */
- (BOOL)isAliasFinderInfoFlag;

/*!
	@method setHasCustomIconFinderInfoFlag:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@result <#result#>
 */
- (BOOL)setHasCustomIconFinderInfoFlag:(BOOL)aFlag;
/*!
	@method setIsStationeryFinderInfoFlag:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param flag <#discussion#>
	@result <#result#>
 */
- (BOOL)setIsStationeryFinderInfoFlag:(BOOL)aFlag;
/*!
	@method setHasNameLockedFinderInfoFlag:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param flag <#discussion#>
	@result <#result#>
 */
- (BOOL)setHasNameLockedFinderInfoFlag:(BOOL)aFlag;
/*!
	@method setHasBundleFinderInfoFlag:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param flag <#discussion#>
	@result <#result#>
 */
- (BOOL)setHasBundleFinderInfoFlag:(BOOL)aFlag;
/*!
	@method setIsInvisibleFinderInfoFlag:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param flag <#discussion#>
	@result <#result#>
 */
- (BOOL)setIsInvisibleFinderInfoFlag:(BOOL)aFlag;
/*!
	@method setIsAliasFinderInfoFlag:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param flag <#discussion#>
	@result <#result#>
 */
- (BOOL)setIsAliasFinderInfoFlag:(BOOL)aFlag;

@end
