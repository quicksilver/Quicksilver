//
//  NSURL_BLTRExtensions.m
//  Quicksilver
//
//  Created by Alcor on 7/13/04.

//

#import "NSURL_BLTRExtensions.h"
#import "NSString_BLTRExtensions.h"

#include <Security/Security.h>
#define KEYCHAIN_PASS @"PasswordInKeychain"

NSString *QSPasswordForHostUserType( NSString *host, NSString *user, SecProtocolType type );
SecProtocolType QSProtocolTypeForString( NSString *protocol );

SecProtocolType QSProtocolTypeForString( NSString *protocol ) {
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

NSString *QSPasswordForHostUserScheme( NSString *host ,NSString *user, NSString *scheme ) {
	NSString *password = nil;
	
	SecProtocolType type = QSProtocolTypeForString(scheme);
	
	password = QSPasswordForHostUserType( host, user, type);
	
	if ( !password && type == kSecProtocolTypeFTP )
		password = QSPasswordForHostUserType( host, user, kSecProtocolTypeFTPAccount ); // Workaround for Transmit's old type usage
	if ( !password )
		password = QSPasswordForHostUserType( host, user, 0 );
	if ( !password )
			QSLog( @"Couldn't find password. URL:%@ %@ %@", host, user,scheme );	
	return password;
}

NSString *QSPasswordForHostUserType(NSString *host,NSString *user,SecProtocolType type){
	const char 		*buffer;
	UInt32 			length = 0;
	OSErr			err;
	
	if ((err = SecKeychainFindInternetPassword(NULL,
                                               [host length], [host UTF8String],
                                               0, NULL,
                                               [user length], [user UTF8String],
                                               0, NULL,
                                               0,
                                               type,
                                               0,
                                               &length, (void**)&buffer,
                                               NULL)));
	
	if (err == noErr){
		NSString *password = [[[NSString alloc] initWithCString:buffer length:length] autorelease];
		SecKeychainItemFreeContent(NULL,(void *)buffer);
		return password;
	}
	return nil;
}

@implementation NSURL (Keychain)

- (NSString *)keychainPassword{
	return QSPasswordForHostUserScheme([self host], [self user], [self scheme]);	
}

- (OSErr)addPasswordToKeychain {
	//const char 		*buffer;
	//UInt32 			length = 0;
	OSErr			err;
	
	NSString *host = [self host]; //@"macsavants.com";
	NSString *user = [self user];
	NSString *pass = [self password];
	//	QSLog(@"host %@",host);
	SecProtocolType type = QSProtocolTypeForString( [self scheme] );
	
	SecKeychainItemRef existing = NULL;
		
	if ((err = SecKeychainFindInternetPassword(NULL,
                                               [host length], [host UTF8String],
                                               0, NULL,
                                               [user length], [user UTF8String],
                                               0, NULL,
                                               0,
                                               type,
                                               0,
                                               NULL,NULL,
                                               &existing)));
	
	if ( !err ) {
		err = SecKeychainItemModifyContent( existing, NULL, [pass length], [pass UTF8String] );
			CFRelease( existing );
	} else {
		err = SecKeychainAddInternetPassword(NULL,
                                             [host length], [host UTF8String],
                                             0, NULL,
                                             [user length], [user UTF8String],
                                             0, NULL,
                                             0,
                                             type,
                                             0,
                                             [pass length], [pass UTF8String],
                                             NULL);
    }
	
	return err;
}


- (NSURL *)URLByInjectingPasswordFromKeychain {
	if ( [[self password] isEqualToString:KEYCHAIN_PASS] ) {
		NSString *pass = [self keychainPassword];
		if (pass)
			return [NSURL URLWithString:[[self absoluteString] stringByReplacing:KEYCHAIN_PASS with:pass]];
	}	
	return self;
}


@end
