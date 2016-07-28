

#import <Foundation/Foundation.h>

@interface QSProcessMonitor : NSObject
+ (id)sharedInstance;

@end

/* QSProcessMonitor notifications */
extern NSString *QSProcessMonitorFrontApplicationSwitched;
extern NSString *QSProcessMonitorApplicationLaunched;
extern NSString *QSProcessMonitorApplicationTerminated;
