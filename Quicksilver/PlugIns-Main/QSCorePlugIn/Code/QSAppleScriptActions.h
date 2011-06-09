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
#define kQSGetArgumentCountCommand 'garc'
#define kQSOpenTextIndirectParameter 'IdTx'

@interface QSAppleScriptActions : QSActionProvider
- (QSObject*)runAppleScript:(NSString *)scriptPath withArguments:(QSObject *)iObject;
@end

