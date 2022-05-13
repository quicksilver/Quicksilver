//
//  QSScreenshots.m
//  Quicksilver
//
//  Created by Lucas Garron on 2022-04-25.
//
//  This class should be used to manage anything having to do with
//  the user's screenshots folder.
//

#import "QSScreenshots.h"

@implementation QSScreenshots

#pragma mark Class Methods

- (NSDictionary *)screencapturePrefs {
	// Try and get the user's screenshots folder setting
	NSUserDefaults *defaults = [[NSUserDefaults alloc] init];
	return [defaults persistentDomainForName:@"com.apple.screencapture"];
}

- (NSURL *)screenshotsLocation {
	NSString *screenshotsPath = [[[self screencapturePrefs] objectForKey:@"location"] stringByStandardizingPath];
	
	if (screenshotsPath) {
		screenshotsPath = [screenshotsPath stringByResolvingSymlinksInPath];
		return [NSURL fileURLWithPath:screenshotsPath];
	}
	
	NSFileManager *manager = [NSFileManager defaultManager];
	// fall back to the default screenshots folder (the desktop folder) if the user settings couldn't be resolved
	return [manager URLForDirectory:NSDesktopDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
}

- (NSString *)screenshotsType {
	NSString *type = [[self screencapturePrefs] objectForKey:@"type"];
	if (!type) {
		type = @"png";
	}
	return type;
}

#pragma mark Proxy Methods

- (id)resolveProxyObject:(id)proxy {
	NSURL *screenshotsURL = [self screenshotsLocation];
	
	if (!screenshotsURL) {
		NSBeep();
		return nil;
	}
	
	NSString *type = [self screenshotsType];
	
	NSFileManager *manager = [NSFileManager defaultManager];
	NSError *err = nil;
	// An array of the directory contents, keeping the attributeModificationDate key and skipping hidden files
	NSArray *contents = [manager contentsOfDirectoryAtURL:screenshotsURL
												includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLAttributeModificationDateKey,nil]
												options:NSDirectoryEnumerationSkipsHiddenFiles
												error:&err];
	if (err || ![contents count]) {
		NSLog(@"Error retrieving contents of %@: %@", [screenshotsURL path], err);
		return nil;
	}

	NSDate *modified = nil;
	NSDate *mostRecent = [NSDate distantPast];
	NSString *mrspath = nil;
	
	for (NSURL *screenshotFile in contents) {
		if (![[screenshotFile pathExtension] isEqualToString:type]) {
			continue;
		}

		// compare the modified date of the file with the most recent screenshot file
		[screenshotFile getResourceValue:&modified forKey:NSURLAttributeModificationDateKey error:nil];

		if ([mostRecent compare:modified] == NSOrderedAscending) {
			mostRecent = modified;
			mrspath = [screenshotFile path];
		}
	}

	if (mrspath) {
			return [QSObject fileObjectWithPath:mrspath]; 
	}
	else {
			return nil;
	}
}

- (NSTimeInterval)cacheTimeForProxy:(id)proxy {
    return 0.5f;
}

@end
