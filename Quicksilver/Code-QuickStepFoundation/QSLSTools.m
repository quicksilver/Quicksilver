//
//  QSLSTools.m
//  Quicksilver
//
//  Created by Alcor on 4/6/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import "QSLSTools.h"

NSString *QSApplicationPathForURL(NSString *urlString){
	NSURL *appURL = nil; 
	OSStatus err; 
	err = LSGetApplicationForURL((CFURLRef)[NSURL URLWithString: urlString],kLSRolesAll, NULL, (CFURLRef *)&appURL); 
//	if (err != noErr) NSLog(@"error %ld", err); 
	// else NSLog(@"%@", appURL); 
	
	return [appURL path];
}

NSString *QSApplicationIdentifierForURL(NSString *urlString){
	NSString *path=QSApplicationPathForURL(urlString);
	if (!path)return nil;
	NSDictionary *infoDict=(NSDictionary *)CFBundleCopyInfoDictionaryForURL((CFURLRef)[NSURL fileURLWithPath:path]);
	[infoDict autorelease];
	return [infoDict objectForKey:(NSString *)kCFBundleIdentifierKey];
}
