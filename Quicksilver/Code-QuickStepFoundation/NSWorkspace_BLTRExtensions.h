//
//  NSWorkspace_BLTRExtensions.h
//  Quicksilver
//
//  Created by Alcor on Fri May 09 2003.
//  Copyright (c) 2003 Blacktree, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define QSAppIsRunning(x) [[NSWorkspace sharedWorkspace] applicationIsRunning:x]
@interface NSWorkspace (Misc)
- (NSArray <NSURL *> *)allApplicationsURLs;
- (NSArray <NSString *>*)allApplications;

- (NSString *)commentForFile:(NSString *)path;
- (BOOL)setComment:(NSString*)comment forFile:(NSString *)path;
@end

@interface NSWorkspace (QSApplicationExtensions)
- (void)hideOtherApplications:(NSArray <NSRunningApplication *> *)theApps;
- (void)quitOtherApplications:(NSArray <NSRunningApplication *> *)theApps;
- (BOOL)openFileInBackground:(NSString *)fullPath;
- (void)relaunchApplication:(NSRunningApplication *)theApp;
@end

@interface NSWorkspace (QSDeprecatedProcessManagment)
- (NSInteger)pidForApplication:(NSDictionary *)theApp QS_DEPRECATED_MSG("Use NSRunningApplication");
- (BOOL)applicationIsRunning:(NSString *)pathOrID QS_DEPRECATED_MSG("Use NSRunningApplication");
- (void)killApplication:(NSString *)path QS_DEPRECATED_MSG("Use NSRunningApplication");
- (BOOL)applicationIsHidden:(NSDictionary *)theApp QS_DEPRECATED_MSG("Use NSRunningApplication");
- (BOOL)applicationIsFrontmost:(NSDictionary *)theApp QS_DEPRECATED_MSG("Use NSRunningApplication");
- (void)switchToApplication:(NSDictionary *)theApp frontWindowOnly:(BOOL)frontOnly QS_DEPRECATED_MSG("Use NSRunningApplication");
- (void)activateFrontWindowOfApplication:(NSDictionary *)theApp QS_DEPRECATED_MSG("Use NSRunningApplication");
- (void)hideApplication:(NSDictionary *)theApp QS_DEPRECATED_MSG("Use NSRunningApplication");
- (void)showApplication:(NSDictionary *)theApp QS_DEPRECATED_MSG("Use NSRunningApplication");
- (void)activateApplication:(NSDictionary *)theApp QS_DEPRECATED_MSG("Use NSRunningApplication");
- (void)reopenApplication:(NSDictionary *)theApp QS_DEPRECATED_MSG("Use NSRunningApplication");
- (void)quitApplication:(NSDictionary *)theApp QS_DEPRECATED_MSG("Use NSRunningApplication");
- (NSString *)nameForPID:(pid_t)pid QS_DEPRECATED_MSG("Use NSRunningApplication");
- (NSString *)pathForPID:(pid_t)pid QS_DEPRECATED_MSG("Use NSRunningApplication");
@end
