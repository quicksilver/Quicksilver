

#import <Foundation/Foundation.h>

#define kQSShowBackgroundProcesses @"QSShowBackgroundProcesses"

@class QSObject;

@interface QSProcessMonitor : NSObject <QSProxyObjectProvider> {
	NSMutableDictionary *processes;
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
- (QSObject *)processObjectWithPSN:(ProcessSerialNumber)psn;

- (BOOL)handleProcessEvent:(NSEvent *)theEvent;

- (NSDictionary *)currentApplication;
- (NSDictionary *)previousApplication;
@end

/* QSProcessMonitor notifications */
extern NSString *QSProcessMonitorFrontApplicationSwitched;
extern NSString *QSProcessMonitorApplicationLaunched;
extern NSString *QSProcessMonitorApplicationTerminated;
