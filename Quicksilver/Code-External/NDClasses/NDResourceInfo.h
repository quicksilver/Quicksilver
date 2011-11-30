/*!
	@header NDResourceInfo.h
	@abstract Header file from the project NDResourceFork
	@discussion 
 
	Created by Nathan Day on Sat Jun 21 2003.
	Copyright (c) 2003 Nathan Day. All rights reserved.
 */
#import <Cocoa/Cocoa.h>
#import "NDResourceFork.h"

/*!
	@class NDResourceInfo
	@abstract Get resource info.
	@discussion A class to represent resource info.
 */
@interface NDResourceInfo : NSObject
{
@private
	ResType			type;
	SInt16			resourceIndex;
	NSString			* resourceName;
	short int		resourceId;
	NSData			* resourceData;
}

/*!
	@method resourceId
	@abstract Get the resource id.
	@discussion Returns the resources id.
	@result The id.
 */
- (short int)resourceId;

/*!
	@method resourceType
	@abstract Get the resource type.
	@discussion Returns the four char code resource type, <TT>ResType</TT> can be converted into a human readable string with the foundation function <TT>NSFileTypeForHFSTypeCode</TT>.
	@result The resource type.
 */
- (ResType)resourceType;

/*!
	@method name
	@abstract Get the resource name.
	@discussion Returns the resources name as a <TT>NSString</TT>
	@result The resources name.
 */
- (NSString *)name;

/*!
	@method data
	@abstract Get the resource data.
	@discussion Returns a <TT>NSData</TT> object containing the resource data.
	@result The resource data.
 */
- (NSData *)data;

@end

@interface NDResourceFork (ResourceInfo)
/*!
	@method resourceEnumeratorOfType:
	@abstract Get a enumerator for every resource of given type.
	@discussion Returns a <TT>NSEnumerator</TT> which will return a <TT>NDResourceInfo</TT> which can be used to get info for each resource.
	@param aType The resource type.
	@result The <TT>NSEnumerator</TT>.
  */
- (NSEnumerator *)resourceEnumeratorOfType:(ResType)aType;
/*!
	@method everyResourceOfType:
	@abstract Gets every resource of given type in the receivers resource file.
	@discussion <TT>everyResourceOfType:</TT> returns a <TT>NSArray</TT> of <TT>NDResourceInfo</TT> objects for every resource of the given type.
	@param aType The resource type.
	@result A <TT>NSArray</TT> of <TT>NDResourceInfo</TT>s.
  */
- (NSArray *)everyResourceOfType:(ResType)aType;
@end
