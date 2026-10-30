//
// NSURL_BLTRExtensions.m
// Quicksilver
//
// Created by Alcor on 7/13/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "NSURL_BLTRExtensions.h"
#import "NSString_BLTRExtensions.h"

#include <Security/Security.h>
#define KEYCHAIN_PASS @"PasswordInKeychain"

NSString *QSPasswordForHostUserType(NSString *host, NSString *user, SecProtocolType type);
SecProtocolType QSProtocolTypeForString(NSString *protocol);

SecProtocolType QSProtocolTypeForString(NSString *protocol) {
	if ([protocol isEqualToString:@"ftp"]) return kSecProtocolTypeFTP;
	else if ([protocol isEqualToString:@"http"]) return kSecProtocolTypeHTTP;
	else if ([protocol isEqualToString:@"sftp"]) return kSecProtocolTypeFTPS;
	else if ([protocol isEqualToString:@"eppc"]) return kSecProtocolTypeEPPC;
	else if ([protocol isEqualToString:@"afp"]) return kSecProtocolTypeAFP;
	else if ([protocol isEqualToString:@"smb"]) return kSecProtocolTypeSMB;
	else if ([protocol isEqualToString:@"ssh"]) return kSecProtocolTypeSSH;
	else if ([protocol isEqualToString:@"telnet"]) return kSecProtocolTypeTelnet;
	return 0;
}

NSString *QSPasswordForHostUserScheme(NSString *host, NSString *user, NSString *scheme) {
	NSString *password = nil;

	SecProtocolType type = QSProtocolTypeForString(scheme);

	password = QSPasswordForHostUserType(host, user, type);

	if (!password && type == kSecProtocolTypeFTP)
		password = QSPasswordForHostUserType(host, user, kSecProtocolTypeFTPAccount); // Workaround for Transmit's old type usage
	if (!password)
		password = QSPasswordForHostUserType(host, user, 0);
	if (!password)
			NSLog(@"Couldn't find password. URL:%@ %@ %@", host, user, scheme);
	return password;
}

NSString *QSPasswordForHostUserType(NSString *host, NSString *user, SecProtocolType type) {
	const char 		*buffer;
	UInt32 			length = 0;
	OSErr			err;
	err = SecKeychainFindInternetPassword(NULL, (UInt32)[host length], [host UTF8String], 0, NULL, (UInt32)[user length], [user UTF8String], 0, NULL, 0, type, 0, &length, (void**)&buffer, NULL);
	if (err == noErr) {
		SecKeychainItemFreeContent(NULL, (void *)buffer);
		return [[NSString alloc] initWithCString:buffer encoding:NSUTF8StringEncoding];
	}
	return nil;
}

@implementation NSURL (Keychain)

- (NSString *)keychainPassword {
	return QSPasswordForHostUserScheme([self host], [self user], [self scheme]);
}

- (OSErr) addPasswordToKeychain {
	OSErr err;
	NSString *host = [self host], *user = [self user], *pass = [self password];

	SecProtocolType type = QSProtocolTypeForString([self scheme]);
	SecKeychainItemRef existing = NULL;
	err = SecKeychainFindInternetPassword(NULL, (UInt32)[host length], [host UTF8String], 0, NULL, (UInt32)[user length], [user UTF8String], 0, NULL, 0, type, 0, NULL, NULL, &existing);
	if (err) {
		return SecKeychainAddInternetPassword(NULL, (UInt32)[host length], [host UTF8String], 0, NULL, (UInt32)[user length], [user UTF8String], 0, NULL, 0, type, 0, (UInt32)[pass length], [pass UTF8String], NULL);
	} else {
		err = SecKeychainItemModifyContent(existing, NULL, (UInt32)[pass length], [pass UTF8String]);
		CFRelease(existing);
		return err;
	}
}

- (NSURL *)URLByInjectingPasswordFromKeychain {
	if ([[self password] isEqualToString:KEYCHAIN_PASS]) {
		NSString *pass = [self keychainPassword];
		if (pass)
			return [NSURL URLWithString:[[self absoluteString] stringByReplacingOccurrencesOfString:KEYCHAIN_PASS withString:pass]];
	}
	return self;
}

- (NSURL *)URLByReallyResolvingSymlinksInPath {
    NSURL *url = [self URLByResolvingSymlinksInPath];
    NSArray *parts = [url pathComponents];
    if ([parts[0] isEqualToString:@"/"] && [@[@"tmp", @"var", @"etc"] indexOfObject:parts[1]] != NSNotFound) {
        NSRange range;
        range.location = 1;
        range.length = [parts count] - 1;
        
        return [NSURL fileURLWithPathComponents:[@[@"/", @"private"] arrayByAddingObjectsFromArray:[parts subarrayWithRange:range]]];
    }
    return url;
}

@end

