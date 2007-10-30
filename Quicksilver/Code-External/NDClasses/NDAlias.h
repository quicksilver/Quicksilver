/*
 *  NDAlias.h
 *  NDAliasProject
 *
 *  Created by Nathan Day on Thu Feb 07 2002.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import <Foundation/Foundation.h>

/*!
	@header NDAliasProject
	Declare the interface for the class NDAlias.
 */

/*!
	@class NDAlias
	@abstract A class to access the Alias Manager from Cocoa 
	@discussion Your application can use a <TT>NDAlias</TT> to refere to file system objects (that is, files, directories, and volumes) in a way that does expect the file system objects path to be maintained. The user then can move or rename the file system object with out your program lossing track of it. This behaviour is not always desirable, for intance with library resources. But for file system objects like documents of user folders, it is what Mac OS users have come to expect
 */
@interface NDAlias : NSObject <NSCoding>
{
	AliasHandle		aliasHandle;
	Boolean			changed;
}

/*!
	@method aliasWithURL:
	@abstract Creates and initalises a <TT>NDAlias</TT>.
	@discussion The method <TT>aliasWithURL:</TT> creates an <TT>NDAlias</TT> that contains only the minimum information necessary to describe the target: the target name, the parent directory ID, the volume name and creation date, and the volume mounting information. The <TT>aliasWithURL:</TT> method uses the standard alias record data structure, but it fills in only parts of the record.
	<P>The methods <TT>url</TT> and <TT>path</TT> never update a minimal alias record.</P>
	@param aURL the file url for the target of the alias.
	@result A <TT>NDAlias</TT> instance, returns <TT>nil</TT> if <TT>NDAlias</TT> creation fails.
  */
+ (id)aliasWithURL:(NSURL *)aURL;
/*!
	@method aliasWithURL:fromURL:
	 @abstract Creates and initalises a <TT>NDAlias</TT>.
	 @discussion  The method <TT>aliasWithURL:fromURL:</TT> creates a <TT>NDAlias</TT> that describes the specified target. <TT>aliasWithURL:fromURL:</TT> always records the name and file or directory ID of the target, its creation date, the parent directory name and ID, and the volume name and creation date. It also records the full pathname of the target and a collection of other information relevant to locating the target, verifying the target, and mounting the target's volume, if necessary. <TT>aliasWithURL:fromURL:</TT> also stores relative path information as well by supplying a starting point for a relative path.
	@param aURL the file url for the target of the alias.
	@param aFromURL The starting point for a relative path, to be used later in a relative search. The two file or directory url's, <TT>aFromURL</TT> and <TT>aURL</TT>, must reside on the same volume.
	@result A <TT>NDAlias</TT> instance, returns <TT>nil</TT> if <TT>NDAlias</TT> creation fails.
 */
+ (id)aliasWithURL:(NSURL *)aURL fromURL:(NSURL *)aFromURL;
/*!
	@method aliasWithPath:
	@abstract Creates and initalises a <TT>NDAlias</TT>.
	@discussion The method <TT>aliasWithPath:</TT> creates an <TT>NDAlias</TT> that contains only the minimum information necessary to describe the target: the target name, the parent directory ID, the volume name and creation date, and the volume mounting information. The <TT>aliasWithPath:</TT> method uses the standard alias record data structure, but it fills in only parts of the record.
	<P>The methods <TT>url</TT> and <TT>path</TT> never update a minimal alias record.</P>
	@param aPath the path for the target of the alias.
	@result A <TT>NDAlias</TT> instance, returns <TT>nil</TT> if <TT>NDAlias</TT> creation fails.
 */
+ (id)aliasWithPath:(NSString *)aPath;
/*!
	@method aliasWithPath:fromPath:
	 @abstract Creates and initalises a <TT>NDAlias</TT>.
	 @discussion  The method <TT>aliasWithPath:fromPath:</TT> creates a <TT>NDAlias</TT> that describes the specified target. <TT>aliasWithPath:fromPath:</TT> always records the name and file or directory ID of the target, its creation date, the parent directory name and ID, and the volume name and creation date. It also records the full pathname of the target and a collection of other information relevant to locating the target, verifying the target, and mounting the target's volume, if necessary. <TT>aliasWithPath:fromPath:</TT> also stores relative path information as well by supplying a starting point for a relative path.
	 @param aURL the file url for the target of the alias.
	 @param aFromPath The starting point for a relative path, to be used later in a relative search. The two file or directory url's, <TT>aFromPath</TT> and <TT>aURL</TT>, must reside on the same volume.
	 @result A NDAlias instance, returns <TT>nil</TT> if <TT>NDAlias</TT> creation fails.
 */
+ (id)aliasWithPath:(NSString *)aPath fromPath:(NSString *)aFromPath;

/*!
	@method aliasWithData:
	@abstract Creates and initalises a <TT>NDAlias</TT>.
	@discussion The method <TT>aliasWithData:</TT> creates a <TT>NDAlias</TT> that describes the specified target. <TT>aliasWithData:</TT> creates the <TT>NDAlias</TT> from the data that was returned from the method <TT>data</TT>
	@param aData The <TT>NSData</TT> instaqnces that contains the data returned previously from the method <TT>data</TT>.
	@result A NDAlias instance, returns <TT>nil</TT> if <TT>NDAlias</TT> creation fails.
  */
