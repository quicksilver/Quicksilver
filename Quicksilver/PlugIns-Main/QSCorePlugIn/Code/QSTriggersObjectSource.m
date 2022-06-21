//
//  QSTriggersObjectSource.m
//  
//
//  Created by Patrick Robertson on 21/06/2022.
//

#import "QSTriggersObjectSource.h"

@implementation QSTriggersObjectSource

- (NSImage *)iconForEntry:(QSCatalogEntry *)theEntry { return [QSResourceManager imageNamed:@"Pref-Triggers"]; }

- (BOOL)entryCanBeIndexed:(QSCatalogEntry *)theEntry {return NO;}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(QSCatalogEntry *)theEntry {
    //    if (VERBOSE) NSLog(@"rescan catalog %d", firstCheck);
    return YES;
}

- (NSArray *)objectsForEntry:(QSCatalogEntry *)theEntry {
    return [[[QSTriggerCenter sharedInstance] triggers] arrayByEnumeratingArrayUsingBlock:^QSObject *(QSTrigger *trigger) {
        QSCommand *cmd = [trigger command];
        [cmd setName:[trigger name]];
        return cmd;
    }];
}

@end
