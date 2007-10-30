//
//  QSShellScriptRunAction.h
//  Quicksilver
//
//  Created by Alcor on 9/13/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QSObject.h"
#import "QSAction.h"
NSString *QSGetShebangPathForScript(NSString *path);

#define kQSShellScriptRunAction @"QSShellScriptRunAction"
@interface QSShellScriptRunAction : NSObject

- (NSString *)runScript:(NSString *)path;
- (NSString *)runExecutable:(NSString *)path withArguments:(NSArray *)arguments;
@end
