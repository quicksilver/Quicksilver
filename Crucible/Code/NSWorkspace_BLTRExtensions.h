//
//  NSWorkspace_BLTRExtensions.h
//  Quicksilver
//
//  Created by Alcor on Fri May 09 2003.

//

#import <Foundation/Foundation.h>

#define QSAppIsRunning(x) [[NSWorkspace sharedWorkspace]applicationIsRunning:x]
@interface NSWorkspace (Misc)
- (NSArray *)allApplications;
- (int)pidForApplication:(NSDictionary *)theApp;
- (BOOL)applicationIsRunning:(NSString *)pathOrID;
- (NSDictionary *)dictForApplicationName:(NSString *)path;
- (void)killApplication:(NSString *)path;
- (BOOL)applicationIsHidden:(NSDictionary *)theApp;
- (BOOL)applicationIsFrontmost:(NSDictionary *)theApp;
- (BOOL)PSN:(ProcessSerialNumber *)psn forApplication:(NSDictionary *)theApp;
- (void)switchToApplication:(NSDictionary *)theApp frontWindowOnly:(BOOL)frontOnly;
- (void)activateFrontWindowOfApplication:(NSDictionary *)theApp;
- (void)hideApplication:(NSDictionary *)theApp;    
- (void)hideOtherApplications:(NSArray *)theApps;
- (void)showApplication:(NSDictionary *)theApp;
- (void)activateApplication:(NSDictionary *)theApp;
- (void)reopenApplication:(NSDictionary *)theApp; 
- (void)quitApplication:(NSDictionary *)theApp;
- (NSString *)nameForPID:(int)pid;
- (NSString *)pathForPID:(int)pid;
- (void)quitPSN:(ProcessSerialNumber)psn;
- (void)quitOtherApplications:(NSArray *)theApps;
- (NSDictionary *)dictForApplicationIdentifier:(NSString *)ident;
- (NSString *)commentForFile:(NSString *)path;
- (BOOL)setComment:(NSString*)comment forFile:(NSString *)path;
- (BOOL)openFileInBackground:(NSString *)fullPath;
@end
