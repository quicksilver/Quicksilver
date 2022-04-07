//
// QSURLDownloadWrapper.m
// Quicksilver
//
// Created by Alcor on 4/10/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "QSURLDownloadWrapper.h"

@interface QSURLDownload () <NSURLSessionDownloadDelegate> {
	NSURLRequest *request;
	NSURLSessionDownloadTask *download;
	int64_t expectedContentLength;
	int64_t currentContentLength;
	id userInfo;
	NSString *destination;
	id <QSURLDownloadDelegate> delegate;
}
@end

@implementation QSURLDownload
+ (id)downloadWithURL:(NSURL*)url delegate:(id)aDelegate {
	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
    [theRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
	[theRequest setValue:kQSUserAgent forHTTPHeaderField:@"User-Agent"];
    return [[self alloc] initWithRequest:theRequest delegate:aDelegate];
}

- (id)initWithRequest:(NSURLRequest*)aRequest delegate:(id)aDelegate {
    if (aRequest == nil)
        [NSException raise:NSInvalidArgumentException format:@"QSURLDownload can't handle nil-requests"];
    
    self = [super init];
    if(!self) {
        return nil;
    }
    request = [aRequest copy];
    delegate = aDelegate;
    return self;
}

- (void)dealloc {
    [self cancel];
}

- (void)start {
	if (!download) {
		NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
		download = [session downloadTaskWithRequest:request];
		[download resume];
	}
}

- (void)cancel {
    [download cancel];
    download = nil;
}

- (BOOL)isRunning {
    return download != nil;
}

- (NSURLRequest *)request {
    return request;
}

- (NSURL *)url {
    return [request URL];
}

- (NSURL *)URL {
	return [request URL];
}

- (NSString *)destination {
	return destination;
}

- (double)progress {
	if (expectedContentLength == NSURLResponseUnknownLength) return 0.0;
	return (double)currentContentLength / expectedContentLength;
}

- (id)userInfo {
	return userInfo;
}

- (void)setUserInfo:(id)value {
	if (userInfo != value) {
		userInfo = value;
	}
}

- (int64_t)expectedContentLength {
	return expectedContentLength;
}

- (int64_t)currentContentLength {
	return currentContentLength;
}

- (void)sendDidUpdate {
    if(delegate && [delegate respondsToSelector:@selector(downloadDidUpdate:)])
        [delegate performSelector:@selector(downloadDidUpdate:) withObject:self];
}

#pragma mark NSURLSession Delegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
			 didWriteData:(int64_t)bytesWritten
		totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
	expectedContentLength = totalBytesExpectedToWrite;
	currentContentLength = totalBytesWritten;
	[self sendDidUpdate];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes {
	expectedContentLength = expectedTotalBytes;
	currentContentLength = fileOffset;
}

//- (BOOL)download:(NSURLDownload *)download shouldDecodeSourceDataOfMIMEType:(NSString *)encodingType {}
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
	NSString *newDestination = NSTemporaryDirectory();
	newDestination = [newDestination stringByAppendingPathComponent:[NSString uniqueString]];
	newDestination = [newDestination stringByAppendingPathExtension:@"qspkg"];
	[[NSFileManager defaultManager] moveItemAtPath:[location path] toPath:newDestination error:nil];
	destination = newDestination;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
	if (error) {
		if(delegate && [delegate respondsToSelector:@selector(download:didFailWithError:)])
        [delegate download:self didFailWithError:error];
		return;
	}

    if(delegate && [delegate respondsToSelector:@selector(downloadDidFinish:)])
        [delegate performSelector:@selector(downloadDidFinish:) withObject:self];
}

@end
