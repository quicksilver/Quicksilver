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

# define kAppleScriptRunTextAction @"AppleScriptRunTextAction"

#define kQSScriptSuite 'DAED'
#define kQSOpenTextScriptCommand 'opnt'
#define kQSOpenFileScriptCommand 'opfl'
#define kQSGetArgumentCountCommand 'garc'
#define kQSIndirectParameter 'IdOb'

@interface QSAppleScriptActions : QSActionProvider
- (QSObject*)runAppleScript:(NSString *)scriptPath withArguments:(QSObject *)iObject;
-(NSAppleEventDescriptor *)eventDescriptorForObject:(QSObject *)iObject;
@end

