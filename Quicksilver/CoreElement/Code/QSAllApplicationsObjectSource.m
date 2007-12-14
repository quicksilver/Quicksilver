//
//  QSAllApplicationsObjectSource
//  Quicksilver
//
//  Created by Alcor on 4/5/05.

//

#import "QSAllApplicationsObjectSource.h"

@implementation QSAllApplicationsObjectSource
- (NSImage *) iconForEntry:(NSDictionary *)dict{return [[NSWorkspace sharedWorkspace]iconForFile:@"/Applications"];}

- (NSArray *) objectsForEntry:(NSDictionary *)dict{
   // [activityController updateTask:@"Scan" status:@"Searching for all Applications" progress:-1];
    NSArray *apps = [[NSWorkspace sharedWorkspace]allApplications];
   // QSLog(@"Added %4d known applications",[apps count]);
    return [QSObject fileObjectsWithPathArray:apps];
}
@end