+ (id)aliasWithData:(NSData *)aData;

/*!
	@method initWithURL:
	@abstract Initalises a <TT>NDAlias</TT>.
	@discussion The method <TT>initWithURL:</TT> initalises an <TT>NDAlias</TT> that contains only the minimum information necessary to describe the target: the target name, the parent directory ID, the volume name and creation date, and the volume mounting information. The <TT>initWithURL:</TT> method uses the standard alias record data structure, but it fills in only parts of the record.
	 <P>The methods <TT>url</TT> and <TT>path</TT> never update a minimal alias record.</P>
	@param aURL the file url for the target of the alias.
	@result A <TT>NDAlias</TT> instance, returns <TT>nil</TT> if <TT>NDAlias</TT> creation fails.
 */
- (id)initWithURL:(NSURL *)aURL;
/*!
	@method initWithPath:fromURL:
	 @abstract Initalises a <TT>NDAlias</TT>.
	 @discussion  The method <TT>initWithPath:fromURL:</TT> initalises a <TT>NDAlias</TT> that describes the specified target. <TT>initWithPath:fromURL:</TT> always records the name and file or directory ID of the target, its creation date, the parent directory name and ID, and the volume name and creation date. It also records the full pathname of the target and a collection of other information relevant to locating the target, verifying the target, and mounting the target's volume, if necessary. <TT>initWithPath:fromURL:</TT> also stores relative path information as well by supplying a starting point for a relative path.
	 @param aURL the file url for the target of the alias.
	 @param aFromURL The starting point for a relative path, to be used later in a relative search. The two file or directory url's, <TT>aFromURL</TT> and <TT>aURL</TT>, must reside on the same volume.
	@result An initalises <TT>NDAlias</TT>, returns <TT>nil</TT> if initalises fails.
 */
- (id)initWithURL:(NSURL *)aURL fromURL:(NSURL *)aFromURL;
/*!
	@method initWithPath:
	 @abstract Initalises a <TT>NDAlias</TT>.
	 @discussion The method <TT>initWithPath:</TT> initalises an <TT>NDAlias</TT> that contains only the minimum information necessary to describe the target: the target name, the parent directory ID, the volume name and creation date, and the volume mounting information. The <TT>initWithPath:</TT> method uses the standard alias record data structure, but it fills in only parts of the record.
	 <P>The methods <TT>url</TT> and <TT>path</TT> never update a minimal alias record.</P>
	 @param aPath the path for the target of the alias.
	@result An initalises <TT>NDAlias</TT>, returns <TT>nil</TT> if initalises fails.
 */
- (id)initWithPath:(NSString *)aPath;
/*!
	@method initWithPath:fromPath:
	 @abstract Initalises a <TT>NDAlias</TT>.
	 @discussion  The method <TT>initWithPath:fromPath:</TT> initalises a <TT>NDAlias</TT> that describes the specified target. <TT>initWithPath:fromPath:</TT> always records the name and file or directory ID of the target, its creation date, the parent directory name and ID, and the volume name and creation date. It also records the full pathname of the target and a collection of other information relevant to locating the target, verifying the target, and mounting the target's volume, if necessary. <TT>initWithPath:fromPath:</TT> also stores relative path information as well by supplying a starting point for a relative path.
	 @param aPath the file url for the target of the alias.
	 @param aFromPath The starting point for a relative path, to be used later in a relative search. The two file or directory url's, <TT>aFromPath</TT> and <TT>aPath</TT>, must reside on the same volume.
	@result An initalises <TT>NDAlias</TT>, returns <TT>nil</TT> if initalises fails.
 */
- (id)initWithPath:(NSString *)aPath fromPath:(NSString *)aFromPath;

	/*!
	@method initWithData:
	 @abstract Initalises a <TT>NDAlias</TT>.
	 @discussion The method <TT>initWithData:</TT> initalises a <TT>NDAlias</TT> that describes the specified target. <TT>initWithData:</TT> creates the <TT>NDAlias</TT> from the data that was returned from the method <TT>data</TT>
	 @param aData The <TT>NSData</TT> instaqnces that contains the data returned previously from the method <TT>data</TT>.
	 @result An initalises <TT>NDAlias</TT>, returns <TT>nil</TT> if initalises fails.
	 */
- (id)initWithData:(NSData *)aData;

