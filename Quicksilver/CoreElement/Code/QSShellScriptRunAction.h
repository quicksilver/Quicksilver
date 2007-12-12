//
//  QSShellScriptRunAction.h
//  Quicksilver
//
//  Created by Alcor on 9/13/04.

//

#import <Cocoa/Cocoa.h>

NSString *QSGetShebangPathForScript(NSString *path);

#define kQSShellScriptRunAction @"QSShellScriptRunAction"
@interface QSShellScriptRunAction : NSObject

- (NSString *)runScript:(NSString *)path;
- (NSString *)runExecutable:(NSString *)path withArguments:(NSArray *)arguments;
@end
