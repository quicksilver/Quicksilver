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
@end
