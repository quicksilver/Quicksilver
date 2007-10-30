/* =============================================================================
	FILE:		UKDirectoryEnumerator.h
	PROJECT:	Filie

    COPYRIGHT:  (c) 2004 M. Uli Kusterer, all rights reserved.
    
	AUTHORS:	M. Uli Kusterer - UK
    
    LICENSES:   MIT License

	REVISIONS:
		2006-03-13	UK	Clarified license, factory methods, miscellaneous
						additions.
		2004-04-15	UK	Created.
   ========================================================================== */

/*
	As of MacOS X 10.3, NSDirectoryEnumerator is dog-slow.
	
	So, this is my take on it, which uses Carbon's FSGetCatalogInfoBulk() to
	quickly list files. And to allow for more control over where this spends
	its cycles, you can even specify what kinds of information you want. By
	default, this will collect *no* info about the object at all. I.e. no
	file attributes, no info whether it's a file or folder etc.
	
	By explicitly requesting certain info, you can avoid a lot of work that
	NSDirectoryEnumerator would do needlessly.
	
	Also, this fetches files in batches of 16, which improves access locality
	and stuff.
    
    This doesn't yet support listing subfolders implicitly. You have to do that
    manually. Apart from that it should be a drop-in replacement.
*/

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>



// -----------------------------------------------------------------------------
//  Constants:
// -----------------------------------------------------------------------------

#define UKDirectoryEnumeratorCacheSize		16			// Default size for cache.
#define UKDE_CACHE_SIZE                     UKDirectoryEnumeratorCacheSize  // old name for UKDirectoryEnumeratorCacheSize.

#ifndef UKDE_ALLOW_SETWHICHINFO
#define	UKDE_ALLOW_SETWHICHINFO 0			// Allow using old name setWhichInfo: instead of setDesiredInfo: and whichInfo instead of desiredInfo. Deprecated.
#endif

// -----------------------------------------------------------------------------
//  UKDirectoryEnumerator:
// -----------------------------------------------------------------------------

@interface UKDirectoryEnumerator : NSEnumerator
{
	FSIterator			iterator;		// Carbon iterator corresponding to this enumerator.
	FSRef*				cache;			// Carbon file refs to the found files. We get them in batches for performance reasons.
	FSCatalogInfo*		infoCache;		// Cache for info about file. May be NULL if whichInfo is kFSCatInfoNone.
	ItemCount			cacheSize;		// Number of files the cache can hold.
	ItemCount			foundItems;		// Number of entries in cache that are used.
	ItemCount			currIndex;		// Index into cache for next item to get. If this is >= foundItems, we need to re-cache.
	FSCatalogInfoBitmap whichInfo;		// Additional info to get for files (setDesiredInfo:/desiredInfo).
    int                 prefixlen;      // The number of characters to remove from files' pathnames to make them relative to the folder's path.
}

+(id)					enumeratorWithPath: (NSString*)fpath;
+(id)					enumeratorWithPath: (NSString*)fpath cacheSize: (ItemCount)n;

-(id)					initWithPath: (NSString*)fpath;
-(id)					initWithPath: (NSString*)fpath cacheSize: (ItemCount)n; // Designated.

-(id)					nextObject;             // NSDirectoryEnumerator-compatible variant.
-(id)                   nextObjectFullPath;     // Variant that returns an absolute path.

// Advanced users:
-(void)					setDesiredInfo: (FSCatalogInfoBitmap)n;   // Flags what additional info you want.
-(FSCatalogInfoBitmap)  desiredInfo;

-(NSDictionary*)		fileAttributes;		// You must set up whichInfo to get something in here. Note that this is an expensive call. If you can use isDirectory() or isInvisible(), then do that instead.
-(BOOL)					isInvisible;		// You must set whichInfo to include kFSCatInfoFinderInfo to get something except NO here.
-(BOOL)					isDirectory;		// You must set whichInfo to include kFSCatInfoNodeFlags to get something except NO here.

-(void)					setCacheSize: (ItemCount)c; // How many files to cache. Defaults to UKDirectoryEnumeratorCacheSize
-(ItemCount)			cacheSize;

-(BOOL)					cacheExhausted;		// Not really needed. I like to use this to pick a convenient point in time at which to send a reloadData message to my view.

-(FSIterator)			iterator;           // Carbon FSIterator behind this.

#if UKDE_ALLOW_SETWHICHINFO
// Old name for setDesiredInfo: *DEPRECATED*
-(void)					setWhichInfo: (FSCatalogInfoBitmap)n;   // Flags what additional info you want.
-(FSCatalogInfoBitmap)  whichInfo;
#endif

@end


// -----------------------------------------------------------------------------
//  Constants:
// -----------------------------------------------------------------------------

