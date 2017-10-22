//
// QSURLDownloadWrapper.m
// Quicksilver
//
// Created by Alcor on 4/10/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "QSURLDownloadWrapper.h"

@interface QSURLDownload () <NSURLSessionTaskDelegate> {
	NSURLRequest *request;
	NSURLSessionDataTask *download;
	long long expectedContentLength;
	long long currentContentLength;
	id userInfo;
	NSString *destination;
	id <QSURLDownloadDelegate> delegate;
}
@end

@interface QSURLSession : NSObject <NSURLSessionDelegate, NSURLSessionDataDelegate> {
	NSOperationQueue *_queue;
	NSURLSession *_session;
}

@end

@implementation QSURLSession

+ (QSURLSession *)sharedSession {
	static QSURLSession *sharedSession = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedSession = [[self alloc] init];
	});
	return sharedSession;
}

- (instancetype)init {
	self = [super init];
	if (!self) return nil;

	_queue = [[NSOperationQueue alloc] init];
	_session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]
												  delegate:self
											 delegateQueue:_queue];

	return self;
}

- (NSURLSession *)session {
	return _session;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
	session;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {

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
	NSAssert(download == nil, @"download already started");

	download = [[[QSURLSession sharedSession] session] dataTaskWithRequest:request];
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

- (long long)expectedContentLength {
	return expectedContentLength;
}

- (long long)currentContentLength {
	return currentContentLength;
}

- (void)sendDidUpdate {
    if(delegate && [delegate respondsToSelector:@selector(downloadDidUpdate:)])
        [delegate performSelector:@selector(downloadDidUpdate:) withObject:self];
}

#pragma mark NSURLDownload Delegate
- (void)downloadDidBegin:(NSURLDownload *)download {
}

/*- (NSURLRequest *)download:(NSURLDownload *)download willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
    
}*/

- (void)download:(NSURLDownload *)download didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
}

- (void)download:(NSURLDownload *)download didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response {
    expectedContentLength = [response expectedContentLength];
	if (expectedContentLength == NSURLResponseUnknownLength) {
		NSNumber *contentLength = [[(NSHTTPURLResponse *)response allHeaderFields] objectForKey:@"Content-Length"];
		if (contentLength)
			expectedContentLength = [contentLength longLongValue];
	}
}

- (void)download:(NSURLDownload *)download willResumeWithResponse:(NSURLResponse *)response fromByte:(long long)startingByte {
    expectedContentLength = [response expectedContentLength];
	if (expectedContentLength == NSURLResponseUnknownLength) {
		NSNumber *contentLength = [[(NSHTTPURLResponse *)response allHeaderFields] objectForKey:@"Content-Length"];
		if (contentLength)
			expectedContentLength = [contentLength longLongValue];
	}
    currentContentLength = startingByte;
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length {
    currentContentLength += length;
    [self sendDidUpdate];
}

//- (BOOL)download:(NSURLDownload *)download shouldDecodeSourceDataOfMIMEType:(NSString *)encodingType {}
- (void)download:(NSURLDownload *)aDownload decideDestinationWithSuggestedFilename:(NSString *)filename {
    NSString *newDestination = NSTemporaryDirectory();
    newDestination = [newDestination stringByAppendingPathComponent:[NSString uniqueString]];
    newDestination = [newDestination stringByAppendingPathExtension:@"qspkg"];
    [aDownload setDestination:newDestination allowOverwrite:YES];
}

- (void)download:(NSURLDownload *)download didCreateDestination:(NSString *)path {
    destination = path; 
}

- (void)downloadDidFinish:(QSURLDownload *)download {
    if(delegate && [delegate respondsToSelector:@selector(downloadDidFinish:)])
        [delegate performSelector:@selector(downloadDidFinish:) withObject:self];
}

- (void)download:(QSURLDownload *)download didFailWithError:(NSError *)error {
    if(delegate && [delegate respondsToSelector:@selector(download:didFailWithError:)])
        [delegate download:self didFailWithError:error];
}

@end