/*!
	@method url
	@abstract Returns the single most likely target for the receiver.
	@discussion  The <TT>url</TT> method performs a fast search for the target of the receiver. If the resolution is successful, <TT>url</TT> returns a file <TT>NSURL</TT> for the target file system object, updates the receiver if necessary, and reports (through the method <TT>changed</TT>) whether the receiver was updated. If the target is on an unmounted AppleShare volume, <TT>url</TT> automatically mounts the volume. If the target is on an unmounted ejectable volume, <TT>url</TT> asks the user to insert the volume.
	<P>After it identifies a target, <TT>url</TT> compares some key information about the target with the information in the receiver. If the information differs, <TT>url</TT> updates the receiver to match the target.</P>
	<P>The <TT>url</TT> method displays the standard dialog boxes when it needs input from the user, such as a name and password for mounting a remote volume. The user can cancel the resolution through these dialog boxes.</P>
	@result A file <TT>NSURL</TT> to the target of the receiver. <TT>nil</TT> is returned if no target could be found. 
  */
- (NSURL *)url;
/*!
	@method path
	 @abstract Returns the single most likely target for the receiver.
	 @discussion  The method <TT>path</TT> performs a fast search for the target of the receiver. If the resolution is successful, <TT>path</TT> returns a path <TT>NSString</TT> for the target file system object, updates the receiver if necessary, and reports (through the method <TT>changed</TT>) whether the receiver was updated. If the target is on an unmounted AppleShare volume, <TT>path</TT> automatically mounts the volume. If the target is on an unmounted ejectable volume, <TT>path</TT> asks the user to insert the volume.
	 <P>After it identifies a target, <TT>path</TT> compares some key information about the target with the information in the receiver. If the information differs, <TT>path</TT> updates the receiver to match the target.</P>
	 <P>The <TT>path</TT> method displays the standard dialog boxes when it needs input from the user, such as a name and password for mounting a remote volume. The user can cancel the resolution through these dialog boxes.</P>
	 @result A path <TT>NSString</TT> to the target of the receiver. <TT>nil</TT> is returned if no target could be found.
 */
- (NSString *)path;
/*!
	@method changed
	@abstract Reports whether the receiver was updated.
	@discussion The method <TT>changed</TT> indicates whether the receiver was updated because it contained some outdated information about the target. If it the receiver is updated, <TT>YES</TT> is returned. Otherwise, it return <TT>NO</TT>. (<TT>url</TT> and <TT>path</TT> never update a <TT>NDAlias</TT> that was created with no relative path.) 
	@result <TT>YES</TT> if the receiver was updated, <TT>NO</TT> if it was not updated.
  */
- (BOOL)changed;

/*!
	@method setURL:
	 @abstract Updates an the reciever with a new target.
	 @discussion The method <TT>setURL:</TT> rebuilds the entire recievers alias record .
	 @param aURL the file url for the target of the alias.
	 @result Returns <TT>YES</TT> if setting the target succeeded, otherwise returns <TT>NO</TT>.
 */
- (BOOL)setURL:(NSURL *)aURL;
/*!
	@method setURL:fromURL:
	@abstract Updates an the reciever with a new target.
	@discussion The method <TT>setURL:fromURL:</TT> rebuilds the entire recievers alias record .
	<P>The <TT>setURL:fromURL:</TT> function always creates a complete alias record. When you use <TT>setURL:fromURL:</TT> to update a minimal alias record, you convert the minimal record to a complete record.</P>
	@param aURL the file url for the target of the reciever.
	@param aFromURL The starting point for a relative path, to be used later in a relative search. The two file or directory url's, <TT>aFromURL</TT> and <TT>aURL</TT>, must reside on the same volume.
	@result Returns <TT>YES</TT> if setting the target succeeded, otherwise returns <TT>NO</TT>.
  */
- (BOOL)setURL:(NSURL *)aURL fromURL:(NSURL *)aFromURL;
/*!
	@method setPath:
	@abstract Updates an the reciever with a new target.
	@discussion The method <TT>setPath:</TT> rebuilds the entire recievers alias record .
	@param aPath the path for the target of the reciever.
	@result Returns <TT>YES</TT> if setting the target succeeded, otherwise returns <TT>NO</TT>.
 */
- (BOOL)setPath:(NSString *)aPath;
/*!
	@method setURL:fromURL:
	 @abstract Updates an the reciever with a new target.
	 @discussion The method <TT>setURL:fromURL:</TT> rebuilds the entire recievers alias record .
	 <P>The <TT>setURL:fromURL:</TT> function always creates a complete alias record. When you use <TT>setURL:fromURL:</TT> to update a minimal alias record, you convert the minimal record to a complete record.</P>
	 @param aPath the path for the target of the reciever.
	 @param aFromPath The starting point for a relative path, to be used later in a relative search. The two file or directory paths, <TT>aFromPath</TT> and <TT>aPath</TT>, must reside on the same volume.
	 @result Returns <TT>YES</TT> if setting the target succeeded, otherwise returns <TT>NO</TT>.
 */
- (BOOL)setPath:(NSString *)aPath fromPath:(NSString *)aFromPath;

/*!
	@method data
	@abstract Returns a <TT>NSData</TT> instance for the reciever.
	@discussion The method <TT>data</TT> returns the contents of the recievers as an <TT>NSData</TT>, this can be used for archiving perposes though <TT>NDAlias</TT> does implement the <TT>NSCoding</TT> protocol.
	@result Returns an <TT>NSData</TT> instance.
  */
- (NSData *)data;

@end
