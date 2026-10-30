//
//  NSURL_BLTRExtensions.h
//  Quicksilver
//
//  Created by Alcor on 7/13/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSURL (Keychain)

- (NSString *)keychainPassword;
- (NSURL *)URLByInjectingPasswordFromKeychain;

/**
 *  Replacement of Apple's URLByResolvingSymlinksInPath that works
 *  for all URLS
 *
 *  @return a new NSURL object after resolving any symlinks in the path
 *  @discussion Apple's own URLByResolvingSymlinksInPath methods doesn't
 *  work correctly for /tmp, /etc and /var. This method looks explicitly at
 *  those 3 cases, and resolves to the /private/ version of them.
 *  See http://goo.gl/sQC9Uy for more info
 */
- (NSURL *)URLByReallyResolvingSymlinksInPath;

@end

@interface NSURL (QSCanonicalPath)

/**
 *  The location the Finder shows this file at
 *
 *  @return a new NSURL under the local /Applications folder, or self
 *  @discussion Finder presents the system domain's Applications
 *  directories (/System/Applications and the App cryptex that backs
 *  /Applications symlinks like Safari) merged into the local
 *  /Applications folder, so e.g. /System/Applications/FindMy.app is
 *  shown in /Applications. Paths outside those directories, and paths
 *  inside a bundle within them, are returned unchanged. The mapped path
 *  may not exist on disk (FindMy.app has no /Applications entry), so
 *  use it for display, not file access.
 */
- (NSURL *)URLByMappingSystemApplicationsToLocalDomain;

/**
 *  The user-visible location of a file that may be reachable through
 *  multiple paths
 *
 *  @return a new NSURL for the same file at its user-visible path, or self
 *  @discussion System applications shipped in a cryptex (e.g. Safari)
 *  are reported by Launch Services and directory scans at their backing
 *  location (/System/Volumes/Preboot/Cryptexes/App/... or
 *  /System/Cryptexes/App/...) rather than the path users see in the
 *  Finder (/Applications/Safari.app). There is no direct API for this
 *  mapping (see https://developer.apple.com/forums/thread/745673); it
 *  is derived from the system's Applications directories, and the
 *  result is only used when it exists and refers to the same file
 *  (NSURLFileResourceIdentifierKey), so this always returns a real path.
 */
- (NSURL *)URLByResolvingToUserVisiblePath;

@end

@interface NSURL (QSBookmarkHelpers)
+ (instancetype)URLByResolvingBookmarkAtURL:(NSURL *)bookmarkURL options:(NSURLBookmarkResolutionOptions)options bookmarkDataIsStale:(BOOL *)isStale error:(NSError **)error;
- (BOOL)writeBookmarkToURL:(NSURL *)destinationURL options:(NSURLBookmarkFileCreationOptions)options error:(NSError **)error;
- (NSData *)bookmarkData;
@end