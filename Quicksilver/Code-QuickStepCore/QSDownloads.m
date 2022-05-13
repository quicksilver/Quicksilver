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

#pragma mark Class Methods

+ (NSArray *)iCloudDocumentsForBundleID:(NSString *)bundleIdentifier
{
	if (!bundleIdentifier) {
		return nil;
	}
	NSString *bundleFolderName = [bundleIdentifier stringByReplacingOccurrencesOfString:@"." withString:@"~"];
	NSString *documentsPath = [[pICloudDocumentsPrefix stringByAppendingPathComponent:bundleFolderName] stringByAppendingPathComponent:@"Documents"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:documentsPath]) {
		// return a list of documents' paths
		NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
								  [NSNumber numberWithInteger:2], kItemFolderDepth, // iCloud only allows one level of nesting
								  [NSNumber numberWithBool:YES], kItemSkipItem,     // don't include the parent folder
								  [NSArray arrayWithObject:@"public.folder"], kItemExcludeFiletypes, // ignore folders
								  nil];
		id dirParser = [QSReg getClassInstance:@"QSDirectoryParser"];
		return [dirParser objectsFromPath:documentsPath withSettings:settings];
	}
	return nil;
}

+ (NSURL *)downloadsLocation
{
	NSFileManager *manager = [NSFileManager defaultManager];
    NSString *downloads = nil;
    // Try and get the user's downloads folder setting (set in Safari)
	NSUserDefaults *defaults = [[NSUserDefaults alloc] init];
	NSDictionary *safariPrefs = [defaults persistentDomainForName:@"com.apple.Safari"];
	downloads = [[safariPrefs objectForKey:@"DownloadsPath"] stringByStandardizingPath];
    
    if (downloads) {
		return [NSURL fileURLWithPath:[downloads stringByResolvingSymlinksInPath]];
    }
	
	return [manager URLForDirectory:NSDownloadsDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];

}

#pragma mark Proxy Methods

- (id)resolveProxyObject:(id)proxy {
	static NSArray *properties;
	static NSArray *ignoredExtensions;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		properties = @[NSURLIsDirectoryKey,NSURLIsPackageKey,NSURLAttributeModificationDateKey];
		ignoredExtensions = @[@"download", @"part", @"dtapart", @"crdownload", @"opdownload"];
	});
	
	NSURL *downloadsURL = [QSDownloads downloadsLocation];
    if (!downloadsURL) {
        NSLog(@"Unable to locate downloads folder");
        NSBeep();
        return nil;
    }
    
	NSFileManager *manager = [NSFileManager defaultManager];
    NSError *err = nil;
    // An array of the directory contents, keeping the isDirectory key, attributeModificationDate key and skipping hidden files
	NSArray *contents = [manager contentsOfDirectoryAtURL:downloadsURL
							   includingPropertiesForKeys:properties
												  options:NSDirectoryEnumerationSkipsHiddenFiles
													error:&err];
	if (err || ![contents count]) {
		NSLog(@"Error retrieving contents of %@: %@", [downloadsURL path], err);
		return nil;
	}

	NSString *downloadPath = nil;
	NSString *mrdpath = nil;
	NSDate *modified = nil;
    NSDate *mostRecent = [NSDate distantPast];

	for (NSURL *downloadedFile in contents) {
		if ([ignoredExtensions containsObject:[downloadedFile pathExtension]]) {
			continue;
		}
		
		NSDictionary *resourceValues = [downloadedFile resourceValuesForKeys:properties error:nil];
		// Do not show folders, but how packages (e.g. .app and .qspluign)
		if ([[resourceValues objectForKey:NSURLIsDirectoryKey] boolValue] && ![[resourceValues objectForKey:NSURLIsPackageKey] boolValue]) {
			continue;
		}
		
		downloadPath = [downloadedFile path];
		if([manager fileExistsAtPath:[downloadPath stringByAppendingPathExtension:@"part"]]) {
			continue;
		}
		
		// compare the modified date of the file with the most recent download file
		modified = [resourceValues objectForKey:NSURLAttributeModificationDateKey];
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

- (NSTimeInterval)cacheTimeForProxy:(id)proxy {
    return 0.5f;
}

@end
