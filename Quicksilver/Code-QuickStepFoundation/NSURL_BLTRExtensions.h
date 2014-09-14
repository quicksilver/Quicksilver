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
