/* =============================================================================
	FILE:		UKDirectoryEnumerator.m
	PROJECT:	Filie

    COPYRIGHT:  (c) 2004 M. Uli Kusterer, all rights reserved.
    
	AUTHORS:	M. Uli Kusterer - UK
    
    LICENSES:   MIT License

	REVISIONS:
		2006-03-13	UK	Clarified license, miscellaneous additions.
		2004-04-15	UK	Created.
   ========================================================================== */

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import "UKDirectoryEnumerator.h"
#import "NSString+CarbonUtilities.h"


// -----------------------------------------------------------------------------
//  Prototypes:
// -----------------------------------------------------------------------------

NSDictionary*   UKDictionaryFromFSCatInfo( FSCatalogInfo* currInfo, FSCatalogInfoBitmap whichInfo );
void            UKFSCatInfoFromDictionary( NSDictionary* attrs, FSCatalogInfo* currInfo, FSCatalogInfoBitmap* whichInfo );


@implementation UKDirectoryEnumerator

+(id)					enumeratorWithPath: (NSString*)fpath
{
	return [[[[self class] alloc] initWithPath: fpath] autorelease];
}

+(id)					enumeratorWithPath: (NSString*)fpath cacheSize: (ItemCount)n
{
	return [[[[self class] alloc] initWithPath: fpath cacheSize: n] autorelease];
}

// -----------------------------------------------------------------------------
//  initWithPath:
//      Convenience initializer. Uses a default cache size.
//
//  REVISIONS:
//      2004-11-11  UK  Documented.
// -----------------------------------------------------------------------------

-(id)		initWithPath: (NSString*)fpath
{
	return [self initWithPath: fpath cacheSize: UKDirectoryEnumeratorCacheSize];
}


// -----------------------------------------------------------------------------
//  initWithPath:cacheSize:
//      Designated initializer. Opens our FSIterator and initializes our
//      cache.
//
//  REVISIONS:
//      2004-11-11  UK  Documented.
// -----------------------------------------------------------------------------

-(id)		initWithPath: (NSString*)fpath cacheSize: (ItemCount)n
{
	self = [super init];
	if( self )
	{
		FSRef		container;
		OSErr		err = noErr;
		
		whichInfo = kFSCatInfoNone;
		
		if( ![fpath getFSRef: &container]
			|| (err = FSOpenIterator( &container, kFSIterateFlat, &iterator )) != noErr )
		{
            if( err == noErr )  // getFSRef failed.
                err = fnfErr;   // Invalid path.
			NSLog(@"UKDirectoryEnumerator::initWithPath: - MacOS Error ID= %d",err);
			[self autorelease];
			return nil;
		}
        
        fpath = [NSString stringWithFSRef: &container]; // In case it's a link or an alias that got resolved.
        prefixlen = [fpath length] +(([fpath characterAtIndex: [fpath length] -1] == '/') ? 0 : 1);
		
		[self setCacheSize: n];
	}
	
	return self;
}


// -----------------------------------------------------------------------------
//  dealloc:
//      Close FSIterator that we wrap with this object.
//
//  REVISIONS:
//		2005-10-15	UK	Made this release infoCache. Thanks Nicholas Jitkoff!
//      2004-11-11  UK  Documented.
// -----------------------------------------------------------------------------

-(void) dealloc
{
	if( cache )
		free( cache );
	
	if( infoCache )
		free( infoCache );
	
	if( iterator != NULL )
		FSCloseIterator( iterator );
    
	[super dealloc];
}


// -----------------------------------------------------------------------------
//  iterator:
//      Let those Carbon fans manually mess with the FSIterator if they have
//      a need to.
//
//  REVISIONS:
//      2004-11-11  UK  Documented.
// -----------------------------------------------------------------------------

-(FSIterator)   iterator
{
	return iterator;
}


// -----------------------------------------------------------------------------
//  nextObjectFullPath:
//      Fetch the next file path from the cache. The Cache contains FSRefs, so
//      this will convert the FSRef into an NSString. If the cache is empty,
//      this will get the next batch of FSRefs into the cache using the Carbon
//      FSGetCatalogInfoBulk call, and also cache their file info.
//
//  REVISIONS:
//      2004-11-11  UK  Documented.
// -----------------------------------------------------------------------------

