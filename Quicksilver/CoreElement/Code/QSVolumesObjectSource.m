//
//  QSVolumesObjectSource.m
//  Quicksilver
//
//  Created by Alcor on 4/5/05.

//

#import "QSVolumesObjectSource.h"

@implementation QSVolumesObjectSource

- (id) init{
    if ((self=[super init])){
        lastMountDate=[NSDate timeIntervalSinceReferenceDate];
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(invalidateSelf) name:NSWorkspaceDidMountNotification object: nil];
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(invalidateSelf) name:NSWorkspaceDidUnmountNotification object: nil];
    }
	return self;
}
- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry{
    return ([indexDate timeIntervalSinceReferenceDate]>lastMountDate);
}



- (void)invalidateSelf{
    lastMountDate=[NSDate timeIntervalSinceReferenceDate];
    [super invalidateSelf];
}


//NSWorkspaceDidMountNotification
//NSWorkspaceDidUnmountNotification

- (NSImage *) iconForEntry:(NSDictionary *)dict{return [[NSWorkspace sharedWorkspace]iconForFile:@"/"];}

- (NSArray *) objectsForEntry:(NSDictionary *)dict{
    NSArray *volumes=[QSObject fileObjectsWithPathArray:[[NSWorkspace sharedWorkspace] mountedLocalVolumePaths]];
	
	//  QSLog(@"Added %4d volumes",[volumes count]);
    return volumes;
}


-(id)resolveProxyObject:(id)proxy{	
	if ([[proxy identifier]isEqualToString:@"QSNetworkVolumesProxy"]){
		NSArray *paths=[[NSWorkspace sharedWorkspace] mountedRemovableMedia];
		NSMutableArray *netPaths=[NSMutableArray array];
		foreach(path,paths){
			if ([path hasPrefix:@"/Network"])[netPaths addObject:path];	
		}
		return [QSObject fileObjectWithArray:paths];
	}
	if ([[proxy identifier]isEqualToString:@"QSMountedVolumesProxy"]){
		return [QSObject fileObjectWithArray:[[NSWorkspace sharedWorkspace] mountedLocalVolumePaths]];
	}
	if ([[proxy identifier]isEqualToString:@"QSRemoveableVolumesProxy"]){
		return [QSObject fileObjectWithArray:[[NSWorkspace sharedWorkspace] mountedRemovableMedia]];
	}
	return nil;
	
}



@end
