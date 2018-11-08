//
// QSLSTools.m
// Quicksilver
//
// Created by Alcor on 4/6/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "QSLSTools.h"

NSString *QSApplicationIdentifierForURL(NSString *urlString) {
	NSURL *URL = [NSURL URLWithString:urlString];
    NSURL *appURL = (__bridge_transfer NSURL *)LSCopyDefaultApplicationURLForURL((__bridge CFURLRef)URL, kLSRolesAll, NULL);
	NSString *path = [appURL path];
	if (!path)
		return nil;
	NSDictionary *infoDict = (NSDictionary *)CFBridgingRelease(CFBundleCopyInfoDictionaryForURL((__bridge CFURLRef)[NSURL fileURLWithPath:path]));
	return [infoDict objectForKey:(NSString *)kCFBundleIdentifierKey];
}
