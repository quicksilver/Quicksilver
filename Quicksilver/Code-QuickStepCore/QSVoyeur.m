#include <Carbon/Carbon.h>
#include <Cocoa/Cocoa.h>

#import "QSVoyeur.h"
#import "UKMainThreadProxy.h"

id QSVoy;

@implementation QSVoyeur

+ (id)sharedInstance {
	@synchronized(self) {
		if (!QSVoy)
			QSVoy = [[[self class] allocWithZone:[self zone]] init];
	}
	return QSVoy;
}

- (id)init {
	self = [super init];
	if (self != nil) {
		[self setDelegate:[self mainThreadProxy]];
	}
	return self;
}

- (void)watcher:(id)kq receivedNotification:(NSString*)nm forPath:(NSString*)fpath {
	if ([nm isEqualToString:UKFileWatcherDeleteNotification]) {
		[self removePathFromQueue:fpath];
		[self addPathToQueue:fpath notifyingAbout:NOTE_DELETE];
	}
	[[[NSWorkspace sharedWorkspace] notificationCenter] postNotificationName:nm object:fpath];
}

@end