/*
	desiredInfo values and what values they add to the fileAttributes dictionary:
		(Note: By default, desiredInfo is kFSCatInfoNone, which means you get an
		empty fileAttributes dictionary)
	
    UKNSWorkspaceAttributeFlags:
        Gives you all the NSxxx keys that you'd get from NSWorkspace's NSDirectoryEnumerator.
    
	kFSCatInfoNodeFlags:
		NSFileType                  - either NSFileTypeDirectory or NSFileTypeRegular
        UKItemIsLocked              - NSNumber containing boolean.
    
	kFSCatInfoFinderInfo:   NSNumbers containing booleans if not specified differently.
		UKItemIsInvisible 
		UKItemIsAlias
		UKItemHasBNDL
		UKItemNameIsLocked
		UKItemIsStationery
		UKItemHasCustomIcon
        UKLabelNumber               - NSNumber containing number (0...7) indicating label of this file.
		NSFileHFSTypeCode           - NSNumber containing HFS type code.
		NSFileHFSCreatorCode        - NSNumber containing HFS creator code.
	
	kFSCatInfoFinderXInfo:
		UKItemHasCustomBadge        - NSNumber containing boolean.
		UKItemHasRoutingInfo        - NSNumber containing boolean.
	
	kFSCatInfoDataSizes:
		NSFileSize                  - NSNumber containing logical size of data fork.
		UKPhysicalFileSize          - NSNumber containing physical size of data fork.
	
	kFSCatInfoRsrcSizes:
		UKLogicalResFileSize        - NSNumber containing logical size of resource fork.
		UKPhysicalResFileSize       - NSNumber containing physical size of resource fork.
	
	kFSCatInfoPermissions:
		NSFileOwnerAccountID		- NSNumber containing owner ID.
		NSFileGroupOwnerAccountID   - NSNumber containing owning group's ID.
		NSFilePosixPermissions		- NSNumber containing unix permissions for file.
    
    kFSCatInfoCreateDate:
        NSFileCreationDate          - NSDate containing the date and time the file was created at.
    
    kFSCatInfoContentMod:
        NSFileModificationDate      - NSDate containing the date and time the file's contents were last modified.
    
    kFSCatInfoAttrMod:
        UKFileAttrModificationDate  - NSDate containing the date and time the file's attributes were last modified.
    
    kFSCatInfoAccessDate:
        UKFileAccessDate            - NSDate containing the date and time the filewas last accessed.
    
    kFSCatInfoBackupDate:
        UKFileBackupDate            - NSDate containing the date and time the file was last backed up.
*/

#define UKNSWorkspaceAttributeFlags (kFSCatInfoNodeFlags | kFSCatInfoFinderInfo | kFSCatInfoDataSizes \
                                        | kFSCatInfoPermissions | kFSCatInfoCreateDate | kFSCatInfoContentMod)


// UKDirectoryEnumerator-specific keys in fileAttributes dictionary:
#define UKItemIsInvisible           @"UKItemIsInvisible"            // This is the HFS Finder flag. You still have to hide files starting with a period.
#define UKItemIsAlias               @"UKItemIsAlias"                // HFS Finder flag. Different from Symlinks.
#define UKItemHasBNDL               @"UKItemHasBNDL"                // HFS Finder flag. File has BNDL resource with type/creator -> icon mappings.
#define UKItemNameIsLocked          @"UKItemNameIsLocked"           // HFS Finder flag. Name and icon can't be edited in Finder.
#define UKItemIsLocked              @"UKItemIsLocked"               // HFS Finder flag.
#define UKItemIsStationery          @"UKItemIsStationery"           // HFS Finder flag. File is stationery that will be copied when opened.
#define UKItemHasCustomIcon         @"UKItemHasCustomIcon"          // HFS Finder flag. File/folder has a user-specified icon.
#define UKPhysicalFileSize          @"UKPhysicalFileSize"           // Physical size of data fork (may be larger than actual used logical file size).
#define UKLogicalResFileSize        @"UKLogicalResFileSize"         // Logical size of resource fork.
#define UKPhysicalResFileSize       @"UKPhysicalResFileSize"        // Physical size of resource fork (may be larger than actual used logical size).
#define UKItemHasCustomBadge        @"UKItemHasCustomBadge"         // HFS Finder flag. File has an icon badge (specified using resources).
#define UKItemHasRoutingInfo        @"UKItemHasRoutingInfo"         // HFS Finder flag. File has routing info resource telling where in system folder it goes.
#define UKLabelNumber               @"UKLabelNumber"                // HFS Finder info. This is the number of the label that's been applied to the icon.
#define UKFileAttrModificationDate  @"UKFileAttrModificationDate"   // When file attributes (as opposed to contents) were last changed.
#define UKFileAccessDate            @"UKFileAccessDate"             // When the file was last accessed.
#define UKFileBackupDate            @"UKFileBackupDate"             // When the file was last backed up.


// -----------------------------------------------------------------------------
//  NSFileManager category:
//      Allows to only get user-visible files, and to set UKDirectoryEnumerator-
//      style file attributes and get them.
// -----------------------------------------------------------------------------

@interface NSFileManager (UKDirectoryEnumeratorVisibleDirectoryContents)

-(NSArray*)	visibleDirectoryContentsAtPath: (NSString*)path;

-(BOOL)             changeCarbonFileAttributes: (NSDictionary*)attrs atPath: (NSString*)path;	// Doesn't yet support all attributes! Check source code!
-(NSDictionary*)    carbonFileAttributesAtPath: (NSString*)path whichInfo: (FSCatalogInfoBitmap)whichInfo;

@end

