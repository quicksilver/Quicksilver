//
//  QSFileSystemMonitor.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 9/19/05.

//

#import "QSFileSystemMonitor.h"


@implementation QSFileSystemMonitor
mSHARED_INSTANCE_CLASS_METHOD

- (id) init {
	self = [super init];
	if (self != nil) {
		logger=[[NSTask taskWithLaunchPath:[@"~/bin/qsfslogger" stringByStandardizingPath]
								 arguments:[NSArray array]]retain];
		[logger setStandardOutput:[NSPipe pipe]];
		output=[[logger standardOutput]fileHandleForReading];
		[output retain];
		[[NSNotificationCenter defaultCenter]addObserver:self
												selector:@selector(pathsChanged:)
													name:NSFileHandleReadCompletionNotification
												  object:output];
		[logger launch];
		[output readInBackgroundAndNotify];
	}
	return self;
}
- (void)pathsChanged:(NSNotification *)notif{
	//QSLog(@"notif %@",notif);
	NSString *string=[[[NSString alloc]initWithData:[[notif userInfo]objectForKey:NSFileHandleNotificationDataItem] encoding:NSUTF8StringEncoding]autorelease];
	QSLog(@"Changed: %@",string);
		[[notif object] readInBackgroundAndNotify];
}

@end
