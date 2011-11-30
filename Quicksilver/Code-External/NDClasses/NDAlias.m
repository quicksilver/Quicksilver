/*
	NDAlias.m

	Created by Nathan Day on 07.02.02 under a MIT-style license.
	Copyright (c) 2008-2011 Nathan Day

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
 */

#import "NDAlias.h"
#import "NSURL+NDCarbonUtilities.h"

@interface NDAlias (Private)
- (NSData *)createAliasRecordDataForURL:(NSURL *)aURL fromURL:(NSURL *)aFromURL;
@end

/*
	NDDataForAliasHandle: - attempt to create an NSData representation of an AliasHandle
 */
static NSData * NDDataForAliasHandle (AliasHandle anAliasHandle)
{
	NSData * aliasData = nil;
	if (anAliasHandle && *anAliasHandle)
	{
		Size size = GetHandleSize((Handle) anAliasHandle);
		if (size > 0)
		{
			aliasData = [NSData dataWithBytes:*anAliasHandle length:(NSUInteger)size];
		}
	}
	
	return aliasData;
}


@implementation NDAlias

/*
	aliasWithURL:
 */
+ (id)aliasWithURL:(NSURL *)aURL
{
	return [[[self alloc] initWithURL:aURL] autorelease];
}

/*
	aliasWithURL:fromURL:
 */
+ (id)aliasWithURL:(NSURL *)aURL fromURL:(NSURL *)aFromURL
{
	return [[[self alloc] initWithURL:aURL fromURL:aFromURL] autorelease];
}

/*
	aliasWithPath:
 */
+ (id)aliasWithPath:(NSString *)aPath
{
	return [[[self alloc] initWithPath:aPath] autorelease];
}

/*
	aliasWithPath:fromPath:
 */
+ (id)aliasWithPath:(NSString *)aPath fromPath:(NSString *)aFromPath
{
	return [[[self alloc] initWithPath:aPath fromPath:aFromPath] autorelease];
}

/*
	aliasWithData:
 */
+ (id)aliasWithData:(NSData *)aData
{
	return [[[self alloc] initWithData:aData] autorelease];
}

/*
	aliasWithFSRef:
 */
+ (id)aliasWithFSRef:(FSRef *)aFSRef
{
	return [[[self alloc] initWithFSRef:aFSRef] autorelease];
}

/*
	initWithPath:
 */
- (id)initWithPath:(NSString *)aPath
{
	return [self initWithPath:aPath fromPath:nil];
}

/*
	initWithPath:fromPath:
 */
- (id)initWithPath:(NSString *)aPath fromPath:(NSString *)aFromPath
{
#if (MAC_OS_X_VERSION_MIN_REQUIRED >= 1050)
	NSFileManager * fileManager = [[[NSFileManager alloc] init] autorelease];
#else
	NSFileManager * fileManager = [NSFileManager defaultManager];
#endif
	
	if( aPath && [fileManager fileExistsAtPath:aPath] )
	{
		if( aFromPath )
		{
			if( [fileManager fileExistsAtPath:aFromPath] )
			{
				self = [self initWithURL:[NSURL fileURLWithPath:aPath] fromURL:[NSURL fileURLWithPath:aFromPath]];
			}
			else
			{
				[super dealloc];
				self = nil;
			}
		}
		else
		{
			self = [self initWithURL:[NSURL fileURLWithPath:aPath] fromURL:nil];
		}
	}
	else
	{
		[super dealloc];
		self = nil;
	}
	
	return self;
}

/*
	initWithURL:
 */
- (id)initWithURL:(NSURL *)aURL
{
	return [self initWithURL:aURL fromURL:nil];
}

/*
	initWithURL:fromURL:
 */
- (id)initWithURL:(NSURL *)aURL fromURL:(NSURL *)aFromURL
{
	if( (self = [super init]) != nil )
	{
		NSData* aliasData = nil;
		if( aURL )
		{
			aliasData = [self createAliasRecordDataForURL:aURL fromURL:aFromURL];
		}
		
		if ( aliasData )
		{
			// Call the designated initializer
			self = [self initWithData:aliasData];
		}
		else
		{
			[super dealloc];
			self = nil;
		}
	}
	
	return self;
}

/*
	initWithCoder:
 */
- (id)initWithCoder:(NSCoder *)aDecoder
{
	// Call the designated initializer
	return [self initWithData:[aDecoder decodeDataObject]];
}

