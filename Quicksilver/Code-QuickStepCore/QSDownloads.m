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
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDir;
    // list files in the Downloads directory
    NSArray *contents = [manager contentsOfDirectoryAtPath:downloads error:nil];
    // the most recent download (with the folder itself as a fallback)
    NSString *mrdpath = downloads;
    NSDate *mostRecent = [NSDate distantPast];
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
        // if SomeFile.part exists, SomeFile is probably an in-progress download so skip it
        if ([manager fileExistsAtPath:[downloads stringByAppendingPathComponent: [downloadedFile stringByAppendingPathExtension:@"part"]]]) continue;
        NSString *downloadPath = [downloads stringByAppendingPathComponent:downloadedFile];
        // ignore folders
        if ([manager fileExistsAtPath:downloadPath isDirectory:&isDir] && isDir) continue;
        NSDate *modified = [[manager attributesOfItemAtPath:downloadPath error:nil] fileModificationDate];
        if ([mostRecent compare:modified] == NSOrderedAscending) {
            mostRecent = modified;
            mrdpath = downloadPath;
        }
    }    
    QSObject *mrd = [QSObject objectWithString:mrdpath];
    return mrd;
}
@end