-(id)   nextObjectFullPath
{
	if( currIndex >= foundItems )
	{
		OSErr err = FSGetCatalogInfoBulk( iterator, cacheSize, &foundItems,
                                            NULL, whichInfo, infoCache,
                                            cache, (FSSpec*) NULL, (HFSUniStr255*) NULL);
		if( err != noErr && err != errFSNoMoreItems )
		{
			NSLog(@"UKDirectoryEnumerator::nextObjectFullPath - MacOS Error ID= %d",err);
			return nil;
		}
		
		currIndex = 0;
		if( foundItems == 0 )
        {
            if( err != errFSNoMoreItems )
                NSLog(@"UKDirectoryEnumerator::nextObjectFullPath - FSCatalogInfoBulk returned 0 items, but not errFSNoMoreItems.");
			return nil;
        }
	}
	
	return [NSString stringWithFSRef: &(cache[currIndex++]) ];
}


// -----------------------------------------------------------------------------
//  nextObject:
//      Fetch the next file name from the cache. This is made to work the same
//      way as NSDirectoryEnumerator, and thus only returns the filenames. If
//      you want the absolute pathname, use nextObjectFullPath, which this
//      calls internally.
//
//  REVISIONS:
//      2004-11-11  UK  Documented.
// -----------------------------------------------------------------------------

-(id)   nextObject
{
    NSString*   fname = [self nextObjectFullPath];
    if( !fname )
        return nil;
    return [fname substringWithRange: NSMakeRange(prefixlen,[fname length] -prefixlen)];    // Remove the prefix (parent folder) from this path to make it relative.
}


// -----------------------------------------------------------------------------
//  cacheExhausted:
//      Tells you whether the next call to nextObject will cause a reload of the
//      cache. You usually don't need this, but sometimes it's useful for
//      deciding when to update progress information. If there will be a short
//      pause while the File Manager caches some more FSRefs, you might as well
//      accept the overhead of drawing new status info to the screen.
//
//  REVISIONS:
//      2004-11-11  UK  Documented.
// -----------------------------------------------------------------------------

-(BOOL) cacheExhausted
{
	return( currIndex >= foundItems );
}


// -----------------------------------------------------------------------------
//  fileAttributes:
//      This is basically the same as NSDirectoryEnumerator's fileAttributes
//      method. However, what you get here depends on what flags you specified
//      to setDesiredInfo:, which defaults to kFSCatInfoNone, which means you
//      get an empty dictionary here if you don't explicitly ask for info.
//
//      Depending on what you pass to setDesiredInfo:, you can even get
//      additional info that you wouldn't get from an NSDirectoryEnumerator.
//      In particular, since we're using Carbon under the hood, we get all the
//      nice info the Finder knows, but other Cocoa apps don't.
//
//      This is an expensive call. If you can, use others like isInvisible or
//      isDirectory.
//
//  REVISIONS:
//      2005-07-03  UK  Extracted CatInfo -> Dictionary code into separate
//                      function UKDictionaryFromFSCatInfo().
//      2004-11-11  UK  Documented.
// -----------------------------------------------------------------------------

#define UK_BTST(f,m)	(((f) & (m)) == (m))    // Shorthand bit-test macro.

-(NSDictionary*)	fileAttributes
{
	if( infoCache == NULL )
		return [NSMutableDictionary dictionary];
	
	FSCatalogInfo*			currInfo = &(infoCache[currIndex -1]);
    
	return UKDictionaryFromFSCatInfo( currInfo, whichInfo );
}


// -----------------------------------------------------------------------------
//  isInvisible:
//      If you passed the kFSCatInfoFinderInfo flag to setDesiredInfo:, this
//      will return the value of the Finder's kIsInvisible file flag. Otherwise
//      this will ruthlessly claim the file was visible.
//
//      This will *not* do any other checks, like whether the file name starts
//      with a period.
//
//  REVISIONS:
//      2004-11-11  UK  Documented.
// -----------------------------------------------------------------------------

