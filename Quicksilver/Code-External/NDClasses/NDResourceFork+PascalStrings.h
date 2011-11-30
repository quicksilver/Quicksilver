/*
 *  NDResourceFork+PascalStrings.h category
 *  NDResourceFork
 *
 *  Created by Nathan Day on Tue Feb 11 2003.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

/*!
	@header NDResourceFork+PascalStrings
	@abstract Defines the interface for a category of the class <TT>NDResourceFork</TT>.
	@discussion This category was mainly added for testing purposes, it's easier to test added strings to a resource fork instead of raw data, but you may find it useful
 */

#import <Cocoa/Cocoa.h>
#import "NDResourceFork.h"

/*!
	@category NDResourceFork(PascalStrings)
	@abstract A category of the class <TT>NDResourceFork</TT>.
	@discussion This category was mainly added for testing purposes, it's easier to test added strings to a resource fork instead of raw data, but you may find it useful
 */
@interface NDResourceFork (PascalStrings)

/*!
	@method addString:type:Id:name:
	@abstract Adds a string to the receivers resource file.
	@discussion<TT>addString:type:name:</TT> doesn't verify whether the resource ID you pass in the parameter anID is already assigned to another resource of the same type. <TT>addString:type:Id:named:</TT> returns <TT>YES</TT> on success
	@param aString An <TT>NSString</TT> object containing the string to be added as a resource to the receivers resource file.
	@param aType The resource type of the resource to be added.
	@param anID The resource ID of the resource to be added.
	@param aName The name of the resource to be added.
	@result Returns <TT>YES</TT> if the string was successfully added, otherwise it returns <TT>NO</TT>.
 */
- (BOOL)addString:(NSString *)aString type:(ResType)aType Id:(short)anID name:(NSString *)aName;
/*!
	 @method addString:type:name:
	 @abstract Adds a string to the receivers resource file.
	 @discussion <TT>addString:type:name:</TT> uses an unique resource ID when adding a string . <TT>addString:type:Id:named:</TT> returns <TT>YES</TT> on success
	@param aString An <TT>NSString</TT> object containing the string to be added as a resource to the receivers resource file.
	 @param aType The resource type of the resource to be added.
	 @param aName The name of the resource to be added.
	 @result Returns <TT>YES</TT> if the resource was successfully added, otherwise it returns <TT>NO</TT>.
 */
- (BOOL)addString:(NSString *)aString type:(ResType)aType name:(NSString *)aName;
/*!
	@method stringForType:Id:
	 @abstract Gets a resource string for a resource in the receivers resource file.
	 @discussion <TT>stringForType:Id:</TT> searches the receivers resource file's resource map in memory for the specified resource string.
	 @param aType The resource type of the resource which you wish to retrieve a string.
	 @param anID An integer that uniquely identifies the resource which you wish to retrieve a string.
	 @result Returns an <TT>NSString</TT> object if successful otherwise returns nil.
 */
- (NSString *)stringForType:(ResType)aType Id:(short)anID;
/*!
	@method stringForType:named:
	@abstract Gets a resource string for a resource in the receivers resource file.
	@discussion <TT>stringForType:Id:</TT> searches the receivers resource file's resource map in memory for the specified resource string.
	 @param aType The resource type of the resourcee which you wish to retrieve a string.
	 @param aName A name that uniquely identifies the resource which you wish to retrieve a string. Strings passed in this parameter are case-sensitive.
	 @result Returns an <TT>NSString</TT> object if successful otherwise returns nil.
 */
- (NSString *)stringForType:(ResType)aType named:(NSString *)aName;

@end
