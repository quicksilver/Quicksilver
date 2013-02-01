//
//  QSAppleScriptActions.h
//  Quicksilver
//
//  Created by Alcor on 7/30/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QSActionProvider.h"

# define kAppleScriptOpenTextAction @"AppleScriptProcessTextAction"
# define kAppleScriptOpenFilesAction @"AppleScriptOpenFilesAction"
# define kAppleScriptRunAction @"AppleScriptRunAction"

// Used as a prefix to the identifier for all AppleScript action objects. Distinguishes them from plain old files
# define kAppleScriptActionIDPrefix @"[Action]:"


# define kAppleScriptRunTextAction @"AppleScriptRunTextAction"

#define kQSScriptSuite 'DAED'
#define kQSOpenTextScriptCommand 'opnt'
#define kQSOpenFileScriptCommand 'opfl'
#define kQSGetArgumentCountCommand 'garc'
#define kQSGetIndirectObjectTypesCommand 'giob'
#define kQSGetDirectObjectTypesCommand 'gdob'
#define kQSIndirectParameter 'IdOb'

@interface QSAppleScriptActions : QSActionProvider
- (QSObject*)runAppleScript:(NSString *)scriptPath withArguments:(QSObject *)iObject;
-(NSAppleEventDescriptor *)eventDescriptorForObject:(QSObject *)iObject;
@end

