//
// NDProcess+QSMods.m
// Quicksilver
//
// Created by Alcor on 9/3/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "NDProcess+QSMods.h"

@implementation NDProcess (QSMods)
- (pid_t) pid {
	return self.processID;
}
- (NSString *)identifier {
	NSDictionary *dict = (NSDictionary *)CFBridgingRelease(ProcessInformationCopyDictionary(&processSerialNumber, kProcessDictionaryIncludeAllInformationMask));
	id ident = [dict objectForKey:@"CFBundleIdentifier"];
	return ident;
}
- (NSDictionary *)processInfo {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[self name] , @"NSApplicationName",
		[self path] , @"NSApplicationPath",
		[self identifier] , @"NSApplicationBundleIdentifier",
		[NSNumber numberWithInt:[self pid]], @"NSApplicationProcessIdentifier",
		[NSNumber numberWithLong:processSerialNumber.highLongOfPSN] , @"NSApplicationProcessSerialNumberHigh",
		[NSNumber numberWithLong:processSerialNumber.lowLongOfPSN] , @"NSApplicationProcessSerialNumberLow",
		nil];
}
- (BOOL)isVisible { return IsProcessVisible(&processSerialNumber); }

- (BOOL)isBackground {
	NSDictionary *dict = (NSDictionary *)CFBridgingRelease(ProcessInformationCopyDictionary(&processSerialNumber, kProcessDictionaryIncludeAllInformationMask));
	BOOL background = [[dict objectForKey:@"LSUIElement"] boolValue] || [[dict objectForKey:@"LSBackgroundOnly"] boolValue];
	return background;
}

- (BOOL)isCarbon {
	NSDictionary *dict = (NSDictionary *)CFBridgingRelease(ProcessInformationCopyDictionary(&processSerialNumber, kProcessDictionaryIncludeAllInformationMask));
	BOOL carbon = [[dict objectForKey:@"RequiresCarbon"] boolValue];
	return carbon;
}
@end
