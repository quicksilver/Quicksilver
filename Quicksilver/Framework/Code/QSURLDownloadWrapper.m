//
//  QSURLDownloadWrapper.m
//  Quicksilver
//
//  Created by Alcor on 4/10/05.

//

#import "QSURLDownloadWrapper.h"

@interface NSURLDownload (NSPrivate)
- (NSString *)_currentPath;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data lengthReceived:(long long)length;
@end

@implementation QSURLDownload
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
	expectedContentLength+=[response expectedContentLength];
	[super connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data lengthReceived:(long long)length{
	currentContentLength+=length;
	[super connection:(NSURLConnection *)connection didReceiveData:(NSData *)data lengthReceived:(long long)length];
}

- (NSURL *)url{
	return [[self request]URL];
}
- (NSString *)destination{
	return [self _currentPath];
}
- (double)progress{
	if (!expectedContentLength)return 0.0;
	double progress=(double)currentContentLength/expectedContentLength;	
	return progress;
}
- (id)userInfo {
    return [[userInfo retain] autorelease];
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

@end
