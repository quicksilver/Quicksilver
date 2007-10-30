
//



#include <Carbon/Carbon.h>
#include <Cocoa/Cocoa.h>

#import "QSVoyeur.h"
#import "UKMainThreadProxy.h"
id QSVoy;

//#define mSHARED_INSTANCE_CLASS_METHOD(si) 

@implementation QSVoyeur

//mSHARED_INSTANCE_CLASS_METHOD(QSVoy)
+ (id)sharedInstance{
	@synchronized(self){if (!QSVoy) QSVoy = [[[self class] allocWithZone:[self zone]] init];}
	return QSVoy;
}

//+ (id)sharedInstance{
//    if (!QSVoy) QSVoy = [[[self class] allocWithZone:[self zone]] init];
//    //QSLog(@"lib instance:%@",_sharedInstance);
//    return QSVoy;
//}
- (id) init {
	self = [super init];
	if (self != nil) {
		[self setDelegate:[self mainThreadProxy]];
	//	[[[NSWorkspace sharedWorkspace] notificationCenter]addObserver:self 
//															  selector:@selector(fileWasDeleted:)
//																  name:UKFileWatcherDeleteNotification
//																object:nil];
	}
	return self;
}

-(void) watcher: (id)kq receivedNotification: (NSString*)nm forPath: (NSString*)fpath{
	if ([nm isEqualToString:UKFileWatcherDeleteNotification]){
		[self removePathFromQueue:fpath];
		[self addPathToQueue:fpath notifyingAbout:NOTE_DELETE];	
	}
	//QSLog(@"notifkq %@ %@",nm,fpath);
	[[[NSWorkspace sharedWorkspace] notificationCenter] postNotificationName: nm object: fpath];
}

@end
