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
    NSString *downloads = [@"~/Downloads" stringByStandardizingPath];
    NSFileManager *manager = [[NSFileManager alloc] init];
	NSString *downloadPath, *mrdpath = downloads;
	NSDate *modified = nil;
    NSDate *mostRecent = [NSDate distantPast];
	
	// Snow Leopard Specific Way
	if([NSApplication isSnowLeopard]) {
		NSNumber *isDir;
		NSURL *downloadsURL = [NSURL URLWithString:downloads];
		NSArray *contents = [manager contentsOfDirectoryAtURL:downloadsURL
								   includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLIsDirectoryKey,NSURLAttributeModificationDateKey,nil]
													  options:NSDirectoryEnumerationSkipsHiddenFiles
														error:nil];
		for (NSURL *downloadedFile in contents) {
			NSString *pathExtension = [downloadedFile pathExtension];
			 if ([pathExtension isEqualToString:@"download"] ||
				 [pathExtension isEqualToString:@"part"] ||
				 [pathExtension isEqualToString:@"dtapart"] ||
				 [pathExtension isEqualToString:@"crdownload"]) {
				 continue;
			 }
			if ([downloadedFile getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:nil] && [isDir boolValue]) {
				continue;
			}
			downloadPath = [downloadedFile path];
			if([manager fileExistsAtPath:[downloadPath stringByAppendingPathExtension:@"part"]]) {
				continue;
			}
			[downloadedFile getResourceValue:&modified forKey:NSURLAttributeModificationDateKey error:nil];
			if ([mostRecent compare:modified] == NSOrderedAscending) {
				mostRecent = modified;
				mrdpath = downloadPath;
			}
		}
	}
	
	// Leopard Way
	else {
	BOOL isDir;

    // list files in the Downloads directory
    NSArray *contents = [manager contentsOfDirectoryAtPath:downloads error:nil];
    // the most recent download (with the folder itself as a fallback)
    for (NSString *downloadedFile in contents) {
        if (
            // hidden files
            [downloadedFile characterAtIndex:0] == '.' ||
            // Safari downloads in progress
            [[downloadedFile pathExtension] isEqualToString:@"download"] ||
            // Firefox downloads in progress
            [[downloadedFile pathExtension] isEqualToString:@"part"] ||
            [[downloadedFile pathExtension] isEqualToString:@"dtapart"] ||
            // Chrome downloads in progress
            [[downloadedFile pathExtension] isEqualToString:@"crdownload"]
        ) continue;
		downloadPath = [downloads stringByAppendingPathComponent:downloadedFile];
        // if SomeFile.part exists, SomeFile is probably an in-progress download so skip it
        if ([manager fileExistsAtPath:[downloadPath stringByAppendingPathExtension:@"part"]]) continue;
        // ignore folders
        if ([manager fileExistsAtPath:downloadPath isDirectory:&isDir] && isDir) continue;
        modified = [[manager attributesOfItemAtPath:downloadPath error:nil] fileModificationDate];
        if ([mostRecent compare:modified] == NSOrderedAscending) {
            mostRecent = modified;
            mrdpath = downloadPath;
        }
    }
	}

	[manager release];
    return [QSObject fileObjectWithPath:mrdpath];
}
@end
