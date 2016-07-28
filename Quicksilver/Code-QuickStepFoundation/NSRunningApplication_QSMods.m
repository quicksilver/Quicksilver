//
//  NSRunningApplication_QSMods.m
//  Quicksilver
//
//  Created by Etienne on 23/07/2016.
//
//

#import "NSRunningApplication_QSMods.h"

@implementation NSRunningApplication (QSMods)
+ (NSArray <NSRunningApplication *> *)runningApplicationsWithPath:(NSString *)path {
	NSURL *applicationURL = [NSURL fileURLWithPath:path];
	if (!applicationURL) {
		/* FIXME: Must check for the existence of path before the loop */
		return nil;
	}
	NSMutableArray *apps = [NSMutableArray array];
	for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
		if ([app.bundleURL isEqual:applicationURL]) [apps addObject:app];
	}
	return apps;
}

+ (instancetype)runningApplicationWithProcessSerialNumber:(ProcessSerialNumber)psn {
	pid_t pid;
	OSErr err = GetProcessPID(&psn, &pid);
	if (err != noErr) return nil;

	return [[self class] runningApplicationWithProcessIdentifier:pid];
}

- (NSRunningApplication *)parentApplication {
	OSErr err;
	ProcessSerialNumber psn;
	if (![self processSerialNumber:&psn]) return nil;

	ProcessInfoRec psr;
	err = GetProcessInformation(&psn, &psr);
	if (err != noErr) return nil;

	return [[self class] runningApplicationWithProcessSerialNumber:psr.processLauncher];
}

- (BOOL)processSerialNumber:(ProcessSerialNumber *)psn {
	NSParameterAssert(psn != NULL);
	return (GetProcessForPID(self.processIdentifier, psn) != noErr);
}
@end
