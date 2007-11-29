//
//  QSRegistry.h
//  Blocks
//
//  Copyright 2007 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Blocks.h"
#define QSReg [QSRegistry sharedInstance]



#define QSPlugInLoadedNotification @"QSPlugInLoaded"
#define QSPlugInInstalledNotification @"QSPlugInInstalled"

#define kQSActionProviders @"QSActionProviders"
#define kQSFSParsers @"QSFSParsers"
#define kQSObjectSources @"QSObjectSources"
#define kQSObjectHandlers @"QSObjectHandlers"
#define kQSPreferencePanes @"QSPreferencePanes"
//#define pRegistryStoreLocation QSApplicationSupportSubPath(@"Registry.plist",NO);

//#define prefInstances nil

@interface QSRegistry : BRegistry {
    NSMutableDictionary *prefInstances; //Preferred Instances of tables
}

- (id)coreInstanceWithID:(NSString *)core;
@end

