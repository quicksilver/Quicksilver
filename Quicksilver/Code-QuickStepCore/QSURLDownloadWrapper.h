//
//  QSURLDownloadWrapper.h
//  Quicksilver
//
//  Created by Alcor on 4/10/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol QSURLDownloadDelegate;
@interface QSURLDownload : NSObject 
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_6
<NSURLDownloadDelegate>
#endif
{
    NSURLRequest *request;
    NSURLDownload *download;
	long long expectedContentLength;
	long long currentContentLength;
	id userInfo;
    NSString *destination;
    id <QSURLDownloadDelegate> delegate;
}
+ (id)downloadWithURL:(NSURL*)url delegate:(id <QSURLDownloadDelegate>)aDelegate;
- (id)initWithRequest:(NSURLRequest*)url delegate:(id <QSURLDownloadDelegate>)aDelegate;
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

@protocol QSURLDownloadDelegate <NSObject>
- (void)downloadDidFinish:(QSURLDownload *)download;
- (void)download:(QSURLDownload *)download didFailWithError:(NSError *)error;

@optional
- (void)downloadDidBegin:(QSURLDownload *)download;
- (void)downloadDidUpdate:(QSURLDownload *)download;
@end