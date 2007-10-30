//
//  QSDropletApplication.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 2/24/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "QSDropletApplication.h"
@protocol QSDropletHandling
- (void)handlePasteboardDrop:(NSPasteboard *)pb commandPath:(NSString *)path;
@end

@implementation QSDropletApplication
- (id) init {
	self = [super init];
	if (self != nil) {
		[self setDelegate:self];
		[self setServicesProvider:self];
	}
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
	[self resetTerminateDelay];
}

- (void)resetTerminateDelay{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self performSelector:@selector(terminate:) withObject:self afterDelay:10.0f];	
}
- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames{
	NSPasteboard *pboard=[NSPasteboard pasteboardWithUniqueName];
	//QSLog(@"files %@",filenames);
	[pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:nil];
    [pboard setPropertyList:filenames forType:NSFilenamesPboardType];	
	[self executeCommandWithPasteboard:pboard];
	[pboard releaseGlobally];
	[self resetTerminateDelay];
}

- (void)performService:(NSPasteboard *)pboard
			  userData:(NSString *)userData
				 error:(NSString **)error
{  
	[self executeCommandWithPasteboard:pboard];
	[self resetTerminateDelay];
}

- (BOOL)executeCommandWithPasteboard:(NSPasteboard *)pb{
	id proxy=[NSConnection rootProxyForConnectionWithRegisteredName:@"Quicksilver Droplet" host:nil];
	if (proxy){
		[proxy setProtocolForProxy:@protocol(QSDropletHandling)];
		NSString *path=[[NSBundle mainBundle]bundlePath];
		path=[path stringByAppendingPathComponent:@"Contents/Command.qscommand"];
		[proxy handlePasteboardDrop:pb commandPath:path];
	}else{	
		fprintf(stderr,"Unable to connect to Quicksilver\n");
		return 1;
	}    
	return 0;
}
@end
