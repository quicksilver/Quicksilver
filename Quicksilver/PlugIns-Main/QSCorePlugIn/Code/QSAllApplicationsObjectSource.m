//
//  QSAllApplicationsObjectSource
//  Quicksilver
//
//  Created by Alcor on 4/5/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import "QSObject_FileHandling.h"
#import "QSAllApplicationsObjectSource.h"

@implementation QSAllApplicationsObjectSource
- (NSImage *)iconForEntry:(QSCatalogEntry *)theEntry { return [[NSWorkspace sharedWorkspace] iconForFile:@"/Applications"]; }
- (NSArray *)objectsForEntry:(QSCatalogEntry *)theEntry {
	return [QSObject fileObjectsWithPathArray:[[NSWorkspace sharedWorkspace] allApplications]];
}
@end
