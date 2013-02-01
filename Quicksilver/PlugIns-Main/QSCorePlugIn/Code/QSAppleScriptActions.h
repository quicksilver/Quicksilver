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
// opnt = OPeN Text
#define kQSOpenTextScriptCommand 'opnt'
// opfl = OPen FiLe
#define kQSOpenFileScriptCommand 'opfl'
// garc = Get ARgument Count
#define kQSGetArgumentCountCommand 'garc'
// giob = Get Indirect OBject
#define kQSGetIndirectObjectTypesCommand 'giob'
// gdob = Get Direct OBject
#define kQSGetDirectObjectTypesCommand 'gdob'
// IdOb = Indirect Object
#define kQSIndirectParameter 'IdOb'

@interface QSAppleScriptActions : QSActionProvider
- (QSObject*)runAppleScript:(NSString *)scriptPath withArguments:(QSObject *)iObject;
-(NSAppleEventDescriptor *)eventDescriptorForObject:(QSObject *)iObject;
@end

