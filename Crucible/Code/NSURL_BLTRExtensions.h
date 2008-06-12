//
//  NSURL_BLTRExtensions.h
//  Quicksilver
//
//  Created by Alcor on 7/13/04.

//

#import <Cocoa/Cocoa.h>


@interface NSURL (Keychain)
- (NSString *)keychainPassword;
- (NSURL *)URLByInjectingPasswordFromKeychain;
@end