/* The system domain's Applications directories in every path form: as reported
 * by NSSearchPathForDirectoriesInDomains, plus their symlink-resolved forms
 * (e.g. /System/Cryptexes/App is a symlink to /System/Volumes/Preboot/Cryptexes/App,
 * the form directory enumerators report) */
static NSArray *QSSystemApplicationsDirectories(void) {
    static NSArray *directories = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableSet *set = [NSMutableSet set];
        for (NSString *dir in NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSSystemDomainMask, YES)) {
            [set addObject:dir];
            [set addObject:[dir stringByResolvingSymlinksInPath]];
        }
        directories = [set allObjects];
    });
    return directories;
}

/* YES if any directory between root and the last path component is a bundle */
static BOOL QSPathHasBundleAncestor(NSString *root, NSArray *components, NSUInteger fromIndex) {
    NSString *ancestor = root;
    for (NSUInteger i = fromIndex; i + 1 < [components count]; i++) {
        ancestor = [ancestor stringByAppendingPathComponent:components[i]];
        NSNumber *isPackage = nil;
        [[NSURL fileURLWithPath:ancestor] getResourceValue:&isPackage forKey:NSURLIsPackageKey error:NULL];
        if ([isPackage boolValue]) return YES;
    }
    return NO;
}

@implementation NSURL (QSCanonicalPath)

- (NSURL *)URLByMappingSystemApplicationsToLocalDomain {
    if (![self isFileURL]) return self;

    NSString *path = [self path];
    NSArray *components = nil;
    for (NSString *systemApps in QSSystemApplicationsDirectories()) {
        if (![path hasPrefix:systemApps]) continue;
        if (!components) components = [path pathComponents];

        // Must be a descendant on a component boundary: /System/ApplicationsFoo
        // shares the prefix string but isn't inside /System/Applications
        NSArray *systemAppsComponents = [systemApps pathComponents];
        NSUInteger prefixCount = [systemAppsComponents count];
        if ([components count] <= prefixCount) continue;
        if (![[components subarrayWithRange:NSMakeRange(0, prefixCount)] isEqualToArray:systemAppsComponents]) continue;

        // Finder only merges the folder hierarchy; paths inside a bundle are not remapped
        if (QSPathHasBundleAncestor(systemApps, components, prefixCount)) return self;

        NSString *localApps = [NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSLocalDomainMask, YES) firstObject];
        NSArray *relativeComponents = [components subarrayWithRange:NSMakeRange(prefixCount, [components count] - prefixCount)];
        return [NSURL fileURLWithPathComponents:[[localApps pathComponents] arrayByAddingObjectsFromArray:relativeComponents]];
    }
    return self;
}

- (NSURL *)URLByResolvingToUserVisiblePath {
    NSURL *mappedURL = [self URLByMappingSystemApplicationsToLocalDomain];
    if (mappedURL == self) return self; // not under a system Applications directory

    // Only adopt the mapped path if it exists and refers to the same file
    // (following symlinks, since the user-visible path may be a symlink to the
    // backing location, like /Applications/Safari.app)
    id selfIdentifier = nil, mappedIdentifier = nil;
    [[self URLByResolvingSymlinksInPath] getResourceValue:&selfIdentifier forKey:NSURLFileResourceIdentifierKey error:NULL];
    [[mappedURL URLByResolvingSymlinksInPath] getResourceValue:&mappedIdentifier forKey:NSURLFileResourceIdentifierKey error:NULL];
    if (!selfIdentifier || !mappedIdentifier || ![selfIdentifier isEqual:mappedIdentifier]) return self;

    return mappedURL;
}

@end

@implementation NSURL (QSBookmarkHelpers)
+ (instancetype)URLByResolvingBookmarkAtURL:(NSURL *)bookmarkURL options:(NSURLBookmarkResolutionOptions)options bookmarkDataIsStale:(BOOL *)isStale error:(NSError **)error {

    NSData *bookmarkData = [[self class] bookmarkDataWithContentsOfURL:bookmarkURL error:error];
    if (!bookmarkData) return nil;

    return [self URLByResolvingBookmarkData:bookmarkData options:options relativeToURL:nil bookmarkDataIsStale:isStale error:error];
}

- (BOOL)writeBookmarkToURL:(NSURL *)destinationURL options:(NSURLBookmarkFileCreationOptions)options error:(NSError **)error {
    NSData *bookmarkData = [self bookmarkDataWithOptions:NSURLBookmarkCreationSuitableForBookmarkFile|options
                          includingResourceValuesForKeys:nil
                                           relativeToURL:nil
                                                   error:error];
    if (bookmarkData == nil) {
        return NO;
    }
    return [NSURL writeBookmarkData:bookmarkData toURL:destinationURL options:options error:error];
}

- (NSData *)bookmarkData {
    return [self bookmarkDataWithOptions:NSURLBookmarkCreationSuitableForBookmarkFile
          includingResourceValuesForKeys:nil
                           relativeToURL:nil
                                   error:NULL];
}
@end