/*
	initWithData: - the designated initializer!
 */
- (id)initWithData:(NSData *)aData
{
	if( (self = [super init]) != nil )
	{
		const void* dataBytes = [aData bytes];
		NSUInteger dataLength = [aData length];
		if( dataBytes && (dataLength > 0) && PtrToHand( dataBytes, (Handle*)&aliasHandle, dataLength ) == noErr )
		{
			changed = false;

			// Because an alias is more of a model-layer object, we don't want the OS popping up a UI when we try to resolve an alias, at least not by default.
			mountFlags = kResolveAliasFileNoUI;
		}
		else
		{
			[super dealloc];
			self = nil;
		}

		// To prevent premature collection.  (Under GC, the given NSData may have no strong references for all we know, and our inner pointer 'dataBytes' does not keep the NSData alive.  So without this, the data could be collected before PtrToHand() is called!)
		[aData self];
	}

	return self;
}

/*
	initWithFSRef:
 */
- (id)initWithFSRef:(FSRef *)aFSRef
{
	NSData* aliasData = nil;

	AliasHandle anAliasHandle = nil;
	OSErr theError = FSNewAlias( NULL, aFSRef, &anAliasHandle );
	if ( !theError )
	{
		aliasData = NDDataForAliasHandle (anAliasHandle);
	}

	if ( aliasData )
	{
		// Call the designated initializer
		self = [self initWithData:aliasData];
	}
	else
	{
		[super dealloc];
		self = nil;
	}

	return self;
}


/*
	encodeWithCoder:
 */
- (void)encodeWithCoder:(NSCoder *)anEncoder
{
	[anEncoder encodeDataObject:[self data]];
}

/*
	dealloc
 */
- (void)dealloc
{
	if ( aliasHandle )
	{
		DisposeHandle( (Handle)aliasHandle );
		aliasHandle = NULL;
	}
	[super dealloc];
}

/*
	finalize
 */
- (void)finalize
{
	/* Important: finalize methods must be threadsafe!  DisposeHandle() is threadsafe since 10.3. */
	if ( aliasHandle )
	{
		DisposeHandle( (Handle)aliasHandle );
		aliasHandle = NULL;
	}
	[super finalize];
}

/*
	-setAllowUserInteraction:
 */
- (void)setAllowUserInteraction:(BOOL)aFlag
{
	mountFlags = aFlag ? (mountFlags & ~kResolveAliasFileNoUI) : (mountFlags | kResolveAliasFileNoUI);
}

/*
	-allowUserInteraction
 */
- (BOOL)allowUserInteraction
{
	return mountFlags & kResolveAliasFileNoUI ? NO : YES;
}

/*
	-setTryFileIDFirst:
 */
- (void)setTryFileIDFirst:(BOOL)aFlag
{
	mountFlags = aFlag ? (mountFlags | kResolveAliasTryFileIDFirst) : (mountFlags & ~kResolveAliasTryFileIDFirst);
}

/*
	-tryFileIDFirst
 */
- (BOOL)tryFileIDFirst
{
	return mountFlags & kResolveAliasTryFileIDFirst ? YES : NO;
}

/*
	-getFSRef:
 */
- (BOOL)getFSRef:(FSRef *)aFsRef
{
	BOOL		success = NO;
	if ( aFsRef )
	{
		OSErr				theError;
		theError = FSResolveAliasWithMountFlags( NULL, aliasHandle, aFsRef, &changed, mountFlags );
		success = theError == noErr;
	}
	return success;
}

/*
	URL
 */
- (NSURL *)URL
{
	id					theURL = nil;
	BOOL				success;
	FSRef				theTarget;
	success = [self getFSRef:&theTarget];
	if( success )
	{
		theURL = [NSURL URLWithFSRef:&theTarget];
	}
	return theURL;
}

/*
	url - deprecated method.  Use -URL instead.
 */
- (NSURL *)url
{
	return [self URL];
}

/*
	path
 */
- (NSString *)path
{
	return [[self URL] path];
}

/*
	changed
 */
- (BOOL)changed
{
	return changed ? YES : NO;
}

/*
	setURL:
 */
- (BOOL)setURL:(NSURL *)aURL
{
	return [self setURL:aURL fromURL:nil];
}

/*
	setURL:
 */
