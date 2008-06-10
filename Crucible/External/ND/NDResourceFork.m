/*
 *  NDResourceFork.m
 *
 *  Created by nathan on Wed Dec 05 2001.
 *  Copyright 2001-2007 Nathan Day. All rights reserved.
 *
 *	Currently ResourceFork will not add resource forks to files
 *	or create new files with resource forks
 *
 */

#import "NDResourceFork.h"
#import "NSString+NDCarbonUtilities.h"

NSData * dataFromResourceHandle( Handle aResourceHandle );
BOOL operateOnResourceUsingFunction( ResFileRefNum afileRef, ResType aType, NSString * aName, ResID anId, BOOL (*aFunction)(Handle,ResType,NSString*,ResID,void*), void * aContext );

/*
 * class interface ResourceTypeEnumerator : NSEnumerator
 */
@interface ResourceTypeEnumerator : NSEnumerator
{
	@private
	SInt16	numberOfTypes,
				typeIndex;
}
+ (id)resourceTypeEnumerator;
@end

/*
 * class implementation NDResourceFork
 */
@implementation NDResourceFork

/*
 * resourceForkForReadingAtURL:
 */
+ (id)resourceForkForReadingAtURL:(NSURL *)aURL
{
	return [[[self alloc] initForReadingAtURL:aURL] autorelease];
}

/*
 * resourceForkForWritingAtURL:
 */
+ (id)resourceForkForWritingAtURL:(NSURL *)aURL
{
	return [[[self alloc] initForWritingAtURL:aURL] autorelease];
}

/*
 * resourceForkForReadingAtPath:
 */
+ (id)resourceForkForReadingAtPath:(NSString *)aPath
{
	return [[[self alloc] initForReadingAtPath:aPath] autorelease];
}

/*
 * resourceForkForWritingAtPath:
 */
+ (id)resourceForkForWritingAtPath:(NSString *)aPath
{
	return [[[self alloc] initForWritingAtPath:aPath] autorelease];
}

/*
	- initForReadingAtURL:
 */
- (id)initForReadingAtURL:(NSURL *)aURL
{
	return [self initForPermission:fsRdPerm atURL:aURL];
}

/*
	- initForWritingAtURL:
 */
- (id)initForWritingAtURL:(NSURL *)aURL
{
	return [self initForPermission:fsWrPerm atURL:aURL];
}

/*
	- initForPermission:AtURL:
 */
- (id)initForPermission:(char)aPermission atURL:(NSURL *)aURL
{
	return [self initForPermission:aPermission atPath:[aURL path]];
}

/*
	- initForPermission:AtPath:
 */
- (id)initForPermission:(char)aPermission atPath:(NSString *)aPath
{
	OSErr			theError = !noErr;
	FSRef			theFsRef,
					theParentFsRef;

	if( (self = [super init]) != nil )
	{
		/*
		 * if write permission then create resource fork
		 */
		if( (aPermission & 0x06) != 0 )		// if write permission
		{
			if ( [[aPath stringByDeletingLastPathComponent] getFSRef:&theParentFsRef] )
			{
				NSUInteger			theNameLength;
				unichar 			theUnicodeName[ PATH_MAX ];
				NSString			* theName;

				theName = [aPath lastPathComponent];
				theNameLength = [theName length];

				if( theNameLength <= PATH_MAX )
				{
					[theName getCharacters:theUnicodeName range:NSMakeRange(0,theNameLength)];

					FSCreateResFile( &theParentFsRef, theNameLength, theUnicodeName, 0, NULL, NULL, NULL );		// doesn't replace if already exists

					theError =  ResError( );

					if( theError == noErr || theError == dupFNErr )
					{
						[aPath getFSRef:&theFsRef];
						fileReference = FSOpenResFile ( &theFsRef, aPermission );
						theError = fileReference > 0 ? ResError( ) : !noErr;
					}
				}
				else
					theError = !noErr;
			}
		}
		else		// dont have write permission
		{
			[aPath getFSRef:&theFsRef];
			fileReference = FSOpenResFile ( &theFsRef, aPermission );
			theError = fileReference > 0 ? ResError( ) : !noErr;
		}

	}

	if( noErr != theError && theError != dupFNErr )
	{
		[self release];
		self = nil;
	}

	return self;
}

/*
	- initForReadingAtPath:
 */
- (id)initForReadingAtPath:(NSString *)aPath
{
	if( [[NSFileManager defaultManager] fileExistsAtPath:aPath] )
		return [self initForPermission:fsRdPerm atURL:[NSURL fileURLWithPath:aPath]];
	else
	{
		[self release];
		return nil;
	}
}

/*
	- initForWritingAtPath:
 */
- (id)initForWritingAtPath:(NSString *)aPath
{
	return [self initForPermission:fsWrPerm atURL:[NSURL fileURLWithPath:aPath]];
}

