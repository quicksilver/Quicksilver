/*
 *  NDAlias+AliasFile.h category
 *  NDAliasProject
 *
 *  Created by Nathan Day on Tue Dec 03 2002.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */
/*!
	@header NDAlias+AliasFile
	@abstract Defines a category of the class <TT>NDAlias</TT>
	@discussion This category add additional functionality to <TT>NDAlias</TT> for reading and writing <TT>NDAlias</TT> instances to Finder alias files. Though this could be used for archiving purposed, the methods of the adopted protocol <TT>NSCoding</TT> are probable better suited. The method of <TT>NDAlias (AliasFile)</TT> are mainly for creating alias files that are visible in Finder to the user.
	<P>As well as the class <TT>NDAlias</TT> and the classes and categories it uses, <TT>NDAlias (AliasFile)</TT> also requires the class <TT>NDResourceFork</TT> and it's category <TT>NDResourceFork (OtherSorces)</TT>. If the additional functionality of <TT>NDAlias (AliasFile)</TT> is not required then the files for <TT>NDAlias (AliasFile)</TT>, <TT>NDResourceFork</TT> and <TT>NDResourceFork (OtherSorces)</TT> can be excluded from your project.</P>
 */

#import <Cocoa/Cocoa.h>
#import "NDAlias.h"

/*!
	@category NDAlias(AliasFile)
	@abstract A category of the class <TT>NDAlias</TT>
	@discussion This category add additional functionality to <TT>NDAlias</TT> for reading and writing <TT>NDAlias</TT> instances to Finder alias files. Though this could be used for archiving purposed, the methods of the adopted protocol <TT>NSCoding</TT> are probable better suited. The method of <TT>NDAlias (AliasFile)</TT> are mainly for creating alias files that are visible in Finder to the user.
	<P>As well as the class <TT>NDAlias</TT> and the classes and categories it uses, <TT>NDAlias (AliasFile)</TT> also requires the class <TT>NDResourceFork</TT> and it's category <TT>NDResourceFork (OtherSorces)</TT>. If the additional functionality of <TT>NDAlias (AliasFile)</TT> is not required then the files for <TT>NDAlias (AliasFile)</TT>, <TT>NDResourceFork</TT> and <TT>NDResourceFork (OtherSorces)</TT> can be excluded from your project.</P>
 */
@interface NDAlias (AliasFile)

/*!
	@method aliasWithContentsOfFile:
	@abstract Creates and initalises a <TT>NDAlias</TT>.
	@discussion The method <TT>aliasWithContentsOfFile:</TT> allocates and initalises an <TT>NDAlias</TT> with the alias record data within the Finder alias file pointed to by the <TT>NSString</TT> path <TT>aPath</TT>.
	@param aPath the path to an alias file.
	@result A <TT>NDAlias</TT> instance, returns <TT>nil</TT> if <TT>NDAlias</TT> creation fails.
 */
+ (id)aliasWithContentsOfFile:(NSString *)aPath;
	/*!
  @method aliasWithContentsOfURL:
	 @abstract Initalises a <TT>NDAlias</TT>.
	 @discussion The method <TT>aliasWithContentsOfURL:</TT> allocates and initalises an <TT>NDAlias</TT> with the alias record data within the Finder <TT>NSURL</TT> alias file pointed to pay the file url <TT>aURL</TT>
	 @param aURL the file url to the alias file.
	 @result A <TT>NDAlias</TT> instance, returns <TT>nil</TT> if <TT>NDAlias</TT> creation fails.
	 */
+ (id)aliasWithContentsOfURL:(NSURL *)aURL;

/*!
	@method initWithContentsOfFile:
	@abstract Initalises a <TT>NDAlias</TT>.
	@discussion The method <TT>initWithContentsOfFile:</TT> initalises the receiver with the alias record data within the Finder alias file pointed to by the <TT>NSString</TT> path <TT>aPath</TT>
	@param aPath the path to the alias file.
	@result An initalises <TT>NDAlias</TT>, returns <TT>nil</TT> if initalises fails.
  */
- (id)initWithContentsOfFile:(NSString *)aPath;
/*!
	@method initWithContentsOfURL:
	@abstract Initalises a <TT>NDAlias</TT>.
	@discussion The method <TT>initWithContentsOfURL:</TT> initalises the reciever with the alias record data within the Finder <TT>NSURL</TT> alias file pointed to pay the file url <TT>aURL</TT>.
	@param aURL the file url to the alias file.
	@result An initalises <TT>NDAlias</TT>, returns <TT>nil</TT> if initalises fails.
 */
- (id)initWithContentsOfURL:(NSURL *)aURL;

/*!
	@method writeToFile:
	@abstract Writes an <TT>NDAlias</TT> to a Finder alias file.
	@discussion The method <TT>writeToFile:</TT> writes the alias record data contained within the reciever to a Finder alias file at the path <TT>aPath</TT>. <TT>writeToFile:</TT> can be used to create alias files that the user can see in Finder and use.
	@param aPath the path for the alias file. Not the path the alias record represents.
	@result «result»
  */
- (BOOL)writeToFile:(NSString *)aPath;
/*!
	@method writeToURL:
	 @abstract Writes an <TT>NDAlias</TT> to a Finder alias file.
	 @discussion The method <TT>writeToURL:</TT> writes the alias record data contained within the reciever to a Finder alias file at the file url <TT>aURL</TT>. <TT>writeToFile:</TT> can be used to create alias files that the user can see in Finder and use.
	@param aURL the file url for the alias file. Not the file url the alias record represents.
	 @result «result»
 */
- (BOOL)writeToURL:(NSURL *)aURL;

@end