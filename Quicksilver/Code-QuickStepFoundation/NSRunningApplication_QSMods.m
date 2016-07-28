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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	OSErr err = GetProcessPID(&psn, &pid);
#pragma clang diagnostic pop
	if (err != noErr) return nil;

	return [[self class] runningApplicationWithProcessIdentifier:pid];
}

- (NSRunningApplication *)parentApplication {
	OSErr err;
	ProcessSerialNumber psn;
	if (![self processSerialNumber:&psn]) return nil;

	ProcessInfoRec psr;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	err = GetProcessInformation(&psn, &psr);
#pragma clang diagnostic pop
	if (err != noErr) return nil;

	return [[self class] runningApplicationWithProcessSerialNumber:psr.processLauncher];
}

- (BOOL)processSerialNumber:(ProcessSerialNumber *)psn {
	NSParameterAssert(psn != NULL);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	return (GetProcessForPID(self.processIdentifier, psn) != noErr);
#pragma clang diagnostic pop
}
@end
