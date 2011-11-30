/*
 *  NSURL+NDCarbonUtilities.h category
 *  AppleScriptObjectProject
 *
 *  Created by nathan on Wed Dec 05 2001.
 *  Copyright (c) 2001 __CompanyName__. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

/*!
	@category NSURL(NDCarbonUtilities)
	@abstract Provides method for interacting with Carbon APIs.
	@discussion Methods for dealing with <TT>FSRef</TT>&rsquo;s, <TT>FSSpec</TT> and other useful carbon stuff.
 */
@interface NSURL (NDCarbonUtilities)

/*!
	@method URLWithFSRef:aFsRef
	@abstract Alloc and intialize a <TT>NSURL</TT>.
	@discussion Returns a file url for the file refered to by a <TT>FSRef</TT>.
	@param aFsRef A pointer to a <TT>FSRef</TT>.
	@result A <TT>NSURL</TT> containing a file url.
 */
+ (NSURL *)URLWithFSRef:(const FSRef *)aFsRef;

/*!
	@method getFSRef:
	@abstract Get a <TT>FSRef</TT>.
	@discussion Obtain a <TT>FSRef</TT> for a file url.
	@param aFsRef A pointer to a <TT>FSRef</TT> struct, to be filled by the method.
	@result Returns <TT>YES</TT> if successful, if the method returns <TT>NO</TT> then <TT>aFsRef</TT> contains garbage.
 */
- (BOOL)getFSRef:(FSRef *)aFsRef;

/*!
	@method getFSSpec:
	@abstract Get a <TT>FSSpec</TT>.
	@discussion Obtain a <TT>FSSpec</TT> for a file url.
	@param aFSSpec A pointer to a <TT>FSSpec</TT> struct, to be filled by the method.
	@result Returns <TT>YES</TT> if successful, if the method returns <TT>NO</TT> then <TT>aFSSpec</TT> contains garbage.
 */
- (BOOL)getFSSpec:(FSSpec *)aFSSpec;

/*!
	@method URLByDeletingLastPathComponent
	@abstract Delete last component of a url.
	@discussion Returns a new <TT>NSURL</TT> equivelent to the receiver with the last component removed.
	@result A new <TT>NSURL</TT>
 */
- (NSURL *)URLByDeletingLastPathComponent;

/*!
	@method fileSystemPathHFSStyle
	@abstract Returns a HFS style path.
	@discussion Returns a <TT>NSString</TT> containg a HFS style path (e.g. <TT>Macitosh HD:Users:</TT>) useful for display purposes.
	@result A new <TT>NSString</TT> containing a HFS style path for the same file or directory as the receiver.
 */
- (NSString *)fileSystemPathHFSStyle;

/*!
	@method resolveAliasFile
	@abstract Resolve an alias file.
	@discussion Returns an file url <TT>NSURL</TT> refered to by the receveive if the receveive refers to an alias file. If it does not refer to an alias file the a url identical to the receveive is returned.
	@result An file url <TT>NSURL</TT>.
 */
- (NSURL *)resolveAliasFile;

@end
