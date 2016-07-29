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

#ifdef DEBUG
	if(DEBUG_MEMORY) NSLog(@"QSVolumesObjectSource dealloc");
#endif
	
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
}


- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(QSCatalogEntry *)theEntry {
	return ([indexDate timeIntervalSinceReferenceDate] >lastMountDate);
}

- (void)invalidateSelf {
	lastMountDate = [NSDate timeIntervalSinceReferenceDate];
	[super invalidateSelf];
}

- (void)setQuickIconForObject:(QSObject *)object
{
	[object setIcon:[QSResourceManager imageNamed:@"RemovableVolumeIcon"]];
}

- (NSArray *)objectsForEntry:(QSCatalogEntry *)theEntry
{
	if ([theEntry.identifier isEqualToString:@"QSPresetRemovableVolumes"]) {
		QSObject *volumesParent = [QSObject makeObjectWithIdentifier:@"QSRemovableVolumesParent"];
		NSString *name = NSLocalizedString(@"Network and Removable Disks", nil);
		[volumesParent setName:name];
		[volumesParent setPrimaryType:@"QSRemovableVolumesParentType"];
		return [NSArray arrayWithObject:volumesParent];
	}
	if ([theEntry.identifier isEqualToString:@"QSPresetVolumes"]) {
		return [QSObject fileObjectsWithPathArray:[[NSWorkspace sharedWorkspace] mountedLocalVolumePaths]];
	}
	return nil;
}

- (BOOL)objectHasChildren:(QSObject *)object
{
	NSArray *volumes = [[NSFileManager defaultManager] mountedVolumeURLsIncludingResourceValuesForKeys:nil options:NSVolumeEnumerationSkipHiddenVolumes];
	return ([volumes count] > 1);
}

- (BOOL)loadChildrenForObject:(QSObject *)object
{
	NSArray *volumes = [[NSFileManager defaultManager] mountedVolumeURLsIncludingResourceValuesForKeys:nil options:NSVolumeEnumerationSkipHiddenVolumes];
	if ([volumes count] < 2) {
		return NO;
	}
	NSMutableArray *volumePaths = [[volumes arrayByPerformingSelector:@selector(path)] mutableCopy];
	[volumePaths removeObject:@"/"];
	[object setChildren:[QSObject fileObjectsWithPathArray:volumePaths]];
	return YES;
}

@end
