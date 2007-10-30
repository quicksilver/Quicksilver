//
//  QSSyncManager.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 1/2/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <SyncServices/SyncServices.h>

@interface QSSyncManager : NSObject {

}
- (void)registerSchema;
- (ISyncClient *)getSyncClient;
@end
