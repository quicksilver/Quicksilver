//
//  NDProcess+QSMods.h
//  Quicksilver
//
//  Created by Alcor on 9/3/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NDProcess (QSMods)
- (pid_t) pid;
- (NSDictionary *)processInfo;

- (BOOL)isVisible;
- (BOOL)isBackground;
- (BOOL)isCarbon;

@end
