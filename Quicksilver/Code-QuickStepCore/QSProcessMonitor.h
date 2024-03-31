

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

#define kQSShowBackgroundProcesses @"QSShowBackgroundProcesses"

@class QSObject;

@interface QSProcessMonitor : NSObject <QSProxyObjectProvider> {
	NSDictionary *processes;
	// a snapshot of processes dict, useful for keeping track of quit applications (for events etc.)
	NSDictionary *processesSnapshot;
	NSDictionary *currentApplication;
	NSDictionary *previousApplication;
    EventHandlerRef changeHandler;
	EventHandlerRef launchHandler;
	EventHandlerRef terminateHandler;
	BOOL isReloading;
}
+ (id)sharedInstance;

- (NSArray *)allProcesses; /* QSObjects */
- (NSArray *)visibleProcesses; /* QSObjects */
- (NSArray *)backgroundProcesses; /* QSObjects */

/* Deprecated, equivalent to the above without KVO */
- (NSArray *)getAllProcesses __attribute__((deprecated("Use -allProcesses")));
- (NSArray *)getVisibleProcesses __attribute__((deprecated("Use -visibleProcesses")));

- (QSObject *)imbuedFileProcessForDict:(NSDictionary *)dict;
- (BOOL)handleProcessEvent:(NSEvent *)theEvent;
- (QSObject *)processObjectWithPSN:(ProcessSerialNumber)psn;
- (QSObject *)processObjectWithPSN:(ProcessSerialNumber)psn fromSnapshot:(BOOL)snapshot;

- (NSDictionary *)currentApplication;
- (NSDictionary *)previousApplication;
@end

/* QSProcessMonitor notifications */
extern NSString *QSProcessMonitorFrontApplicationSwitched;
extern NSString *QSProcessMonitorApplicationLaunched;
extern NSString *QSProcessMonitorApplicationTerminated;
