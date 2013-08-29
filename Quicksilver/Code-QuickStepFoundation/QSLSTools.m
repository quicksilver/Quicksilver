//
// QSLSTools.m
// Quicksilver
//
// Created by Alcor on 4/6/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "QSLSTools.h"

#if 0
NSString *QSApplicationPathForURL(NSString *urlString) {
	NSURL *appURL = nil;
	OSStatus err;
	err = LSGetApplicationForURL((CFURLRef) [NSURL URLWithString: urlString], kLSRolesAll, NULL, (CFURLRef *)&appURL);
//	if (err != noErr) NSLog(@"error %ld", err);
//	else NSLog(@"%@", appURL);
	return [appURL path];
}
#endif

NSString *QSApplicationIdentifierForURL(NSString *urlString) {	
    CFURLRef appURLRef = nil;
	LSGetApplicationForURL((__bridge CFURLRef) [NSURL URLWithString: urlString] , kLSRolesAll, NULL, &appURLRef);
    NSURL *appURL = (__bridge NSURL *)appURLRef;
	NSString *path = [appURL path];
	if (!path)
		return nil;
	NSDictionary *infoDict = (NSDictionary *)CFBridgingRelease(CFBundleCopyInfoDictionaryForURL((__bridge CFURLRef)[NSURL fileURLWithPath:path]));
	return [infoDict objectForKey:(NSString *)kCFBundleIdentifierKey];
}
