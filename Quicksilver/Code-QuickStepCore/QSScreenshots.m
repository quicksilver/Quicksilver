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

+ (NSURL *)screenshotsLocation
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *screenshots = nil;

	// Try and get the user's screenshots folder setting
	NSUserDefaults *defaults = [[NSUserDefaults alloc] init];
	NSDictionary *screencapturePrefs = [defaults persistentDomainForName:@"com.apple.screencapture"];
	screenshots = [[screencapturePrefs objectForKey:@"location"] stringByStandardizingPath];

	if (screenshots) {
		screenshots = [screenshots stringByResolvingSymlinksInPath];
		return [NSURL URLWithString:[screenshots stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];
	} else {
		// fall back to the default screenshots folder (the desktop folder) if the user settings couldn't be resolved
		NSArray *screenshotURLs = [manager URLsForDirectory:NSDesktopDirectory inDomains:NSUserDomainMask];
		if ([screenshotURLs count]) {
			return [screenshotURLs objectAtIndex:0];
		}
	}
	return nil;
}

#pragma mark Proxy Methods

- (id)resolveProxyObject:(id)proxy {
	NSURL *screenshotsURL = [QSScreenshots screenshotsLocation];
		if (!screenshotsURL) {
			NSBeep();
			return nil;
		}

	NSFileManager *manager = [NSFileManager defaultManager];
	NSError *err = nil;
	// An array of the directory contents, keeping the attributeModificationDate key and skipping hidden files
	NSArray *contents = [manager contentsOfDirectoryAtURL:screenshotsURL
												includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLAttributeModificationDateKey,nil]
												options:NSDirectoryEnumerationSkipsHiddenFiles
												error:&err];
	if (err) {
		NSLog(@"Error resolving screenshots path: %@", err);
		return nil;
	}

	NSString *screenshotPath = nil;
	NSString *mrspath = nil;
	NSDate *modified = nil;
	NSDate *mostRecent = [NSDate distantPast];

	for (NSURL *screenshotFile in contents) {
		err = nil;

		screenshotPath = [screenshotFile path];
		// compare the modified date of the file with the most recent screenshot file
		[screenshotFile getResourceValue:&modified forKey:NSURLAttributeModificationDateKey error:&err];
		if (err != nil) {
			NSLog(@"Error getting resource value for %@\nError: %@",screenshotPath,err);
			continue;
		}
		if ([mostRecent compare:modified] == NSOrderedAscending) {
			mostRecent = modified;
			mrspath = screenshotPath;
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
