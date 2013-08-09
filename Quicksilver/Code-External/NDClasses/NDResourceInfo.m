/*
 *  NDResourceInfo.m
 *  NDResourceFork
 *
 *  Created by Nathan Day on Sat Jun 21 2003.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "NDResourceInfo.h"
#import "NSString+NDCarbonUtilities.h"

extern NSData * dataFromResourceHandle( Handle aResourceHandle );

/*
 * class interface NDResourceInfo (Private)
 */
@interface NDResourceInfo (Private)
+ (id)resourceInfoWithType:(ResType)aType index:(SInt16)aIndex;
- (id)initWithType:(ResType)aType index:(SInt16)aIndex;
- (void)setType:(ResType)aType index:(SInt16)aIndex;
- (BOOL)getResourceInfo;
@end

/*
 * class interface ResourceEnumeratorForType : NSEnumerator
 */
@interface ResourceEnumeratorForType : NSEnumerator
{
@private
	ResType				type;
	SInt16				numberOfResources,
							resourceIndex;
}
+ (id)resourceEnumeratorForType:(ResType)aType;
- (id)initForType:(ResType)aType;
@end

/*
 * class implementation NDResourceInfo
 */
@implementation NDResourceInfo

/*
 * -resourceId
 */
- (short int)resourceId
{
	if( !resourceName ) NSAssert([self getResourceInfo], @"Could not get id for resource");

	return resourceId;
}

/*
 * -type
 */
- (ResType)resourceType
{
	return type;
}

/*
 * -name
 */
- (NSString *)name
{
	if( !resourceName ) NSAssert([self getResourceInfo], @"Could not get name for resource");

	return resourceName;
}

/*
 * -data
 */
- (NSData *)data
{
	if( resourceData == nil )
	{
		Handle		theResHandle;

		theResHandle = Get1IndResource( type, resourceIndex );

		if( theResHandle && noErr == ResError() )
		{
			resourceData = [dataFromResourceHandle( theResHandle ) retain];
		}
		else
			NSLog( @"Could not get data for resource");
	}

	return resourceData;
}

/*
 * -description
 */
- (NSString *)description
{
	return [NSString stringWithFormat:@"type = %@, id = %i, name = %@", NSFileTypeForHFSTypeCode([self resourceType]), [self resourceId], [self name]];
}

@end

/*
 * class implementation NDResourceInfo (Private)
 */
@implementation NDResourceInfo (Private)

/*
 * +resourceInfoWithType:index:
 */
+ (id)resourceInfoWithType:(ResType)aType index:(SInt16)aIndex
{
	return [[[self alloc] initWithType:aType index:aIndex] autorelease];
}

/*
 * -initWithType:index:
 */
- (id)initWithType:(ResType)aType index:(SInt16)aIndex
{
	if( self = [self init] )
	{
		[self setType:aType index:aIndex];
	}

	return self;
}

- (void)setType:(ResType)aType index:(SInt16)aIndex
{
	type = aType;
	resourceIndex = aIndex;
	[resourceData release];
	resourceData = nil;
}

/*
 * -dealloc
 */
- (void)dealloc
{
	[resourceData release];
	[super dealloc];
}

/*
 * -getResourceInfo
 */
- (BOOL)getResourceInfo
{
	Handle		theResHandle;
	short			theResID = 0;
	ResType		theResType;
	Str255		theResName;

	SetResLoad( false );
	theResHandle = Get1IndResource( type, resourceIndex );
	SetResLoad( true );

	if( theResHandle && noErr == ResError() )
	{
		GetResInfo( theResHandle, &theResID, &theResType, theResName );

		if( noErr ==  ResError( ) )
		{
			resourceId = theResID;
			resourceName = [NSString stringWithPascalString:theResName];
		}
		else
			NSLog( @"Could not get name for resource");
	}
	else
		NSLog( @"Could not get name for resource");

	return resourceName != nil;
}

@end

@implementation NDResourceFork (ResourceInfo)

/*
 * -resourceEnumeratorOfType:
 */
- (NSEnumerator *)resourceEnumeratorOfType:(ResType)aType
{
	return [ResourceEnumeratorForType resourceEnumeratorForType:aType];
}

/*
 * -everyResourceType
 */
- (NSArray *)everyResourceOfType:(ResType)aType
{
	return [[ResourceEnumeratorForType resourceEnumeratorForType:aType] allObjects];
}

@end

/*
 * class implementation ResourceEnumeratorForType : NSEnumerator
 */
@implementation ResourceEnumeratorForType : NSEnumerator

/*
 * +resourceEnumeratorForType:
 */
+ (id)resourceEnumeratorForType:(ResType)aType
{
	return [[[self alloc] initForType:aType] autorelease];
}

/*
 * -initForType:
 */
- (id)initForType:(ResType)aType
{
	if( self = [self init] )
	{
		type = aType;
		numberOfResources = Count1Resources( type );
		resourceIndex = 1;
	}

	return self;
}

/*
 * -nextObject
 */
- (id)nextObject
{
	if( resourceIndex <= numberOfResources )
		return [NDResourceInfo resourceInfoWithType:type index:resourceIndex++];
	else
		return nil;
}

@end

