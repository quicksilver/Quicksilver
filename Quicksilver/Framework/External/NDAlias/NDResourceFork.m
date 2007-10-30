/*
 *  NDResourceFork.m
 *
 *  Created by nathan on Wed Dec 05 2001.
 *  Copyright (c) 2001 Nathan Day. All rights reserved.
 *
 *	Currently ResourceFork will not add resource forks to files
 *	or create new files with resource forks
 *
 */

#import "NDResourceFork.h"
#import "NSString+NDCarbonUtilities.h"

/*
 * class implementation NDResourceFork
 */
@implementation NDResourceFork

NSData * dataFromResourceHandle( Handle aResourceHandle );
BOOL operateOnResourceUsingFunction( short int afileRef, ResType aType, NSString * aName, short int anId, BOOL (*aFunction)(Handle,ResType,NSString*,short int,void*), void * aContext );

/*
 * +dataWithContentsOfURL:type:Id:
 */
+ (NSData *)dataWithContentsOfURL:(NSURL *)aURL type:(ResType)aType Id:(short int)anID
{
	return [[self resourceForkForReadingAtURL:aURL] dataForType:aType Id:anID];
}

/*
 * +dataWithContentsOfURL:type:named:
 */
+ (NSData *)dataWithContentsOfURL:(NSURL *)aURL type:(ResType)aType named:(NSString *)aName
{
	return [[self resourceForkForReadingAtURL:aURL] dataForType:aType named:aName];
}

/*
 * +dataWithContentsOfFile:type:Id:
 */
+ (NSData *)dataWithContentsOfFile:(NSString *)aPath type:(ResType)aType Id:(short int)anID
{
	return [[self resourceForkForReadingAtPath:aPath] dataForType:aType Id:anID];
}

/*
 * +dataWithContentsOfFile:type:named:
 */
+ (NSData *)dataWithContentsOfFile:(NSString *)aPath type:(ResType)aType named:(NSString *)aName
{
	return [[self resourceForkForReadingAtPath:aPath] dataForType:aType named:aName];
}

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
 * initForReadingAtURL:
 */
- (id)initForReadingAtURL:(NSURL *)aURL
{
	return [self initForPermission:fsRdPerm AtURL:aURL];
}

/*
 * initForWritingAtURL:
 */
- (id)initForWritingAtURL:(NSURL *)aURL
{
	return [self initForPermission:fsWrPerm AtURL:aURL];
}

/*
 * initForPermission:AtURL:
 */
- (id)initForPermission:(char)aPermission AtURL:(NSURL *)aURL
{
	return [self initForPermission:aPermission AtPath:[aURL path]];
}

/*
 * -initForPermission:AtPath:
 */
