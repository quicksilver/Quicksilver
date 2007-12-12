//
//  QSAppleScriptActions.h
//  Quicksilver
//
//  Created by Alcor on 7/30/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>
# define kAppleScriptOpenTextAction @"AppleScriptProcessTextAction"
# define kAppleScriptOpenFilesAction @"AppleScriptOpenFilesAction"
# define kAppleScriptRunAction @"AppleScriptRunAction"

# define kAppleScriptRunTextAction @"AppleScriptRunTextAction"
#import "QSActionProvider.h"


#define kQSScriptSuite 'DAED'
#define kQSOpenTextScriptCommand 'opnt'


@interface QSAppleScriptActions : QSActionProvider
- (void)runAppleScript:(NSString *)scriptPath withArguments:(QSObject *)iObject;
@end

