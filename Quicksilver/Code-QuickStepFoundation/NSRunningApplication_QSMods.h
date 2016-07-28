//
//  NSRunningApplication_QSMods.h
//  Quicksilver
//
//  Created by Etienne on 23/07/2016.
//
//

#import <Foundation/Foundation.h>
#import <AppKit/NSRunningApplication.h>

@interface NSRunningApplication (QSMods)
+ (NSArray <NSRunningApplication *> *)runningApplicationsWithPath:(NSString *)path;
+ (instancetype)runningApplicationWithProcessSerialNumber:(ProcessSerialNumber)psn;
- (NSRunningApplication *)parentApplication;
- (BOOL)processSerialNumber:(ProcessSerialNumber *)psn;
@end
