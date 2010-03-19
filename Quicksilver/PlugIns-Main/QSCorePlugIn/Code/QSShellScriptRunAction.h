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

NSArray *QSGetShebangArgsForScript(NSString *path);

/* Deprecated, do not use !
 * It fails on things like #!/usr/bin/arch -i386 /usr/bin/ruby */
NSString *QSGetShebangPathForScript(NSString *path);

#define kQSShellScriptRunAction @"QSShellScriptRunAction"
@interface QSShellScriptRunAction : NSObject

- (NSString *)runScript:(NSString *)path;
- (NSString *)runExecutable:(NSString *)path withArguments:(NSArray *)arguments;
@end
