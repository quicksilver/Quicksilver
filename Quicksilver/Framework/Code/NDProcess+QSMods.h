//
//  NDProcess+QSMods.h
//  Quicksilver
//
//  Created by Alcor on 9/3/04.

//

#import <Cocoa/Cocoa.h>

#import "NDProcess.h"

@interface NDProcess (QSMods)
- (pid_t)pid;
- (NSDictionary *)processInfo;

- (BOOL)isVisible;
- (BOOL)isBackground;
- (BOOL)isCarbon;

@end