/*
	- closeFile
 */
- (void)closeFile
{
	if( fileReference > 0 )
	{
		CloseResFile( fileReference );
		fileReference = 0;
	}
}

#ifndef __OBJC_GC__

/*
	- dealloc
 */
- (void)dealloc
{
	if( fileReference > 0 )
		NSLog (@"NDAlias ERROR: you neglected to call closeFile: before disposing this NDResourceFork");
	[super dealloc];
}

#else

/*
	- finalize
 */
- (void)finalize
{
	if( fileReference > 0 )
		NSLog (@"NDAlias ERROR: you neglected to call closeFile: before disposing this NDResourceFork");
	[super finalize];
}

#endif

/*
	- addData:type:Id:name:
 */
- (BOOL)addData:(NSData *)aData type:(ResType)aType Id:(ResID)anId name:(NSString *)aName
{
	Handle		theResHandle;
	
	if( [self removeType:aType Id:anId] )
	{
		ResFileRefNum	thePreviousRefNum;

		thePreviousRefNum = CurResFile();	// save current resource
		UseResFile( fileReference );    			// set this resource to be current
	
		// copy NSData's bytes to a handle
		if ( noErr == PtrToHand ( [aData bytes], &theResHandle, [aData length] ) )
		{
			Str255			thePName;

			[aName getPascalString:(StringPtr)thePName length:sizeof(thePName)];
			
			HLock( theResHandle );
			AddResource( theResHandle, aType, anId, thePName );
			HUnlock( theResHandle );

/*			if( noErr == ResError() )
				ChangedResource( theResHandle );
*/			
			UseResFile( thePreviousRefNum );     		// reset back to resource previously set
	
			return ( ResError( ) == noErr );
		}
	}
	
	return NO;
}

/*
	- addData:type:name:
 */
- (BOOL)addData:(NSData *)aData type:(ResType)aType name:(NSString *)aName
{
	if( aName == nil ) NSLog(@"Adding a resource without specifying the name of id.");
	return [self addData:aData type:aType Id:Unique1ID(aType) name:aName];
}

static BOOL getDataFunction( Handle aResHandle, ResType aType, NSString * aName, ResID anId, void * aContext )
{
	(void)aType;
	(void)aName;
	(void)anId;
	NSData	** theData = (NSData**)aContext;
	*theData = dataFromResourceHandle( aResHandle );
	return *theData != nil;
}
/*
 * dataForType:Id:
 */
- (NSData *)dataForType:(ResType)aType Id:(ResID)anId
{
	NSData	* theData = nil;
	
	if( operateOnResourceUsingFunction( fileReference, aType, nil, anId, getDataFunction, (void*)&theData )  )
		return theData;
	else
		return nil;
}

/*
 * dataForType:named:
 */
- (NSData *)dataForType:(ResType)aType named:(NSString *)aName
{
	NSData	* theData = nil;

	if( operateOnResourceUsingFunction( fileReference, aType, aName, 0, getDataFunction, (void*)&theData )  )
		return theData;
	else
		return nil;
}

/*
 * removeType: Id:
 */
static BOOL removeResourceFunction( Handle aResHandle, ResType aType, NSString * aName, ResID anId, void * aContext )
{
	(void)aType;
	(void)aName;
	(void)anId;
	(void)aContext;
	if( aResHandle )
		RemoveResource( aResHandle );		// Disposed of in current resource file
	return !aResHandle || noErr == ResError( );
}
- (BOOL)removeType:(ResType)aType Id:(ResID)anId
{
	return operateOnResourceUsingFunction( fileReference, aType, nil, anId, removeResourceFunction,  NULL);
}

static BOOL getNameFunction( Handle aResHandle, ResType aType, NSString * aName, ResID anId, void * aContext )
{
	(void)aName;
	Str255		thePName;
	NSString		** theString = (NSString **)aContext;

	if( aResHandle )
	{
		GetResInfo( aResHandle, &anId, &aType, thePName );
		if( noErr ==  ResError( ) )
			*theString = [NSString stringWithPascalString:thePName];
	}

	return *theString != nil;
}
/*
 * nameOfResourceType:Id:
*/
- (NSString *)nameOfResourceType:(ResType)aType Id:(ResID)anId
{
	NSString		* theString = nil;

	if( operateOnResourceUsingFunction( fileReference, aType, nil, anId, getNameFunction, (void*)&theString ) )
		return theString;
	else
		return nil;

}

static BOOL getIdFunction( Handle aResHandle, ResType aType, NSString * aName, ResID anId, void * aContext  )
{
	(void)aContext;
	Str255		thePName;

	if( aResHandle && [aName getPascalString:(StringPtr)thePName length:sizeof(thePName)] )
	{
		GetResInfo( aResHandle, &anId, &aType, thePName );
		return noErr ==  ResError( );
	}
	else
		return NO;
}
/*
 * getId:OfResourceType:Id:
 */
