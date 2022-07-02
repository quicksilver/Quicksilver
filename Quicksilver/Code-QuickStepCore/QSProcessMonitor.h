

#import <Foundation/Foundation.h>

#define kQSShowBackgroundProcesses @"QSShowBackgroundProcesses"

@class QSObject;

@interface QSProcessMonitor : NSObject <QSProxyObjectProvider> {
	NSDictionary *processes;
	NSDictionary *currentApplication;
	NSDictionary *previousApplication;
    EventHandlerRef changeHandler;
	EventHandlerRef launchHandler;
	EventHandlerRef terminateHandler;
	BOOL isReloading;
}
+ (id)sharedInstance;
+ (NSArray *)processes; /* NDProcesses */

- (NSArray *)allProcesses; /* QSObjects */
- (NSArray *)visibleProcesses; /* QSObjects */
- (NSArray *)backgroundProcesses; /* QSObjects */

/* Deprecated, equivalent to the above without KVO */
- (NSArray *)getAllProcesses QS_DEPRECATED_MSG("Use -allProcesses");
- (NSArray *)getVisibleProcesses QS_DEPRECATED_MSG("Use -visibleProcesses");

- (QSObject *)imbuedFileProcessForDict:(NSDictionary *)dict;
- (BOOL)handleProcessEvent:(NSEvent *)theEvent;
- (QSObject *)processObjectWithPSN:(ProcessSerialNumber)psn;

- (NSDictionary *)currentApplication;
- (NSDictionary *)previousApplication;
@end

/* QSProcessMonitor notifications */
extern NSString *QSProcessMonitorFrontApplicationSwitched;
extern NSString *QSProcessMonitorApplicationLaunched;
extern NSString *QSProcessMonitorApplicationTerminated;
