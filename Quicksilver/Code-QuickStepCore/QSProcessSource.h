/* QSDefaultsObjectSource */

#import <Cocoa/Cocoa.h>
#import "QSObjectSource.h"

#import "QSActionProvider.h"

#define kQSShowBackgroundProcesses @"QSShowBackgroundProcesses"

@interface QSProcessObjectSource : QSObjectSource <QSProxyObjectProvider>

@property (readonly) NSRunningApplication *currentApplication;
@property (readonly) NSRunningApplication *previousApplication;

@end

# define kProcessKillAction @"ProcessKillAction"
# define kProcessSuspendAction @"ProcessSuspendAction"
# define kProcessResumeAction @"ProcessResumeAction"

# define kProcessSetPriorityAction @"ProcessSetPriorityAction"


# define kProcessLowerPriorityAction @"ProcessLowerPriorityAction"
# define kProcessRaisePriorityAction @"ProcessRaisePriorityAction"

# define kProcessNormalPriorityAction @"ProcessNormalPriorityAction"
# define kProcessHighPriorityAction @"ProcessHighPriorityAction"
# define kProcessLowPriorityAction @"ProcessLowPriorityAction"
# define kProcessVeryHighPriorityAction @"ProcessVeryHighPriorityAction"
# define kProcessVeryLowPriorityAction @"ProcessVeryLowPriorityAction"


# define kAppHideAction @"AppHideAction"
# define kAppHideOthersAction @"AppHideOthersAction"

# define kAppQuitAction @"AppQuitAction"

# define kAppActivateAction @"AppActivateAction"
# define kAppReopenAction @"AppReopenAction"

@interface QSProcessActionProvider : QSActionProvider {
}
//- (int) pidOfProcess:(QSObject *)dObject;
//- (BOOL)setPriority:(int)priority ofPID:(int)pid;
//- (void)setPriority:(int)priority ofProcess:(QSObject *)dObject;
//- (void)sendSignal:(int)signal toProcess:(QSObject *)dObject;
@end