-(BOOL)			isInvisible
{
	FSCatalogInfo*			currInfo = &(infoCache[currIndex -1]);

	if( UK_BTST(whichInfo, kFSCatInfoFinderInfo) )
	{
		FileInfo*		fInfo = (FileInfo*) currInfo->finderInfo;
		return UK_BTST(fInfo->finderFlags, kIsInvisible);
	}
	else
		return NO;
}


// -----------------------------------------------------------------------------
//  isDirectory:
//      If you passed the kFSCatInfoNodeFlags flag to setDesiredInfo:, this
//      will tell you whether an item is a directory (aka folder) or not.
//      Otherwise this will ruthlessly claim it was a file.
//
//  REVISIONS:
//      2004-11-11  UK  Documented.
// -----------------------------------------------------------------------------

-(BOOL)			isDirectory
{
	FSCatalogInfo*			currInfo = &(infoCache[currIndex -1]);

	if( UK_BTST(whichInfo, kFSCatInfoNodeFlags) )
		return UK_BTST(currInfo->nodeFlags, kFSNodeIsDirectoryMask);
	else
		return NO;
}


// -----------------------------------------------------------------------------
//  setDesiredInfo:
//      Takes a bit field of or-ed together FSCatalogInfoBitmap flags that
//      control what information will be collected about files. You can then
//      query this information using the fileAttributes, isInvisible and
//      isDirectory methods.
//
//      FSCatalogInfoBitmap and the associated flags are defined in
//      <Carbon/Files.h>.
//
//  REVISIONS:
//      2004-11-11  UK  Documented.
// -----------------------------------------------------------------------------

-(void)			setDesiredInfo: (FSCatalogInfoBitmap)n
{
	if( whichInfo != n )
	{
		whichInfo = n;
		
		if( whichInfo == kFSCatInfoNone && infoCache != NULL )
		{
			free( infoCache );
			infoCache = NULL;
		}
		else if( whichInfo != kFSCatInfoNone && infoCache == NULL )
		{
			infoCache = malloc( sizeof(FSCatalogInfo) * cacheSize );
			if( cache == NULL )
				whichInfo = kFSCatInfoNone;
		}
	}
}


// -----------------------------------------------------------------------------
//  desiredInfo:
//      Returns the flags set using setDesiredInfo:. If you didn't call that,
//      you'll probably get the default kFSCatalogInfoNone.
//
//  REVISIONS:
//      2004-11-11  UK  Documented.
// -----------------------------------------------------------------------------

-(FSCatalogInfoBitmap)  desiredInfo
{
	return whichInfo;
}

#if UKDE_ALLOW_SETWHICHINFO
// -----------------------------------------------------------------------------
//  setWhichInfo: and whichInfo:    *DEPRECATED*
// -----------------------------------------------------------------------------

-(void)			setWhichInfo: (FSCatalogInfoBitmap)n
{
    [self setDesiredInfo: n];
}

-(FSCatalogInfoBitmap)  whichInfo
{
    return [self desiredInfo];
}
#endif


// -----------------------------------------------------------------------------
//  setCacheSize:
//      Controls the size (in number of files) of the cache used when getting
//      the files. The file list is retrieved in batches of that many files,
//      and -nextObject will automatically fetch the next item from the cache
//      and load the next batch into the cache as needed.
//
//      Note that this destroys any currently cached items. So only call this
//      before your first call to -nextObject or when -cacheExhausted is YES.
//
//  REVISIONS:
//      2004-11-11  UK  Documented.
// -----------------------------------------------------------------------------

-(void)			setCacheSize: (ItemCount)c
{
    // Get rid of the old FSRef and FSCatalogInfo caches:
	if( cache )
	{
		free(cache);
		cache = NULL;
	}
	
	if( infoCache )
	{
		free(infoCache);
		infoCache = NULL;
	}
	
    // Allocate new caches of the requested size:
	cache = malloc( sizeof(FSRef) * c );
	if( cache == NULL )
		cacheSize = 0;
	else
		cacheSize = c;
	
	if( whichInfo != kFSCatInfoNone )
	{
		infoCache = malloc( sizeof(FSCatalogInfo) * c );
		if( cache == NULL )
			whichInfo = kFSCatInfoNone;
	}
}


