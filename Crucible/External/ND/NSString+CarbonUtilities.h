/*
 *  NSString+CarbonUtilities.h category
 *
 *  Created by Nathan Day on Sat Aug 03 2002.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.\
 */

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

/*!
	@category NSString(CarbonUtilitiesPaths)
	@abstract Provides method for interacting with Carbon APIs.
	@discussion Methods for dealing with <TT>FSRef</TT>&rsquo;s and methods for dealing with pascal string as well as making some other core foundation methods accessable in Objective-C syntax.
 */
@interface NSString (CarbonUtilitiesPaths)

/*!
	@method stringWithFSRef:
	@abstract Alloc and initialize an <TT>NSString</TT>.
	@discussion Creats a <TT>NSString</TT> containing a POSIX style path from a <TT>FSRef</TT>
	@param aFSRef a pointer to a <TT>FSRef</TT>.
	@result A <TT>NSString</TT> containing a POSIX path.
  */
//+ (NSString *)stringWithFSRef:(const FSRef *)aFSRef;
/*!
	@method getFSRef:
	@abstract Get a <TT>FSRef</TT> for a path <TT>NSString</TT>.
	@discussion Initializes an <TT>FSRef</TT> for a POSIX style path <TT>NSString</TT>.
	@param aFSRef a pointer to a <TT>FSRef</TT>.
	@result Return <TT>YES</TT> if the method was successful, if the function returns <TT>NO</TT> then the <TT>FSRef</TT> pointed to by <TT>aFSRef</TT> is garbage.
  */
- (BOOL)getFSRef:(FSRef *)aFSRef;

/*!
	@method getFSSpec:
	 @abstract Get a <TT>FSSpec</TT>.
	 @discussion Obtain a <TT>FSSpec</TT> for a POSIX path.
	 @param aFSSpec A pointer to a <TT>FSSpec</TT> struct, to be filled by the method.
	 @result Returns <TT>YES</TT> if successful, if the method returns <TT>NO</TT> then <TT>aFSSpec</TT> contains garbage.
 */
- (BOOL)getFSSpec:(FSSpec *)aFSSpec;

/*!
	@method fileSystemPathHFSStyle
	@abstract Returns a HFS style path.
	@discussion Returns a <TT>NSString</TT> containg a HFS style path (e.g. <TT>Macitosh HD:Users:</TT>) useful for display purposes.
	@result A new <TT>NSString</TT> containing a HFS style path for the same file or directory as the receiver.
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
	@discussion Returns an POSIX path <TT>NSString</TT> refered to by the receveive if the receveive refers to an alias file. If it does not refer to an alias file the a string identical to the receveive is returned.
	@result An POSIX path <TT>NSString</TT>.
  */
- (NSString *)resolveAliasFile;

/*!
	@method stringWithPascalString:
	@abstract Alloc and initialize an <TT>NSString</TT>.
	@discussion Reurns a new <TT>NSString</TT> equivelent to the passed in pascal string.
	@param aPStr A pascal string of type <TT>ConstStr255Param</TT>.
	@result A <TT>NSString</TT>.
 */
+ (NSString *)stringWithPascalString:(ConstStr255Param)aPStr;

/*!
	@method pascalString:length:
	@abstract Obtain a pascal string equivelent to the receveiver.
	@discussion Fill the <TT>StringPtr</TT> with a pascal string equivelent to the receveiver.
	@param aBuffer A <TT>StringPtr</TT> that contains the pascal string on completion.
	@param aLength The maximum length the string can be. Pascal string can be no longer than <TT>255</TT> bytes long, <TT>256</TT> if you include the first length byte, so a value of 256 is the desired length.
	@result Returns <TT>YES</TT> if the method was successful, if <TT>NO</TT> is returns then <TT>aBuffer</TT> contains garbage.
 */
- (BOOL)pascalString:(StringPtr)aBuffer length:(short)aLength;

/*!
	@method trimWhitespace
	@abstract Trims white space from a <TT>NSString</TT>.
	@discussion Returns a new <TT>NSString</TT> equivelent to the receveiver but without any white space (return, new line, space, tab) at the begining or end of the string.
	@result A new <TT>NSString</TT>.
 */
- (NSString *)trimWhitespace;

@end
