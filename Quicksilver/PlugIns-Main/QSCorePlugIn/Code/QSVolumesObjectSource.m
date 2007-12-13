//
// QSVolumesObjectSource.m
// Quicksilver
//
// Created by Alcor on 4/5/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "QSVolumesObjectSource.h"
#import "QSObject_FileHandling.h"
#import <QSCore/QSObject.h>

@implementation QSVolumesObjectSource

- (id)init {
	if (self = [super init]) {
		lastMountDate = [NSDate timeIntervalSinceReferenceDate];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(invalidateSelf) name:NSWorkspaceDidMountNotification object: nil];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(invalidateSelf) name:NSWorkspaceDidUnmountNotification object: nil];
	}
	return self;
}

- (void)dealloc {
	if(DEBUG_MEMORY) NSLog(@"QSVolumesObjectSource dealloc");
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[super dealloc];
}


- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry {
	return ([indexDate timeIntervalSinceReferenceDate] >lastMountDate);
}

- (void)invalidateSelf {
	lastMountDate = [NSDate timeIntervalSinceReferenceDate];
	[super invalidateSelf];
}

- (NSImage *)iconForEntry:(NSDictionary *)dict {return [[NSWorkspace sharedWorkspace] iconForFile:@"/"];}

- (NSArray *)objectsForEntry:(NSDictionary *)dict {
	NSArray *volumes = [QSObject fileObjectsWithPathArray:[[NSWorkspace sharedWorkspace] mountedLocalVolumePaths]];

	// NSLog(@"Added %4d volumes", [volumes count]);
	return volumes;
}

- (id)resolveProxyObject:(id)proxy {
	if ([[proxy identifier] isEqualToString:@"QSNetworkVolumesProxy"]) {
		NSArray *paths = [[NSWorkspace sharedWorkspace] mountedRemovableMedia];
		NSMutableArray *netPaths = [NSMutableArray array];
		foreach(path, paths) {
			if ([path hasPrefix:@"/Network"]) [netPaths addObject:path];
		}
		return [QSObject fileObjectWithArray:paths];
	}
	if ([[proxy identifier] isEqualToString:@"QSMountedVolumesProxy"]) {
		return [QSObject fileObjectWithArray:[[NSWorkspace sharedWorkspace] mountedLocalVolumePaths]];
	}
	if ([[proxy identifier] isEqualToString:@"QSRemoveableVolumesProxy"]) {
		return [QSObject fileObjectWithArray:[[NSWorkspace sharedWorkspace] mountedRemovableMedia]];
	}
	return nil;

}

@end