// -----------------------------------------------------------------------------
//  cacheSize:
//      Returns the size (in number of files) of the cache used when getting
//      the files. The file list is retrieved in batches of that many files,
//      and -nextObject will automatically fetch the next item from the cache
//      and load the next batch into the cache as needed.
//
//  REVISIONS:
//      2004-11-11  UK  Documented.
// -----------------------------------------------------------------------------

-(ItemCount)	cacheSize
{
	return cacheSize;
}

@end


@implementation NSFileManager (UKDirectoryEnumeratorVisibleDirectoryContents)

// -----------------------------------------------------------------------------
//  visibleDirectoryContentsAtPath:
//      Lists the contents of a particular directory (aka folder), removing
//      any items that are invisible according to MacOS X conventions. Note
//      that this will not consider "latent" invisibility. I.e. if you list the
//      contents of an invisible folder, only the files that are themselves
//      invisible inside it will be removed.
//
//      This tries to apply the same criteria as the Finder when it comes to
//      invisibility.
//
//  REVISIONS:
//      2004-11-11  UK  Created.
// -----------------------------------------------------------------------------

-(NSArray*)	visibleDirectoryContentsAtPath: (NSString*)path
{
    NSMutableArray*         arr = [NSMutableArray array];
    NSAutoreleasePool*      pool = [[NSAutoreleasePool alloc] init];
        // Everything created now will be autoreleased if it isn't in arr:
        UKDirectoryEnumerator*  enny = [[[UKDirectoryEnumerator alloc] initWithPath: path] autorelease];
        NSString*               fname;
        
        [enny setDesiredInfo: kFSCatInfoFinderInfo];
        
        // Loop through the directory:
        while( (fname = [enny nextObject]) )
        {
            if( [fname characterAtIndex: 0] == '.' )    // Unix-style invisibility?
                continue;
            
            if( [enny isInvisible] )                    // MacOS-style invisibility?
                continue;
            
            [arr addObject: fname];     // File is visible and should be listed.
        }
        
        // Now, if we're at the file system root, consult .hidden on what other files we should hide:
        if( [path isEqualToString: @"/"] )  // At the root level, we have some specially hidden Unix folders:
        {
            NSArray*    hiddenList = [[NSString stringWithContentsOfFile: @"/.hidden"] componentsSeparatedByString: @"\n"];
            [arr removeObjectsInArray: hiddenList];
        }
        // End of autoreleased area.
    [pool release];
    
    return arr;
}


-(BOOL)         changeCarbonFileAttributes: (NSDictionary*)attrs atPath: (NSString*)path
{
    FSCatalogInfo       info;
    FSRef               fileRef;
    OSErr               err = noErr;
    FSCatalogInfoBitmap whichInfo = kFSCatInfoNone;
    
    if( ![path getFSRef: &fileRef] )
        return nil;
    
    UKFSCatInfoFromDictionary( attrs, &info, &whichInfo );
    
    err = FSSetCatalogInfo( &fileRef, whichInfo, &info );
    if( err != noErr )
        NSLog( @"changeCarbonFileAttributes:atPath: FSSetCatalogInfo: MacOS Error ID=%d", err );
    
    return( err == noErr );
}


-(NSDictionary*)    carbonFileAttributesAtPath: (NSString*)path whichInfo: (FSCatalogInfoBitmap)whichInfo
{
    FSCatalogInfo       info;
    FSRef               fileRef;
    OSErr               err = noErr;
    
    if( ![path getFSRef: &fileRef] )
        return nil;
    
    err = FSGetCatalogInfo( &fileRef, whichInfo, &info, NULL,NULL, NULL );
    if( err != noErr )
        return nil;
    
    return UKDictionaryFromFSCatInfo( &info, whichInfo );
}


@end


