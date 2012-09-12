//
//  QSDownloads.m
//  Quicksilver
//
//  Created by Rob McBroom on 4/8/11.
//
//  This class should be used to manage anything having to do with
//  the user's Downloads folder.
//

#import "QSDownloads.h"

@implementation QSDownloads
- (id)resolveProxyObject:(id)proxy {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *downloads = nil;
	NSURL *downloadsURL = nil;
    // Try and get the user's downloads folder setting (set in Safari)
	if ([NSApplication isMountainLion]) {
		// check Safari directly in 10.8+
		NSUserDefaults *defaults = [[NSUserDefaults alloc] init];
		NSDictionary *safariPrefs = [defaults persistentDomainForName:@"com.apple.Safari"];
		downloads = [[safariPrefs objectForKey:@"DownloadsPath"] stringByStandardizingPath];
		[defaults release];
	} else {
		NSData *downloadsData = (NSData *)CFPreferencesCopyValue((CFStringRef) @"DownloadFolder", (CFStringRef) @"com.apple.internetconfigpriv", kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (downloadsData) {
			downloads = [[NDAlias aliasWithData:downloadsData] quickPath];
			[downloadsData release];
		}
	}
    
    if (downloads) {
		downloads = [downloads stringByResolvingSymlinksInPath];
		downloadsURL = [NSURL URLWithString:downloads];
    } else {
		// fall back to the default downloads folder if the user settings couldn't be resolved
		NSArray *downloadURLs = [manager URLsForDirectory:NSDownloadsDirectory inDomains:NSUserDomainMask];
		if ([downloadURLs count]) {
			downloadsURL = [downloadURLs objectAtIndex:0];
		}
	}
    
    if (!downloadsURL) {
        NSLog(@"Unable to locate downloads folder (path: %@)",downloads);
        NSBeep();
        return nil;
    }
    
    NSError *err = nil;
    // An array of the directory contents, keeping the isDirectory key, attributeModificationDate key and skipping hidden files
	NSArray *contents = [manager contentsOfDirectoryAtURL:downloadsURL
							   includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLIsDirectoryKey,NSURLAttributeModificationDateKey,nil]
												  options:NSDirectoryEnumerationSkipsHiddenFiles
													error:&err];
	if (err) {
		NSLog(@"Error resolving downloads path: %@", err);
		return nil;
	}

	NSString *downloadPath = nil;
	NSString *mrdpath = nil;
	NSDate *modified = nil;
    NSDate *mostRecent = [NSDate distantPast];

	NSNumber *isDir;
	NSNumber *isPackage;
	NSSet *ignoredExtensions = [NSSet setWithObjects:@"download", @"part", @"dtapart", @"crdownload", nil];
	for (NSURL *downloadedFile in contents) {
		err = nil;
		NSString *fileExtension = [downloadedFile pathExtension];
		if ([ignoredExtensions containsObject:fileExtension]) {
			continue;
		}
		
		downloadPath = [downloadedFile path];
		// Do not show folders
		if ([downloadedFile getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:&err] && [isDir boolValue]) {
			if (err != nil) {
				NSLog(@"Error getting resource value for %@\nError: %@",downloadPath,err);
				continue;
			}
			// Show packages (e.g. .app and .qsplugin packages)
			if ([downloadedFile getResourceValue:&isPackage forKey:NSURLIsPackageKey error:&err] && ![isPackage boolValue]) {
				if (err != nil) {
					NSLog(@"Error getting resource value for %@\nError: %@",downloadPath,err);
				}
				continue;
			}
		}
		if([manager fileExistsAtPath:[downloadPath stringByAppendingPathExtension:@"part"]]) {
			continue;
		}
		// compare the modified date of the file with the most recent download file
		[downloadedFile getResourceValue:&modified forKey:NSURLAttributeModificationDateKey error:&err];
		if (err != nil) {
			NSLog(@"Error getting resource value for %@\nError: %@",downloadPath,err);
			continue;
		}
		if ([mostRecent compare:modified] == NSOrderedAscending) {
			mostRecent = modified;
			mrdpath = downloadPath;
		}
	}

    if (mrdpath) {
        return [QSObject fileObjectWithPath:mrdpath]; 
    }
    else {
        return nil;
    }
}
@end
