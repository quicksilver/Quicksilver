/*
	NDAlias.m
	NDAlias

	Created by Nathan Day on Thu Feb 07 2002.
 *  Copyright 2002-2008 Nathan Day. All rights reserved.
 */

#import "NDAlias.h"
#import "NSURL+NDCarbonUtilities.h"

@interface NDAlias (Private)
- (NSUInteger)hash;
- (BOOL)isEqual:(id)otherObject;
- (NSData *)dataForAliasHandle:(AliasHandle)anAliasHandle;
- (NSData *)createAliasRecordDataForURL:(NSURL *)aURL fromURL:(NSURL *)aFromURL;
@end

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

+ (id)aliasWithData:(NSData *)aData
{
	return [[[self alloc] initWithData:aData] autorelease];
}

+ (id)aliasWithFSRef:(FSRef *)aFSRef
{
	return [[[self alloc] initWithFSRef:aFSRef] autorelease];
}

/*
	initWithPath:fromPath:
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
	if( aPath && [[NSFileManager defaultManager] fileExistsAtPath:aPath] )
	{
		if( aFromPath && [[NSFileManager defaultManager] fileExistsAtPath:aFromPath] )
			return [self initWithURL:[NSURL fileURLWithPath:aPath] fromURL:[NSURL fileURLWithPath:aFromPath]];
		else
			return [self initWithURL:[NSURL fileURLWithPath:aPath] fromURL:nil];
	}
	else
	{
		[self release];
		return nil;
	}
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
			[self release];
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
		}
		else
		{
			[self release];
			self = nil;
		}
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
	if ( !theError && anAliasHandle )
	{
		aliasData = [self dataForAliasHandle:anAliasHandle];
	}
	
	if ( aliasData )
	{
		// Call the designated initializer
		self = [self initWithData:aliasData];
	}
	else
	{
		[self release];
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

#ifndef __OBJC_GC__

/*
	dealloc
 */
- (void)dealloc
{
	DisposeHandle( (Handle)aliasHandle );
	[super dealloc];
}

#else

/*
	finalize
 */
- (void)finalize
{
	/* Important: finalize methods must be thread-safe!  DisposeHandle() is threadsafe since 10.3. */
	DisposeHandle( (Handle)aliasHandle );
	[super finalize];
}

#endif

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
	return changed != false;
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
	BOOL		theSuccess = NO;;
	if( [[NSFileManager defaultManager] fileExistsAtPath:aPath] )
	{
		if( [[NSFileManager defaultManager] fileExistsAtPath:aFromPath] )
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
	data
 */
- (NSData *)data
{
	NSData		* theData = nil;
	if( aliasHandle != NULL )
	{
		theData = [self dataForAliasHandle:aliasHandle];
	}

	return theData;
}

/*
	displayName
 */
- (NSString *)displayName
{
	return [[NSFileManager defaultManager] displayNameAtPath:[self path]];
}


/*
	lastKnownPath
 */
- (NSString *)lastKnownPath
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
	lastKnownName
 */
- (NSString *)lastKnownName
{
	CFStringRef path = nil;
	(void)FSCopyAliasInfo (aliasHandle, NULL, NULL, &path, NULL, NULL);

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
				err = FSResolveAliasFile (&fsRef, true, &isTargetFolder, &wasAliased);
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

@end

@implementation NDAlias (Private)

/*
	hash
 */
- (NSUInteger)hash
{
	// TODO It is very important that if two object are equal according to isEqual:
	// that they have the same hash value.  I think we may have a bug here.
	return [[self path] hash];
}

/*
	isEqual:
 */
- (BOOL)isEqual:(id)anOtherObject
{
	/* Two NDAliases are defined as equal if and only if they resolve to equal FSRefs */
	BOOL		theEqual = NO;
	if ([anOtherObject isKindOfClass:[NDAlias class]])
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
	dataForAliasHandle: - create an NSData representation of an AliasHandle
 */
- (NSData *)dataForAliasHandle:(AliasHandle)anAliasHandle
{
	// TODO: consider switching from GetHandleSize() to GetAliasSize() ?
	NSData* aliasData = [NSData dataWithBytes:*anAliasHandle length:GetHandleSize((Handle) anAliasHandle)];
 
	return aliasData;
}

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
	if ( !theError && anAliasHandle )
	{
		aliasData = [self dataForAliasHandle:anAliasHandle];
	}
	
	return aliasData;
}

@end