NSDictionary*       UKDictionaryFromFSCatInfo( FSCatalogInfo* currInfo, FSCatalogInfoBitmap whichInfo )
{
	NSMutableDictionary*	dict = [NSMutableDictionary dictionary];
	
	if( UK_BTST(whichInfo, kFSCatInfoNodeFlags) )
	{
		[dict setObject: [NSNumber numberWithBool: UK_BTST(currInfo->nodeFlags, kFSNodeLockedMask)] forKey: UKItemIsLocked];
		if( UK_BTST(currInfo->nodeFlags, kFSNodeIsDirectoryMask) )
			[dict setObject: NSFileTypeDirectory forKey: NSFileType];
		else
			[dict setObject: NSFileTypeRegular forKey: NSFileType];
	}
	if( UK_BTST(whichInfo, kFSCatInfoFinderInfo) )
	{
		FileInfo*		fInfo = (FileInfo*) currInfo->finderInfo;
		
		[dict setObject: [NSNumber numberWithBool: UK_BTST(fInfo->finderFlags, kIsInvisible)] forKey: UKItemIsInvisible];
		[dict setObject: [NSNumber numberWithBool: UK_BTST(fInfo->finderFlags, kIsAlias)] forKey: UKItemIsAlias];
		[dict setObject: [NSNumber numberWithBool: UK_BTST(fInfo->finderFlags, kHasBundle)] forKey: UKItemHasBNDL];
		[dict setObject: [NSNumber numberWithBool: UK_BTST(fInfo->finderFlags, kNameLocked)] forKey: UKItemNameIsLocked];
		[dict setObject: [NSNumber numberWithBool: UK_BTST(fInfo->finderFlags, kIsStationery)] forKey: UKItemIsStationery];
		[dict setObject: [NSNumber numberWithBool: UK_BTST(fInfo->finderFlags, kHasCustomIcon)] forKey: UKItemHasCustomIcon];
		[dict setObject: [NSNumber numberWithInt: (fInfo->finderFlags & kColor) >> 1] forKey: UKLabelNumber];
		
		[dict setObject: [NSNumber numberWithUnsignedLong: fInfo->fileType] forKey: NSFileHFSTypeCode];
		[dict setObject: [NSNumber numberWithUnsignedLong: fInfo->fileCreator] forKey: NSFileHFSCreatorCode];
	}
	if( UK_BTST(whichInfo, kFSCatInfoDataSizes) )
	{
		[dict setObject: [NSNumber numberWithUnsignedLongLong: currInfo->dataLogicalSize] forKey: NSFileSize];
		[dict setObject: [NSNumber numberWithUnsignedLongLong: currInfo->dataPhysicalSize] forKey: UKPhysicalFileSize];
	}
	if( UK_BTST(whichInfo, kFSCatInfoRsrcSizes) )
	{
		[dict setObject: [NSNumber numberWithUnsignedLongLong: currInfo->rsrcLogicalSize] forKey: UKLogicalResFileSize];
		[dict setObject: [NSNumber numberWithUnsignedLongLong: currInfo->rsrcPhysicalSize] forKey: UKPhysicalResFileSize];
	}
	if( UK_BTST(whichInfo, kFSCatInfoFinderXInfo) )
	{
		ExtendedFileInfo*		xInfo = (ExtendedFileInfo*) currInfo->extFinderInfo;
		
		if( !UK_BTST(xInfo->extendedFinderFlags, kExtendedFlagsAreInvalid) )
		{
			[dict setObject: [NSNumber numberWithBool: UK_BTST(xInfo->extendedFinderFlags, kExtendedFlagHasCustomBadge)] forKey: UKItemHasCustomBadge];
			[dict setObject: [NSNumber numberWithBool: UK_BTST(xInfo->extendedFinderFlags, kExtendedFlagHasRoutingInfo)] forKey: UKItemHasRoutingInfo];
		}
	}
	if( UK_BTST(whichInfo, kFSCatInfoPermissions) )
	{
		FSPermissionInfo*		pInfo = (FSPermissionInfo*) currInfo->permissions;
		
		[dict setObject: [NSNumber numberWithUnsignedLong: pInfo->userID] forKey: NSFileOwnerAccountID];
		[dict setObject: [NSNumber numberWithUnsignedLong: pInfo->groupID] forKey: NSFileGroupOwnerAccountID];
		[dict setObject: [NSNumber numberWithUnsignedShort: pInfo->mode] forKey: NSFilePosixPermissions];
	}
    CFAbsoluteTime      absTime = 0;
    if( UK_BTST(whichInfo, kFSCatInfoCreateDate) )
    {
        UCConvertUTCDateTimeToCFAbsoluteTime( &currInfo->createDate, &absTime );
		[dict setObject: [NSDate dateWithTimeIntervalSinceReferenceDate: absTime] forKey: NSFileCreationDate];
    }
    if( UK_BTST(whichInfo, kFSCatInfoAttrMod) )
    {
        UCConvertUTCDateTimeToCFAbsoluteTime( &currInfo->attributeModDate, &absTime );
		[dict setObject: [NSDate dateWithTimeIntervalSinceReferenceDate: absTime] forKey: UKFileAttrModificationDate];
    }
    if( UK_BTST(whichInfo, kFSCatInfoContentMod) )
    {
        UCConvertUTCDateTimeToCFAbsoluteTime( &currInfo->contentModDate, &absTime );
		[dict setObject: [NSDate dateWithTimeIntervalSinceReferenceDate: absTime] forKey: NSFileModificationDate];
    }
    if( UK_BTST(whichInfo, kFSCatInfoAccessDate) )
    {
        UCConvertUTCDateTimeToCFAbsoluteTime( &currInfo->accessDate, &absTime );
		[dict setObject: [NSDate dateWithTimeIntervalSinceReferenceDate: absTime] forKey: UKFileAccessDate];
    }
    if( UK_BTST(whichInfo, kFSCatInfoBackupDate) )
    {
        UCConvertUTCDateTimeToCFAbsoluteTime( &currInfo->backupDate, &absTime );
		[dict setObject: [NSDate dateWithTimeIntervalSinceReferenceDate: absTime] forKey: UKFileBackupDate];
    }
	
	return dict;
}


