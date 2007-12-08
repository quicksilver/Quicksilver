/*
 *  NDAlias.m
 *  NDAliasProject
 *
 *  Created by Nathan Day on Thu Feb 07 2002.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "NDAlias.h"
#import "NSURL+NDCarbonUtilities.h"

@interface NDAlias (Private)
- (BOOL)createAliasRecordFor:(NSURL *)aURL fromURL:(NSURL *)aFromURL;
@end

@implementation NDAlias

/*
 * aliasWithURL:
 */
+ (id)aliasWithURL:(NSURL *)aURL
{
	return [[[self alloc] initWithURL:aURL] autorelease];
}

/*
 * aliasWithURL:fromURL:
 */
+ (id)aliasWithURL:(NSURL *)aURL fromURL:(NSURL *)aFromURL
{
	return [[[self alloc] initWithURL:aURL fromURL:aFromURL] autorelease];
}

/*
 * aliasWithPath:
 */
+ (id)aliasWithPath:(NSString *)aPath
{
	return [[[self alloc] initWithPath:aPath] autorelease];
}

/*
 * aliasWithPath:fromPath:
 */
+ (id)aliasWithPath:(NSString *)aPath fromPath:(NSString *)aFromPath
{
	return [[[self alloc] initWithPath:aPath fromPath:aFromPath] autorelease];
}

+ (id)aliasWithData:(NSData *)aData
{
	return [[[self alloc] initWithData:aData] autorelease];
}

/*
 * initWithPath:fromPath:
 */
- (id)initWithPath:(NSString *)aPath
{
	return [self initWithPath:aPath fromPath:nil];
}

/*
 * initWithPath:fromPath:
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
 * initWithURL:
 */
- (id)initWithURL:(NSURL *)aURL
{
	return [self initWithURL:aURL fromURL:nil];
}

/*
 * initWithURL:fromURL:
 */
- (id)initWithURL:(NSURL *)aURL fromURL:(NSURL *)aFromURL
{
	if( (self = [self init]) != nil )
	{
		if( aURL && [self createAliasRecordFor:aURL fromURL:aFromURL] )
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
 * initWithCoder:
 */
- (id)initWithCoder:(NSCoder *)aDecoder
{
	return [self initWithData:[aDecoder decodeDataObject]];
}


- (id)initWithData:(NSData *)aData
{
	if( (self = [self init]) != nil )
	{
		if( aData && PtrToHand( [aData bytes], (Handle*)&aliasHandle, [aData length] ) == noErr )
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
 * encodeWithCoder:
 */
- (void)encodeWithCoder:(NSCoder *)anEncoder
{
	[anEncoder encodeDataObject:[self data]];	
}

/*
 * dealloc
 */
- (void)dealloc
{
	DisposeHandle( (Handle)aliasHandle );
	[super dealloc];
}

/*
 * -setAllowUserInteraction:
 */
- (void)setAllowUserInteraction:(BOOL)aFlag
{
	mountFlags = aFlag ? (mountFlags & ~kResolveAliasFileNoUI) : (mountFlags | kResolveAliasFileNoUI);
}

/*
 * -allowUserInteraction
 */
- (BOOL)allowUserInteraction
{
	return mountFlags & kResolveAliasFileNoUI ? NO : YES;
}

/*
 * -setTryFileIDFirst:
 */
- (void)setTryFileIDFirst:(BOOL)aFlag
{
	mountFlags = aFlag ? (mountFlags | kResolveAliasTryFileIDFirst) : (mountFlags & ~kResolveAliasTryFileIDFirst);
}

/*
 * -tryFileIDFirst
 */
- (BOOL)tryFileIDFirst
{
	return mountFlags & kResolveAliasTryFileIDFirst ? YES : NO;
}

/*
 * url
 */
- (NSURL *)url
{
	id					theURL = nil;
	FSRef				theTarget;
	OSErr				theError;
	if( (theError = FSResolveAliasWithMountFlags( NULL, aliasHandle, &theTarget, &changed, mountFlags )) == noErr )
	{
		theURL = [NSURL URLWithFSRef:&theTarget];
	}
	return theURL;
}

/*
 * path
 */
- (NSString *)path
{
	return [[self url] path];
}

/*
 * changed
 */
- (BOOL)changed
{
	return changed != false;
}

/*
 * setURL:
 */
- (BOOL)setURL:(NSURL *)aURL
{
	return [self setURL:aURL fromURL:nil];
}

/*
 * setURL:
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
 * setPath:
 */
- (BOOL)setPath:(NSString *)aPath
{
	return [self setPath:aPath fromPath:nil];
}

/*
 * setPath:fromPath:
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
 * description
 */
- (NSString *)description
{
	return [self path];
}

- (NSData *)data
{
	NSData		* theData = nil;
	if( aliasHandle != NULL )
	{
		HLock((Handle)aliasHandle);
		theData = [NSData dataWithBytes:*aliasHandle length:GetHandleSize((Handle) aliasHandle)];
		HUnlock((Handle)aliasHandle);
	}

	return theData;
}

@end

@implementation NDAlias (Private)

/*
 * createAliasRecordFor:fromURL:
 */
- (BOOL)createAliasRecordFor:(NSURL *)aURL fromURL:(NSURL *)aFromURL
{
	OSErr					theError = noErr;
	FSRef					theReference,
							theFromReference;

	if( aURL != nil && [aURL isFileURL] && [aURL getFSRef:&theReference] )
	{
		if( aFromURL != nil && [aFromURL isFileURL] && [aFromURL getFSRef:&theFromReference] )
		{
			theError = FSNewAlias( &theFromReference, &theReference, &aliasHandle );
		}
		else
		{
			theError = FSNewAliasMinimal( &theReference, &aliasHandle );
		}
	}

	return theError == noErr;
}

@end