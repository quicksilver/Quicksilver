/*!
	@header NSString+NDCarbonUtilities
	@abstract Decalres the category <tt>NSString (NDCarbonUtilities)</tt>
	@discussion Provides method for interacting with Carbon APIs.
 
	Created by Nathan Day on Sat Aug 03 2002.
	Copyright &#169; 2002 Nathan Day. All rights reserved.
 */

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

/*!
	@category NSString(NDCarbonUtilitiesPaths)
	@abstract Provides method for interacting with Carbon APIs.
	@discussion Methods for dealing with <tt>FSRef</tt>&rsquo;s and pascal string as well as making some other core foundation methods accessable in Objective-C syntax.
 */
@interface NSString (NDCarbonUtilitiesPaths)

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
	 @param fsSpec A pointer to a <tt>FSSpec</tt> struct, to be filled by the method.
	 @result Returns <tt>YES</tt> if successful, if the method returns <tt>NO</tt> then <tt>fsSpec</tt> contains garbage.
 */
- (BOOL)getFSSpec:(FSSpec *)fsSpec;

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
	@method pascalString:length:
	@abstract Obtain a pascal string equivelent to the receveiver.
	@discussion Fill the <tt>StringPtr</tt> with a pascal string equivelent to the receveiver.
	@param buffer A <tt>StringPtr</tt> that contains the pascal string on completion.
	@param length The maximum length the string can be. Pascal string can be no longer than <tt>255</tt> bytes long, <tt>256</tt> if you include the first length byte.
	@result Returns <tt>YES</tt> if the method was successful, if <tt>NO</tt> is returns then <tt>buffer</tt> contains garbage.
 */
- (BOOL)pascalString:(StringPtr)buffer length:(short)length;

/*!
	@method trimWhitespace
	@abstract Trims white space from a <tt>NSString</tt>.
	@discussion Returns a new <tt>NSString</tt> equivelent to the receveiver but without any white space (return, new line, space, tab) at the begining or end of the string.
	@result A new <tt>NSString</tt>.
 */
- (NSString *)trimWhitespace;

@end
