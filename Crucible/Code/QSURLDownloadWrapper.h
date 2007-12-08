//
//  QSURLDownloadWrapper.h
//  Quicksilver
//
//  Created by Alcor on 4/10/05.

//

#import <Cocoa/Cocoa.h>


@interface QSURLDownload : NSURLDownload{
	long long expectedContentLength;
	long long currentContentLength;
	id userInfo;
}
- (NSURL *)url;
- (NSString *)destination;
- (double)progress;
- (id)userInfo;
- (void)setUserInfo:(id)value;
- (long long)expectedContentLength;
- (long long)currentContentLength;
@end

