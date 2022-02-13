//
//  QSUpdateController.h
//  Quicksilver
//
//  Created by Alcor on 7/22/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QSUpdateController : NSObject {

}
@property (nonatomic) BOOL isCheckingForUpdates;
+ (instancetype)sharedInstance;
- (void)checkForUpdates:(BOOL)userInitiated;

/* Needed by QSPlugInManager */
- (NSArray *)extractFilesFromQSPkg:(NSString *)path toPath:(NSString *)tempDirectory;
@end
