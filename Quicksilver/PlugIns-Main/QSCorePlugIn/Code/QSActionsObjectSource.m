//
//  QSActionsObjectSource.m
//  Quicksilver
//
//  Created by Rob McBroom on 2014/04/03.
//
//

#import "QSActionsObjectSource.h"

@implementation QSActionsObjectSource

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry
{
    // no need to scan on an interval
    // rescan should happen whenever a plug-in loads
    return YES;
}

- (void)enableEntry:(QSCatalogEntry *)entry
{
    // scan for actions after every plug-in loads
    [[NSNotificationCenter defaultCenter] addObserver:entry selector:@selector(invalidateIndex:) name:QSPlugInLoadedNotification object:nil];
}

- (NSArray *)objectsForEntry:(NSDictionary *)theEntry
{
    // find actions with no third pane
    NSIndexSet *simpleActionIndexes = [[QSExec actions] indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(QSAction *action, NSUInteger idx, BOOL *stop) {
        return ([action argumentCount] == 1 && [QSExec actionIsEnabled:action]);
    }];
    return [[QSExec actions] objectsAtIndexes:simpleActionIndexes];
}

@end

@implementation QSActionActions

#define QSPerformActionAction @"QSPerformActionAction"

- (QSObject *)performAction:(QSObject *)action withObject:(QSObject *)iObject
{
    return [(QSAction *)action performOnDirectObject:iObject indirectObject:nil];
}

- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject
{
    if ([[dObject primaryType] isEqualToString:QSActionType] && [(QSAction *)dObject argumentCount] == 1) {
        return @[QSPerformActionAction];
    }
    return nil;
}

- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject
{
    // find objects in the catalog that this action supports
    QSAction *selectedAction = (QSAction *)dObject;
    NSArray *types = [selectedAction directTypes];
    if ([types count] == 1 && [types[0] isEqualToString:QSTextType]) {
        // action only supports text - ask for some automatically
        return @[[QSObject textProxyObjectWithDefaultValue:@""]];
    }
    NSMutableSet *supportedObjects = [[NSMutableSet alloc] init];
    for (NSString *type in types) {
        if ([type isEqualToString:QSFilePathType] && [[selectedAction directFileTypes] count]) {
            NSArray *allFileObjects = [QSLib arrayForType:QSFilePathType];
            for (NSString *fileType in [selectedAction directFileTypes]) {
                for (QSObject *guy in allFileObjects) {
                    if ([fileType isEqualToString:@"*"] || QSTypeConformsTo([guy fileUTI], fileType)) {
                        [supportedObjects addObject:guy];
                    }
                }
            }
        } else {
            // type wasn't QSFilePathType, or it was but allows all files
            [supportedObjects addObjectsFromArray:[QSLib arrayForType:type]];
        }
    }
    return [supportedObjects allObjects];
}

@end
