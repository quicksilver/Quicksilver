//
//  QSURLDownloadWrapper.h
//  Quicksilver
//
//  Created by Alcor on 4/10/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface QSURLDownload : NSObject {
    NSURLRequest *request;
    NSURLDownload *download;
	long long expectedContentLength;
	long long currentContentLength;
	id userInfo;
    NSString *destination;
    id delegate;
}
+ (id)downloadWithURL:(NSURL*)url delegate:(id)aDelegate;
- (id)initWithRequest:(NSURLRequest*)url delegate:(id)aDelegate;
- (void)start;
- (void)cancel;

- (NSURLRequest *)request;
- (NSURL *)URL;
- (NSString *)destination;
- (double)progress;
- (id)userInfo;
- (void)setUserInfo:(id)value;

- (long long)expectedContentLength;
- (long long)currentContentLength;
@end

@interface NSObject (QSURLDownloadDelegate)
- (void)downloadDidUpdate:(QSURLDownload *)download;
- (void)downloadDidFinish:(QSURLDownload *)download;
- (void)download:(QSURLDownload *)download didFailWithError:(NSError *)error;
@end