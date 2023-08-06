//
// QSPaths.m
// Quicksilver
//
// Created by Alcor on 3/28/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "QSPaths.h"


NSString *QSGetApplicationSupportFolder() {
	static NSString *QSApplicationSupportPath = nil;

	// https://github.com/quicksilver/Quicksilver/issues/2953
	#ifdef TESTING
		NSLog(@"Override QSApplicationSupportPath for testing");
		QSApplicationSupportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"QSTest_Application_Support"];
	#endif

	if (!QSApplicationSupportPath) {
		NSString *path = [[[NSUserDefaults standardUserDefaults] stringForKey:@"QSApplicationSupportPath"] stringByStandardizingPath];
		if (!path) {
			NSArray *userSupportPathArray = NSSearchPathForDirectoriesInDomains (NSApplicationSupportDirectory, NSUserDomainMask, YES);
			if ([userSupportPathArray count]) {
				path = [[userSupportPathArray objectAtIndex:0] stringByAppendingPathComponent:@"Quicksilver"];
			}
			else {
				NSLog(@"Unable to find user Application Support folder");
				path = nil;
			}
		}
		QSApplicationSupportPath = path;
	}
	return QSApplicationSupportPath;
}

NSString *QSApplicationSupportSubPath(NSString *subpath, BOOL createFolder) {

	NSString *path = [QSGetApplicationSupportFolder() stringByAppendingPathComponent:subpath];
	NSFileManager *manager = [NSFileManager defaultManager];
	if (createFolder && ![manager fileExistsAtPath:path isDirectory:nil])
		[manager createDirectoriesForPath:path];
	return path;
}
