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
    NSArray *contents = [manager contentsOfDirectoryAtPath:downloads error:nil];
    NSString *mrdpath;
    NSDate *mostRecent = [NSDate distantPast];
    for (NSString *downloadedFile in contents) {
        if ([downloadedFile isEqualToString:@".DS_Store"]) continue;
        if ([downloadedFile isEqualToString:@".localized"]) continue;
        NSString *downloadPath = [downloads stringByAppendingPathComponent:downloadedFile];
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
