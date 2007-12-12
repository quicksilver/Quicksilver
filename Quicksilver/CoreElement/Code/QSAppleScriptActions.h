//
//  QSAppleScriptActions.h
//  Quicksilver
//
//  Created by Alcor on 7/30/04.

//

#define kAppleScriptOpenTextAction @"AppleScriptProcessTextAction"
#define kAppleScriptOpenFilesAction @"AppleScriptOpenFilesAction"
#define kAppleScriptRunAction @"AppleScriptRunAction"

#define kAppleScriptRunTextAction @"AppleScriptRunTextAction"


#define kQSScriptSuite 'DAED'
#define kQSOpenTextScriptCommand 'opnt'


@interface QSAppleScriptActions : QSActionProvider 
- (void)runAppleScript:(NSString *)scriptPath withArguments:(QSObject *)iObject;
@end

