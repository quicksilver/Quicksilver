//
//  NDProcess+QSMods.m
//  Quicksilver
//
//  Created by Alcor on 9/3/04.

//

#import "NDProcess+QSMods.h"


@implementation NDProcess (QSMods)
- (pid_t)pid{
	pid_t pid=-1;
	GetProcessPID(&processSerialNumber,&pid);
	return pid;
}
-  (NSString *)identifier{
	NSDictionary *dict=(NSDictionary *)ProcessInformationCopyDictionary(&processSerialNumber,kProcessDictionaryIncludeAllInformationMask);	
	[dict autorelease];
	return [dict objectForKey:@"CFBundleIdentifier"];
}
- (NSDictionary *)processInfo{
	NSDictionary *processDict=[NSDictionary dictionaryWithObjectsAndKeys:
		[self name],@"NSApplicationName",
		[self path],@"NSApplicationPath",
		[self identifier],@"NSApplicationBundleIdentifier",
		[NSNumber numberWithInt:[self pid]],@"NSApplicationProcessIdentifier",
		[NSNumber numberWithLong:processSerialNumber.highLongOfPSN],@"NSApplicationProcessSerialNumberHigh",
		[NSNumber numberWithLong:processSerialNumber.lowLongOfPSN],@"NSApplicationProcessSerialNumberLow",
		nil]; 
	return processDict;
}
- (BOOL)isVisible{
	return IsProcessVisible(&processSerialNumber);
}

- (BOOL)isBackground{
	NSDictionary *dict=(NSDictionary *)ProcessInformationCopyDictionary(&processSerialNumber,kProcessDictionaryIncludeAllInformationMask);	
	
	//QSLog(@"UIElement:%@ Background:%@",[dict objectForKey:@"LSUIElement"],dict);
	BOOL background=[[dict objectForKey:@"LSUIElement"]boolValue]||[[dict objectForKey:@"LSBackgroundOnly"]boolValue];
	[dict autorelease];
	
	return background;
}

- (BOOL)isCarbon{
	NSDictionary *dict=(NSDictionary *)ProcessInformationCopyDictionary(&processSerialNumber,kProcessDictionaryIncludeAllInformationMask);	
	BOOL carbon=[[dict objectForKey:@"RequiresCarbon"]boolValue];
	[dict autorelease];
	return carbon;
}
@end
