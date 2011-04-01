

#import <Foundation/Foundation.h>

#define kQSShowBackgroundProcesses @"QSShowBackgroundProcesses"

@class QSObject;

@interface QSProcessMonitor : NSObject {
	NSMutableArray *processes;
	NSDictionary *currentApplication;
	NSDictionary *previousApplication;
    EventHandlerRef eventHandler;
}
+ (id)sharedInstance;
- (NSArray *)visibleProcesses;
- (NSArray *)allProcesses;
- (void)reloadProcesses;
- (QSObject *)imbuedFileProcessForDict:(NSDictionary *)dict;

+ (id)sharedInstance;
+ (NSArray *)processes;
- (QSObject *)processObjectWithPSN:(ProcessSerialNumber)psn;
- (BOOL)handleProcessEvent:(NSEvent *)theEvent;
- (void)appChanged:(NSNotification *)aNotification;
- (void)processTerminated:(QSObject *)thisProcess;
- (void)removeProcessWithPSN:(ProcessSerialNumber)psn;
- (QSObject *)processObjectWithDict:(NSDictionary *)dict;
- (void)appTerminated:(NSNotification *)notif;
- (void)appLaunched:(NSNotification *)notif;
- (void)addProcessWithDict:(NSDictionary *)info;

- (NSArray *)getAllProcesses;
- (NSArray *)getVisibleProcesses;
- (QSObject *)imbuedFileProcessForDict:(NSDictionary *)dict;
- (void)reloadProcesses;
- (NSDictionary *)previousApplication;
- (void)setPreviousApplication:(NSDictionary *)newPreviousApplication ;
- (void)setCurrentApplication:(NSDictionary *)newCurrentApplication ;
@end