void    UKFSCatInfoFromDictionary( NSDictionary* attrs, FSCatalogInfo* currInfo, FSCatalogInfoBitmap* whichInfo )
{
    NSNumber*       val = nil;
    
    (*whichInfo) = kFSCatInfoNone;
    memset( currInfo, 0, sizeof(FSCatalogInfo) );   // Clear all fields.
    
    // Node Flags:
    val = [attrs objectForKey: UKItemIsLocked];
    if( val )
    {
        (*whichInfo) |= kFSCatInfoNodeFlags;
        
        if( [val boolValue] )
            currInfo->nodeFlags |= kFSNodeLockedMask;
    }
    
    // Finder Flags:
    FileInfo*		fInfo = (FileInfo*) currInfo->finderInfo;
    
    val = [attrs objectForKey: UKItemIsInvisible];
    if( val )
    {
        (*whichInfo) |= kFSCatInfoFinderInfo;
        
        if( [val boolValue] )
            fInfo->finderFlags |= kIsInvisible;
    }
    
    val = [attrs objectForKey: UKItemIsAlias];
    if( val )
    {
        (*whichInfo) |= kFSCatInfoFinderInfo;
        
        if( [val boolValue] )
            fInfo->finderFlags |= kIsAlias;
    }

    val = [attrs objectForKey: UKItemHasBNDL];
    if( val )
    {
        (*whichInfo) |= kFSCatInfoFinderInfo;
        
        if( [val boolValue] )
            fInfo->finderFlags |= kHasBundle;
    }

    val = [attrs objectForKey: UKItemNameIsLocked];
    if( val )
    {
        (*whichInfo) |= kFSCatInfoFinderInfo;
        
        if( [val boolValue] )
            fInfo->finderFlags |= kNameLocked;
    }

    val = [attrs objectForKey: UKItemIsStationery];
    if( val )
    {
        (*whichInfo) |= kFSCatInfoFinderInfo;
        
        if( [val boolValue] )
            fInfo->finderFlags |= kIsStationery;
    }

    val = [attrs objectForKey: UKItemHasCustomIcon];
    if( val )
    {
        (*whichInfo) |= kFSCatInfoFinderInfo;
        
        if( [val boolValue] )
            fInfo->finderFlags |= kHasCustomIcon;
    }

    val = [attrs objectForKey: UKLabelNumber];
    if( val )
    {
        (*whichInfo) |= kFSCatInfoFinderInfo;
        
        fInfo->finderFlags |= ([val intValue] << 1) & kColor;
    }

    val = [attrs objectForKey: NSFileHFSTypeCode];
    if( val )
    {
        (*whichInfo) |= kFSCatInfoFinderInfo;
        fInfo->fileType = [val unsignedLongValue];
    }

    val = [attrs objectForKey: NSFileHFSCreatorCode];
    if( val )
    {
        (*whichInfo) |= kFSCatInfoFinderInfo;
        fInfo->fileCreator = [val unsignedLongValue];
    }

    // Extended Finder Flags:
    ExtendedFileInfo*		xInfo = (ExtendedFileInfo*) currInfo->extFinderInfo;
    
    val = [attrs objectForKey: UKItemHasCustomBadge];
    if( val )
    {
        (*whichInfo) |= kFSCatInfoFinderXInfo;
        
        if( [val boolValue] )
            xInfo->extendedFinderFlags |= kExtendedFlagHasCustomBadge;
    }

    val = [attrs objectForKey: UKItemHasRoutingInfo];
    if( val )
    {
        (*whichInfo) |= kFSCatInfoFinderXInfo;
        
        if( [val boolValue] )
            xInfo->extendedFinderFlags |= kExtendedFlagHasRoutingInfo;
    }

    // Permissions:
    FSPermissionInfo*		pInfo = (FSPermissionInfo*) currInfo->permissions;
    
    val = [attrs objectForKey: NSFileOwnerAccountID];
    if( val )
    {
        (*whichInfo) |= kFSCatInfoPermissions;
        
        pInfo->userID = [val unsignedLongValue];
    }
    
    val = [attrs objectForKey: NSFileGroupOwnerAccountID];
    if( val )
    {
        (*whichInfo) |= kFSCatInfoPermissions;
        
        pInfo->groupID = [val unsignedLongValue];
    }

    val = [attrs objectForKey: NSFilePosixPermissions];
    if( val )
    {
        (*whichInfo) |= kFSCatInfoPermissions;
        
        pInfo->mode = [val unsignedShortValue];
    }

    // Dates:
    // TO DO: Write code to set dates.
    /*CFAbsoluteTime      absTime = 0;
    if( UK_BTST(whichInfo, kFSCatInfoCreateDate) )
    {
        UCConvertUTCDateTimeToCFAbsoluteTime( &currInfo->createDate, &absTime );
		[dict setObject: [NSDate dateWithTimeIntervalSinceReferenceDate: absTime] forKey: NSFileCreationDate];
    }
    if( UK_BTST(whichInfo, kFSCatInfoAttrMod) )
    {
        UCConvertUTCDateTimeToCFAbsoluteTime( &currInfo->attributeModDate, &absTime );
		[dict setObject: [NSDate dateWithTimeIntervalSinceReferenceDate: absTime] forKey: UKFileAttrModificationDate];
    }
    if( UK_BTST(whichInfo, kFSCatInfoContentMod) )
    {
        UCConvertUTCDateTimeToCFAbsoluteTime( &currInfo->contentModDate, &absTime );
		[dict setObject: [NSDate dateWithTimeIntervalSinceReferenceDate: absTime] forKey: NSFileModificationDate];
    }
    if( UK_BTST(whichInfo, kFSCatInfoAccessDate) )
    {
        UCConvertUTCDateTimeToCFAbsoluteTime( &currInfo->accessDate, &absTime );
		[dict setObject: [NSDate dateWithTimeIntervalSinceReferenceDate: absTime] forKey: UKFileAccessDate];
    }
    if( UK_BTST(whichInfo, kFSCatInfoBackupDate) )
    {
        UCConvertUTCDateTimeToCFAbsoluteTime( &currInfo->backupDate, &absTime );
		[dict setObject: [NSDate dateWithTimeIntervalSinceReferenceDate: absTime] forKey: UKFileBackupDate];
    }*/
}