- (BOOL)setURL:(NSURL *)aURL fromURL:(NSURL *)aFromURL
{
	OSErr					theError = !noErr;
	FSRef					theReference,
							theFromReference;

	if( aURL != nil && [aURL isFileURL] && [aURL getFSRef:&theReference] )
	{
		if( aFromURL != nil && [aFromURL isFileURL] && [aFromURL getFSRef:&theFromReference] )
			theError = FSUpdateAlias( &theFromReference, &theReference, aliasHandle, &changed );
		else
			theError = FSUpdateAlias( NULL, &theReference, aliasHandle, &changed );
	}

	return theError == noErr;
}

/*
	setPath:
 */
- (BOOL)setPath:(NSString *)aPath
{
	return [self setPath:aPath fromPath:nil];
}

/*
	setPath:fromPath:
 */
- (BOOL)setPath:(NSString *)aPath fromPath:(NSString *)aFromPath
{
	BOOL		theSuccess = NO;
	
#if (MAC_OS_X_VERSION_MIN_REQUIRED >= 1050)
	NSFileManager * fileManager = [[[NSFileManager alloc] init] autorelease];
#else
	NSFileManager * fileManager = [NSFileManager defaultManager];
#endif
	
	if( [fileManager fileExistsAtPath:aPath] )
	{
		if( [fileManager fileExistsAtPath:aFromPath] )
			theSuccess = [self setURL:[NSURL fileURLWithPath:aPath] fromURL:[NSURL fileURLWithPath:aFromPath]];
		else
			theSuccess = [self setURL:[NSURL fileURLWithPath:aPath] fromURL:nil];
	}

	return theSuccess;
}

/*
	description
 */
- (NSString *)description
{
	return [self path];
}

/*
	debugDescription
 */
- (NSString *)debugDescription
{
	NSString * str = [NSString stringWithFormat:@"aliasHandle %p, changed %d, mountFlags %x, lastKnownPath %@",
					  aliasHandle,
					  changed,
					  mountFlags,
					  [self lastKnownPath]];
	
	return str;
}

/*
	data
 */
- (NSData *)data
{
	NSData * theData = NDDataForAliasHandle (aliasHandle);

	return theData;
}

/*
	displayName
 */
- (NSString *)displayName
{
#if (MAC_OS_X_VERSION_MIN_REQUIRED >= 1050)
	NSFileManager * fileManager = [[[NSFileManager alloc] init] autorelease];
#else
	NSFileManager * fileManager = [NSFileManager defaultManager];
#endif
	
	return [fileManager displayNameAtPath:[self path]];
}

/*
	lastKnownPath
 */
- (NSString *)lastKnownPath
{
	CFStringRef path = nil;
	(void)FSCopyAliasInfo (aliasHandle, NULL, NULL, &path, NULL, NULL);

	/* To support GC and non-GC, we need this contortion. */
	return [NSMakeCollectable(path) autorelease];
}

/*
	lastKnownName
 */
- (NSString *)lastKnownName
{
	CFStringRef path = nil;
	HFSUniStr255 name;
	OSStatus err = FSCopyAliasInfo (aliasHandle, &name, NULL, NULL, NULL, NULL);
	if ( !err )
	{
		path = FSCreateStringFromHFSUniStr (NULL, &name);
	}

	/* To support GC and non-GC, we need this contortion. */
	return [NSMakeCollectable(path) autorelease];
}

/*
	lastKnownVolumeName
 */
- (NSString *)lastKnownVolumeName
{
	CFStringRef path = nil;
	HFSUniStr255 name;
	OSStatus err = FSCopyAliasInfo (aliasHandle, NULL, &name, NULL, NULL, NULL);
	if ( !err )
	{
		path = FSCreateStringFromHFSUniStr (NULL, &name);
	}

	/* To support GC and non-GC, we need this contortion. */
	return [NSMakeCollectable(path) autorelease];
}

/*
	resolveIfIsAliasFile:
 */
- (NDAlias *)resolveIfIsAliasFile:(BOOL *)wasSuccessful
{
	// Assume failure
	BOOL success = NO;

	// Return self unless we are later able to resolve to something else
	NDAlias * aliasToReturn = self;

	FSRef fsRef;
	if ( [self getFSRef:&fsRef] )
	{
		Boolean isAliasFile, isFolder;
		OSErr err = FSIsAliasFile (&fsRef, &isAliasFile, &isFolder);
		if ( !err )
		{
			if ( isAliasFile )
			{
				Boolean isTargetFolder, wasAliased;
				err = FSResolveAliasFileWithMountFlags (&fsRef, true, &isTargetFolder, &wasAliased, mountFlags);
				if ( !err )
				{
					NDAlias * aliasToOriginal = [NDAlias aliasWithFSRef:&fsRef];
					if (aliasToOriginal)
					{
						aliasToReturn = aliasToOriginal;
						success = YES;
					}
				}
			}
			else
			{
				success = YES;
			}
		}
	}

	if ( wasSuccessful )
	{
		*wasSuccessful = success;
	}

	return aliasToReturn;
}

