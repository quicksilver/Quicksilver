//
//  QSUpdateController.h
//  Quicksilver
//
//  Created by Alcor on 7/22/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QSUpdateController : NSObject
+ (instancetype)sharedInstance;
- (IBAction)checkForUpdate:(id)sender;
- (IBAction)threadedRequestedCheckForUpdate:(id)sender;

/* Needed by QSPlugInManager */
- (NSArray *)extractFilesFromQSPkg:(NSString *)path toPath:(NSString *)tempDirectory;
@end