- (BOOL)getId:(ResID *)anId ofResourceType:(ResType)aType named:(NSString *)aName
{
	(void)anId;
	return operateOnResourceUsingFunction( fileReference, aType, aName, 0, getIdFunction, NULL );
}

static BOOL getAttributesFunction( Handle aResHandle, ResType aType, NSString * aName, ResID anId, void * aContext )
{
	(void)aType;
	(void)aName;
	(void)anId;
	ResAttributes		* theAttributes = (ResAttributes*)aContext;
	if( aResHandle )
	{
		*theAttributes = GetResAttrs( aResHandle );
		return noErr ==  ResError( );
	}

	return NO;
}
/*
	- attributeFlags:forResourceType:Id:
 */
- (BOOL)getAttributeFlags:(ResAttributes*)attributes forResourceType:(ResType)aType Id:(ResID)anId
{
	return operateOnResourceUsingFunction( fileReference, aType, nil, anId, getAttributesFunction, (void*)attributes );
}

static BOOL setAttributesFunction( Handle aResHandle, ResType aType, NSString * aName, ResID anId, void * aContext  )
{
	(void)aType;
	(void)aName;
	(void)anId;
	ResAttributes		theAttributes = *(ResAttributes*)aContext;
	if( aResHandle )
	{
		theAttributes &= ~(resPurgeable|resChanged); // these attributes should not be changed
		SetResAttrs( aResHandle, theAttributes);
		if( noErr ==  ResError( ) )
		{
			ChangedResource(aResHandle);
			return noErr ==  ResError( );
		}
	}
	return NO;
}
/*
	- setAttributeFlags:forResourceType:Id:
 */
- (BOOL)setAttributeFlags:(ResAttributes)attributes forResourceType:(ResType)aType Id:(ResID)anId
{
	BOOL				theSuccess;

	NSLog(@"WARRING: Currently the setAttributeFlags:forResourceType:Id: does not work");
	theSuccess = operateOnResourceUsingFunction( fileReference, aType, nil, anId, setAttributesFunction, &attributes );
	return theSuccess;
}


/*
	- resourceTypeEnumerator
 */
- (NSEnumerator *)resourceTypeEnumerator
{
	return [ResourceTypeEnumerator resourceTypeEnumerator];
}

/*
	- everyResourceType
 */
- (NSArray *)everyResourceType
{
	return [[ResourceTypeEnumerator resourceTypeEnumerator] allObjects];
}

/*
	- dataForEntireResourceFork
 */
- (NSData *)dataForEntireResourceFork
{
	NSMutableData		* theData = nil;
	ByteCount			theByteCount;
	signed long long	theForkSize;
	
	if( FSGetForkSize( fileReference, &theForkSize ) == noErr && theForkSize <= UINT_MAX )
	{
		theData = [NSMutableData dataWithLength:(unsigned int)theForkSize];
		if( FSReadFork( fileReference, fsFromStart, 0, theForkSize, [theData mutableBytes], &theByteCount ) != noErr || theByteCount != (unsigned int)theForkSize )
			theData = nil;
	}

	return theData;
}

/*
	- writeEntireResourceFork:
 */
- (BOOL)writeEntireResourceFork:(NSData *)aData
{
	ByteCount		theWrittenBytes;
	NSUInteger		theDataLength;

	theDataLength = [aData length];

	// return true if aData exists, length not zero, write succeeds, write length equals data length
	return aData && theDataLength != 0 && FSWriteFork( fileReference, fsFromStart, 0, theDataLength, [aData bytes], &theWrittenBytes ) == noErr && theDataLength == theWrittenBytes;
}

@end

/*
 * class implementation ResourceTypeEnumerator
 */
@implementation ResourceTypeEnumerator

/*
 * +resourceTypeEnumerator
 */
+ (id)resourceTypeEnumerator
{
	return [[[self alloc] init] autorelease];
}

/*
	- init
 */
- (id)init
{
	if( (self = [super init]) != nil )
	{
		NSAssert( sizeof(ResType) <= sizeof(unsigned long) ,@"WARNING: everyResourceType assumes that ResType is the same size as unsigned long" );

		numberOfTypes = Count1Types ();
		typeIndex = 1;
	}

	return self;
}

/*
	- nextObject
 */
- (id)nextObject
{
	NSNumber		* theResTypeNumber = nil;
	ResType		theResType;

	if( typeIndex <=  numberOfTypes )
	{
		Get1IndType ( &theResType, typeIndex );

		if( noErr ==  ResError( ) )
			theResTypeNumber = [NSNumber numberWithUnsignedLong:theResType];
		else
			NSLog( @"Could not get type for resource %i", typeIndex);

		typeIndex++;
	}

	return theResTypeNumber;

}

