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
- (NSInteger) pidForApplication:(NSDictionary *)theApp;
- (BOOL)applicationIsRunning:(NSString *)pathOrID;
- (void)killApplication:(NSString *)path;
- (BOOL)applicationIsFrontmost:(NSDictionary *)theApp;
- (void)switchToApplication:(NSDictionary *)theApp frontWindowOnly:(BOOL)frontOnly;
- (void)activateFrontWindowOfApplication:(NSDictionary *)theApp;
- (void)hideApplication:(NSDictionary *)theApp;
- (void)hideOtherApplications:(NSArray *)theApps;
- (void)showApplication:(NSDictionary *)theApp;
- (void)activateApplication:(NSDictionary *)theApp;
- (void)reopenApplication:(NSDictionary *)theApp;
- (void)quitApplication:(NSDictionary *)theApp;
- (void)quitOtherApplications:(NSArray *)theApps;
- (NSDictionary *)dictForApplicationIdentifier:(NSString *)ident QS_DEPRECATED;
- (NSString *)commentForFile:(NSString *)path;
- (BOOL)setComment:(NSString*)comment forFile:(NSString *)path;
- (BOOL)openFileInBackground:(NSString *)fullPath;
- (void)relaunchApplication:(NSDictionary *)theApp;
@end