- (id)initForPermission:(char)aPermission AtPath:(NSString *)aPath
{
	OSErr			theError = !noErr;
	FSRef			theFsRef,
					theParentFsRef;

	if( (self = [self init]) != nil )
	{
		/*
		 * if write permission then create resource fork
		 */
		if( (aPermission & 0x06) != 0 )		// if write permission
		{
			if ( [[aPath stringByDeletingLastPathComponent] getFSRef:&theParentFsRef] )
			{
				unsigned int	theNameLength;
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
 * initForReadingAtPath:
 */
- (id)initForReadingAtPath:(NSString *)aPath
{
	if( [[NSFileManager defaultManager] fileExistsAtPath:aPath] )
		return [self initForPermission:fsRdPerm AtURL:[NSURL fileURLWithPath:aPath]];
	else
	{
		[self release];
		return nil;
	}
}

/*
 * initForWritingAtPath:
 */
- (id)initForWritingAtPath:(NSString *)aPath
{
	return [self initForPermission:fsWrPerm AtURL:[NSURL fileURLWithPath:aPath]];
}

/*
 * dealloc
 */
- (void)dealloc
{
	if( fileReference > 0 )
		CloseResFile( fileReference );

	[super dealloc];
}

/*
 * -addData:type:Id:name:
 */
- (BOOL)addData:(NSData *)aData type:(ResType)aType Id:(short int)anId name:(NSString *)aName
{
	Handle		theResHandle;
	
	if( [self removeType:aType Id:anId] )
	{
		short int	thePreviousRefNum;

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
 * -addData:type:name:
 */
- (BOOL)addData:(NSData *)aData type:(ResType)aType name:(NSString *)aName
{
	if( aName == nil ) NSLog(@"Adding a resource without specifying the name of id.");
	return [self addData:aData type:aType Id:Unique1ID(aType) name:aName];
}

/*
 * dataForType:Id:
 */
- (NSData *)dataForType:(ResType)aType Id:(short int)anId
{
	BOOL getDataFunction( Handle aResHandle, ResType type, NSString * aName, short int Id, void * context );
	NSData	* theData = nil;

	return operateOnResourceUsingFunction( fileReference, aType, nil, anId, getDataFunction, (void*)&theData ) ? theData : nil;
}

/*
 * dataForType:named:
 */
- (NSData *)dataForType:(ResType)aType named:(NSString *)aName
{
	BOOL getDataFunction( Handle aResHandle, ResType type, NSString * name, short int Id, void * context);
	NSData	* theData = nil;

	if( operateOnResourceUsingFunction( fileReference, aType, aName, 0, getDataFunction, (void*)&theData )  )
		return theData;
	else
		return nil;
}
	BOOL getDataFunction( Handle aResHandle, ResType aType, NSString * aName, short int anId, void * aContext )
	{
		NSData	** theData = (NSData**)aContext;
		*theData = dataFromResourceHandle( aResHandle );
		return *theData != nil;
	}


/*
 * -everyResourceType
 *		array of NSNumbers for every resource type
 */
- (NSArray *)everyResourceType
{
	SInt16 				theNumOfTypes;
	NSMutableArray		* theTypesArray = nil;
	SInt16				theIndex;

	NSAssert( sizeof(ResType) <= sizeof(unsigned long) ,@"WARNING: everyResourceType assumes that ResType is the same size as unsigned long" );

	theNumOfTypes = Count1Types ();

	if( noErr ==  ResError( ) )
	{
		theTypesArray = [NSMutableArray arrayWithCapacity:theNumOfTypes];

		for( theIndex = 1; theIndex <= theNumOfTypes; theIndex++ )
		{
			ResType		theResType;
			Get1IndType ( &theResType, theIndex );
			if( noErr ==  ResError( ) )
				[theTypesArray addObject:[NSNumber numberWithUnsignedLong:theResType]];
			else
				NSLog( @"Could not get type for resource %i", theIndex);
		}
	}
	else
	{
		NSLog( @"Could not get number of resource types" );
	}

	return theTypesArray;
}

/*
 * removeType: Id:
 */
- (BOOL)removeType:(ResType)aType Id:(short int)anId
{
	BOOL removeResourceFunction( Handle aResHandle, ResType type, NSString * aName, short int Id, void * aContext );
	
	return operateOnResourceUsingFunction( fileReference, aType, nil, anId, removeResourceFunction,  NULL);
}
	BOOL removeResourceFunction( Handle aResHandle, ResType aType, NSString * aName, short int anId, void * aContext )
	{
		if( aResHandle )
			RemoveResource( aResHandle );		// Disposed of in current resource file
		return !aResHandle || noErr == ResError( );
	}

/*
* nameOfResourceType:Id:
*/
- (NSString *)nameOfResourceType:(ResType)aType Id:(short int)anId
{
	BOOL getNameFunction( Handle resHandle, ResType type, NSString * name, short int Id, void * context );
	NSString		* theString = nil;

	if( operateOnResourceUsingFunction( fileReference, aType, nil, anId, getNameFunction, (void*)&theString ) )
		return theString;
	else
		return nil;

}
	BOOL getNameFunction( Handle aResHandle, ResType aType, NSString * aName, short int anId, void * aContext )
	{
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
 * getId:OfResourceType:Id:
 */
- (BOOL)getId:(short int *)anId ofResourceType:(ResType)aType named:(NSString *)aName
{
	BOOL getIdFunction( Handle resHandle, ResType type, NSString * name, short int Id, void * context );
	return operateOnResourceUsingFunction( fileReference, aType, aName, 0, getIdFunction, NULL );
}
	BOOL getIdFunction( Handle aResHandle, ResType aType, NSString * aName, short int anId, void * aContext  )
	{
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
 * -attributeFlags:forResourceType:Id:
 */
- (BOOL)getAttributeFlags:(short int*)attributes forResourceType:(ResType)aType Id:(short int)anId
{
	BOOL getAttributesFunction( Handle aResHandle, ResType type, NSString * aName, short int Id, void * aContext );
	return operateOnResourceUsingFunction( fileReference, aType, nil, anId, getAttributesFunction, (void*)attributes );
}
	BOOL getAttributesFunction( Handle aResHandle, ResType aType, NSString * aName, short int anId, void * aContext )
	{
		short int		* theAttributes = (short int*)aContext;
		if( aResHandle )
		{
			*theAttributes = GetResAttrs( aResHandle );
			return noErr ==  ResError( );
		}
	
		return NO;
	}

/*
 * -setAttributeFlags:forResourceType:Id:
 */
- (BOOL)setAttributeFlags:(short int)attributes forResourceType:(ResType)aType Id:(short int)anId
{
	BOOL		setAttributesFunction( Handle resHandle, ResType type, NSString * aName, short int Id, void * context );
	BOOL				theSuccess;

	NSLog(@"WARRING: Currently the setAttributeFlags:forResourceType:Id: does not work");
	theSuccess = operateOnResourceUsingFunction( fileReference, aType, nil, anId, setAttributesFunction, &attributes );
	return theSuccess;
}
	BOOL setAttributesFunction( Handle aResHandle, ResType aType, NSString * aName, short int anId, void * aContext  )
	{
		short int		theAttributes = *(short int*)aContext;
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
 * -dataForEntireResourceFork
 */
- (NSData *)dataForEntireResourceFork
{
	NSMutableData		* theData = nil;
	ByteCount			theByteCount;
	signed long long	theForkSize;
	
	if( FSGetForkSize( fileReference, &theForkSize ) == noErr && theForkSize <= UINT_MAX )
	{
		theData = [NSMutableData dataWithLength:theForkSize];
		if( FSReadFork( fileReference, fsFromStart, 0, theForkSize, [theData mutableBytes], &theByteCount ) != noErr || theByteCount != theForkSize )
			theData = nil;
	}

	return theData;
}

/*
 * -writeEntireResourceFork:
 */
- (BOOL)writeEntireResourceFork:(NSData *)aData
{
	ByteCount		theWrittenBytes;
	unsigned int	theDataLength;

	theDataLength = [aData length];

	// return true if aData exists, length not zero, write succeeds, write length equals data length
	return aData && theDataLength != 0 && FSWriteFork( fileReference, fsFromStart, 0, theDataLength, [aData bytes], &theWrittenBytes ) == noErr && theDataLength == theWrittenBytes;
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

BOOL operateOnResourceUsingFunction( short int afileRef, ResType aType, NSString * aName, short int anId, BOOL (*aFunction)(Handle,ResType,NSString*,short int,void*), void * aContext )
{
	Handle		theResHandle = NULL;
	short int	thePreviousRefNum;
	Str255		thePName;
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

/*
 * implementation NSData (NDResourceFork)
 */
@implementation NSData (NDResourceFork)

/*
 * +dataWithResourceForkContentsOfURL:type:Id:
 */
+ (NSData *)dataWithResourceForkContentsOfURL:(NSURL *)aURL type:(ResType)aType Id:(short int)anID
{
	NDResourceFork		* theResourceFork = [[NDResourceFork alloc] initForReadingAtURL:aURL];
	NSData				* theData = [theResourceFork dataForType:aType Id:anID];
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
	[theResourceFork release];
	return theData;
}

/*
 * +dataWithResourceForkContentsOfFile:type:Id:
 */
+ (NSData *)dataWithResourceForkContentsOfFile:(NSString *)aPath type:(ResType)aType Id:(short int)anID
{
	NDResourceFork		* theResourceFork = [[NDResourceFork alloc] initForReadingAtPath:aPath];
	NSData				* theData = [theResourceFork dataForType:aType Id:anID];
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
	[theResourceFork release];
	return theData;
}

/*
 * -writeToResourceForkURL:type:Id:name:
 */
- (BOOL)writeToResourceForkURL:(NSURL *)aURL type:(ResType)aType Id:(int)anId name:(NSString *)aName
{
	BOOL					theResult = NO;
	NDResourceFork		* theResourceFork = [[NDResourceFork alloc] initForWritingAtURL:aURL];
	if( theResourceFork )
	{
		theResult = [theResourceFork addData:self type:aType Id:anId name:aName];
		[theResourceFork release];
	}
	return theResult;
}

/*
 * -writeToResourceForkFile:ype:Id:name:
 */
- (BOOL)writeToResourceForkFile:(NSString *)aPath type:(ResType)aType Id:(int)anId name:(NSString *)aName
{
	BOOL					theResult = NO;
	NDResourceFork		* theResourceFork = [[NDResourceFork alloc] initForWritingAtPath:aPath];
	if( theResourceFork )
	{
		theResult = [theResourceFork addData:self type:aType Id:anId name:aName];
		[theResourceFork release];
	}
	return theResult;
}

@end



