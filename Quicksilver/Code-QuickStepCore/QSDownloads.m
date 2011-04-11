//
//  QSDownloads.m
//  Quicksilver
//
//  Created by Rob McBroom on 4/8/11.
//

#import "QSDownloads.h"

@implementation QSDownloads
- (id)resolveProxyObject:(id)proxy {
    NSString *downloads = [@"~/Downloads" stringByStandardizingPath];
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDir;
    NSArray *contents = [manager contentsOfDirectoryAtPath:downloads error:nil];
    NSString *mrdpath;
    NSDate *mostRecent = [NSDate distantPast];
    for (NSString *downloadedFile in contents) {
        if (
            // system files
            [downloadedFile isEqualToString:@".DS_Store"] ||
            [downloadedFile isEqualToString:@".localized"] ||
            // Safari downloads in progress
            [[downloadedFile pathExtension] isEqualToString:@".download"] ||
            // Firefox downloads in progress
            [[downloadedFile pathExtension] isEqualToString:@".part"] ||
            [[downloadedFile pathExtension] isEqualToString:@".dtapart"] ||
            // Chrome downloads in progress
            [[downloadedFile pathExtension] isEqualToString:@".crdownload"]
        ) continue;
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
