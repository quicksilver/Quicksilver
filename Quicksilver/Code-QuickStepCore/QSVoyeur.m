#include <Cocoa/Cocoa.h>

#import "QSVoyeur.h"

id QSVoy;

@implementation QSVoyeur

+ (id)sharedInstance {
	@synchronized(self) {
		if (!QSVoy)
			QSVoy = [[[self class] allocWithZone:nil] init];
	}
	return QSVoy;
}

- (id)init {
	self = [super init];
	if (self != nil) {
		[self setDelegate:self];
		self.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
	}
	return self;
}

- (void)queue:(VDKQueue *)queue didReceiveNotification:(NSString *)notificationName forPath:(NSString *)fpath {
	if ([notificationName isEqualToString:VDKQueueDeleteNotification]) {
		[self removePath:fpath];
		[self addPath:fpath notifyingAbout:NOTE_DELETE];
	}
	[[[NSWorkspace sharedWorkspace] notificationCenter] postNotificationName:notificationName object:fpath];
}

@end