@end

/*
 * implementation NSData (NDResourceFork)
 */
@implementation NSData (NDResourceFork)

/*
 * +dataWithResourceForkContentsOfURL:type:Id:
 */
+ (NSData *)dataWithResourceForkContentsOfURL:(NSURL *)aURL type:(ResType)aType Id:(ResID)anID
{
	NDResourceFork		* theResourceFork = [[NDResourceFork alloc] initForReadingAtURL:aURL];
	NSData				* theData = [theResourceFork dataForType:aType Id:anID];
	[theResourceFork closeFile];
	[theResourceFork release];
	return theData;
}

/*
 * +dataWithResourceForkContentsOfURL:type:named:
 */
+ (NSData *)dataWithResourceForkContentsOfURL:(NSURL *)aURL type:(ResType)aType named:(NSString *)aName
{
	NDResourceFork		* theResourceFork = [[NDResourceFork alloc] initForReadingAtURL:aURL];
	NSData				* theData = [theResourceFork dataForType:aType named:aName];
	[theResourceFork closeFile];
	[theResourceFork release];
	return theData;
}

/*
 * +dataWithResourceForkContentsOfFile:type:Id:
 */
+ (NSData *)dataWithResourceForkContentsOfFile:(NSString *)aPath type:(ResType)aType Id:(ResID)anID
{
	NDResourceFork		* theResourceFork = [[NDResourceFork alloc] initForReadingAtPath:aPath];
	NSData				* theData = [theResourceFork dataForType:aType Id:anID];
	[theResourceFork closeFile];
	[theResourceFork release];
	return theData;
}

/*
 * +dataWithResourceForkContentsOfFile:type:named:
 */
+ (NSData *)dataWithResourceForkContentsOfFile:(NSString *)aPath type:(ResType)aType named:(NSString *)aName
{
	NDResourceFork		* theResourceFork = [[NDResourceFork alloc] initForReadingAtPath:aPath];
	NSData				* theData = [theResourceFork dataForType:aType named:aName];
	[theResourceFork closeFile];
	[theResourceFork release];
	return theData;
}

/*
	- writeToResourceForkURL:type:Id:name:
 */
- (BOOL)writeToResourceForkURL:(NSURL *)aURL type:(ResType)aType Id:(int)anId name:(NSString *)aName
{
	BOOL				theResult = NO;
	NDResourceFork		* theResourceFork = [[NDResourceFork alloc] initForWritingAtURL:aURL];
	if( theResourceFork )
	{
		theResult = [theResourceFork addData:self type:aType Id:anId name:aName];
		[theResourceFork closeFile];
		[theResourceFork release];
	}
	return theResult;
}

/*
	- writeToResourceForkFile:ype:Id:name:
 */
- (BOOL)writeToResourceForkFile:(NSString *)aPath type:(ResType)aType Id:(int)anId name:(NSString *)aName
{
	BOOL				theResult = NO;
	NDResourceFork		* theResourceFork = [[NDResourceFork alloc] initForWritingAtPath:aPath];
	if( theResourceFork )
	{
		theResult = [theResourceFork addData:self type:aType Id:anId name:aName];
		[theResourceFork closeFile];
		[theResourceFork release];
	}
	return theResult;
}

/*
 * dataFromResourceHandle()
 */
NSData * dataFromResourceHandle( Handle aResourceHandle )
{
	NSData		* theData = nil;
	if( aResourceHandle )
	{
		HLock(aResourceHandle);
		theData = [NSData dataWithBytes:*aResourceHandle length:GetHandleSize( aResourceHandle )];
		HUnlock(aResourceHandle);
	}

	return theData;
}

BOOL operateOnResourceUsingFunction( ResFileRefNum afileRef, ResType aType, NSString * aName, ResID anId, BOOL (*aFunction)(Handle,ResType,NSString*,ResID,void*), void * aContext )
{
	Handle			theResHandle = NULL;
	ResFileRefNum	thePreviousRefNum;
	Str255			thePName;
	BOOL			theResult = NO;

	thePreviousRefNum = CurResFile();	// save current resource

	UseResFile( afileRef );    		// set this resource to be current

	if( noErr ==  ResError( ) && ((aName && [aName getPascalString:(StringPtr)thePName length:sizeof(thePName)]) || !aName ))
	{
		if( aName && [aName getPascalString:(StringPtr)thePName length:sizeof(thePName)] )
			theResHandle = Get1NamedResource( aType, thePName );
		else if( !aName )
			theResHandle = Get1Resource( aType, anId );			
				
		if( noErr == ResError() )
				theResult = aFunction( theResHandle, aType, aName, anId, aContext  );

		if ( theResHandle )
			ReleaseResource( theResHandle );
	}

	UseResFile( thePreviousRefNum );     		// reset back to resource previously set

	return theResult;
}

@end