/*
	isEqualToAlias:
 */
- (BOOL)isEqualToAlias:(id)anOtherObject
{
	/* Two NDAliases are defined as equal if they are the exact same object or if they resolve to equal FSRefs */
	BOOL		theEqual = (anOtherObject == self);
	if (!theEqual && [anOtherObject isKindOfClass:[NDAlias class]])
	{
		FSRef		theFSRef1,
					theFSRef2;
		
		if ( [self getFSRef:&theFSRef1] )
		{
			if ( [anOtherObject getFSRef:&theFSRef2] )
				theEqual = (FSCompareFSRefs (&theFSRef1, &theFSRef2) == noErr);
		}
	}
	
	return theEqual;
}

/*
	isAliasCollectionResolvable:
 */
+ (BOOL)isAliasCollectionResolvable:(NSObject<NSFastEnumeration>*)aCollection
{
	BOOL resolvable = NO;
	
	FSRef ref;
	for (NDAlias* alias in aCollection)
	{
		resolvable = [alias getFSRef:&ref];
		if (!resolvable)
		{
			break;
		}
	}
	
	return resolvable;
}

/*
	isAliasCollection:equalToAliasCollection:
 */
+ (BOOL)isAliasCollection:(id)aCollection1 equalToAliasCollection:(id)aCollection2
{
	BOOL collectionsMatch = NO;
	
	// The cast is merely to silence a compiler warning, either NSSet or NSArray is acceptable (or in fact anything that responds to 'count' and conforms to NSFastEnumeration).
	if ([(NSArray*)aCollection1 count] == [(NSArray*)aCollection2 count])
	{
		collectionsMatch = YES;
		for (NDAlias* alias1 in aCollection1)
		{
			BOOL foundAlias1 = NO;
			for (NDAlias* alias2 in aCollection2)
			{
				if ([alias1 isEqualToAlias:alias2])
				{
					foundAlias1 = YES;
					break;
				}
			}
			if (!foundAlias1)
			{
				collectionsMatch = NO;
				break;
			}
		}
	}
	
	return collectionsMatch;
}

/*
	arrayOfAliasesFromArrayOfData:
 */
+ (NSArray*)arrayOfAliasesFromArrayOfData:(NSArray*)aDataArray
{
	NSMutableArray* array = [NSMutableArray array];
	for (NSData* aliasData in aDataArray)
	{
		NDAlias* alias = [NDAlias aliasWithData:aliasData];
		if (alias)
		{
			[array addObject:alias];
		}
	}
	
	return array;
}

/*
	arrayOfDataFromArrayOfAliases:
 */
+ (NSArray*)arrayOfDataFromArrayOfAliases:(NSArray*)anAliasArray
{
	NSMutableArray* array = [NSMutableArray array];
	for (NDAlias* alias in anAliasArray)
	{
		NSData* data = [alias data];
		if (data)
		{
			[array addObject:data];
		}
	}
	
	return array;
}

@end

@implementation NDAlias (Private)

/*
	createAliasRecordDataForURL:fromURL:
 */
- (NSData *)createAliasRecordDataForURL:(NSURL *)aURL fromURL:(NSURL *)aFromURL
{
	AliasHandle		anAliasHandle = NULL;
	OSErr			theError = noErr;
	FSRef			theReference,
					theFromReference;

	if( aURL != nil && [aURL isFileURL] && [aURL getFSRef:&theReference] )
	{
		if( aFromURL != nil && [aFromURL isFileURL] && [aFromURL getFSRef:&theFromReference] )
			theError = FSNewAlias( &theFromReference, &theReference, &anAliasHandle );
		else
			theError = FSNewAliasMinimal( &theReference, &anAliasHandle );
	}

	NSData* aliasData = nil;
	if ( !theError )
	{
		aliasData = NDDataForAliasHandle(anAliasHandle);
	}

	return aliasData;
}

@end
