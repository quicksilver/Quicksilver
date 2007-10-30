

#import <Foundation/Foundation.h>
@class QSObject;

@interface QSProcessMonitor : NSObject {
    NSMutableArray *processes;
	NSDictionary *currentApplication;
	NSDictionary *previousApplication;
}
+ (id)sharedInstance;
-(NSArray *)visibleProcesses;
-(NSArray *)allProcesses;
- (void)reloadProcesses;
- (QSObject *)imbuedFileProcessForDict:(NSDictionary *)dict;

+ (id)sharedInstance;
+ (NSArray *)processes;
- (void)regisiterForAppChangeNotifications;
- (QSObject *)processObjectWithPSN:(ProcessSerialNumber)psn;
- (BOOL)handleProcessEvent:(NSEvent *)theEvent;
- (void)appChanged:(NSNotification *)aNotification;
- (void)processTerminated:(QSObject *)thisProcess;
- (void)removeProcessWithPSN:(ProcessSerialNumber)psn;
- (QSObject *)processObjectWithDict:(NSDictionary *)dict;
- (void)appTerminated:(NSNotification *)notif;
- (void)appLaunched:(NSNotification *)notif;
- (void)addProcessWithDict:(NSDictionary *)info;

- (NSArray *) getAllProcesses;
- (NSArray *) getVisibleProcesses;
- (QSObject *)imbuedFileProcessForDict:(NSDictionary *)dict;
- (void)reloadProcesses;

- (void)setPreviousApplication:(NSDictionary *)newPreviousApplication ;
- (void)setCurrentApplication:(NSDictionary *)newCurrentApplication ;
@end
