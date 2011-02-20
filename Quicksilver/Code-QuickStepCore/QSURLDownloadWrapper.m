//
// QSURLDownloadWrapper.m
// Quicksilver
//
// Created by Alcor on 4/10/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "QSURLDownloadWrapper.h"

@implementation QSURLDownload
+ (id)downloadWithURL:(NSURL*)url delegate:(id)aDelegate {
    return [[[self alloc] initWithRequest:[NSURLRequest requestWithURL:url] delegate:aDelegate] autorelease];
}

- (id)initWithRequest:(NSURLRequest*)aRequest delegate:(id)aDelegate {
    if (aRequest == nil)
        [NSException raise:NSInvalidArgumentException format:@"QSURLDownload can't handle nil-requests"];
    
    self = [super init];
    if(!self) {
        [super release];
        return nil;
    }
    request = [aRequest copy];
    delegate = aDelegate;
    return self;
}

- (void)dealloc {
    [self cancel];
    [request release];
    [userInfo release];
	[destination release];
	[super dealloc];
}

- (void)start {
    if (!download)
        download = [[NSURLDownload alloc] initWithRequest:request delegate:self];
}

- (void)cancel {
    [download cancel];
    [download release];
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
	if (!expectedContentLength) return 0.0;
	return (double)currentContentLength / expectedContentLength;
}

- (id)userInfo {
	return userInfo;
}

- (void)setUserInfo:(id)value {
	if (userInfo != value) {
		[userInfo release];
		userInfo = [value retain];
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
}

- (void)download:(NSURLDownload *)download willResumeWithResponse:(NSURLResponse *)response fromByte:(long long)startingByte {
    expectedContentLength = [response expectedContentLength];
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
    destination = [path retain]; 
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
