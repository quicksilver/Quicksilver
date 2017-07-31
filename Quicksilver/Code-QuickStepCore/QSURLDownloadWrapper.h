//
//  QSURLDownloadWrapper.h
//  Quicksilver
//
//  Created by Alcor on 4/10/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol QSURLDownloadDelegate;
@interface QSURLDownload : NSObject

+ (id)downloadWithURL:(NSURL *)url delegate:(nullable id <QSURLDownloadDelegate>)aDelegate;
- (id)initWithRequest:(NSURLRequest *)url delegate:(nullable id <QSURLDownloadDelegate>)aDelegate;
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

NS_ASSUME_NONNULL_END
