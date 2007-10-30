//
//  QSURLDownloadWrapper.m
//  Quicksilver
//
//  Created by Alcor on 4/10/05.
//  Copyright 2005 Blacktree. All rights reserved.
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


- (void)sendDidReceiveResponse:(id)cfres {
  NSURLResponse *response = [NSURLResponse _responseWithCFURLResponse:cfres];
   	expectedContentLength+=[response expectedContentLength];
   [super sendDidReceiveResponse:response];
}

- (void)sendDidReceiveData:(long)length {

  	currentContentLength+=length;
  [super sendDidReceiveData:length];
}
   
//- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data lengthReceived:(long long)length{
//	currentContentLength+=length;
//	[super connection:(NSURLConnection *)connection didReceiveData:(NSData *)data lengthReceived:(long long)length];
//}

- (NSURL *)url{
	return [[self request]URL];
}

- (void)setDestination:(NSString *)path allowOverwrite:(BOOL)allowOverwrite {
  [destination release];
  destination = [path retain];
  [super setDestination:path allowOverwrite:allowOverwrite]; 
}
- (void)dealloc {
  [destination release];
  [super dealloc];
}

- (NSString *)destination{
	return destination;
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
