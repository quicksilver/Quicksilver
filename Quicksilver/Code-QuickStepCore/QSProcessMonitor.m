#import "QSObject.h"
#import "QSObject_FileHandling.h"

#import "NDProcess+QSMods.h"

#import "QSProcessMonitor.h"
#import "QSTypes.h"


NSString *QSProcessMonitorFrontApplicationSwitched = @"QSProcessMonitorFrontApplicationSwitched";
NSString *QSProcessMonitorApplicationLaunched = @"QSProcessMonitorApplicationLaunched";
NSString *QSProcessMonitorApplicationTerminated = @"QSProcessMonitorApplicationTerminated";

@implementation QSProcessMonitor

+ (id)sharedInstance {
	static id _sharedInstance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedInstance = [[self alloc] init];
	});
	return _sharedInstance;
}

+ (NSArray *)processes {
	return nil;
}

- (id)init {
	self = [super init];
	if (!self) return nil;

	NSNotificationCenter *nc = [[NSWorkspace sharedWorkspace] notificationCenter];
	[nc addObserver:self selector:@selector(appTerminated:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
	[nc addObserver:self selector:@selector(appLaunched:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];

	return self;
}

- (void)dealloc {
	NSNotificationCenter *nc = [[NSWorkspace sharedWorkspace] notificationCenter];
	[nc removeObserver:self name:NSWorkspaceDidTerminateApplicationNotification object:nil];
	[nc removeObserver:self name:NSWorkspaceDidLaunchApplicationNotification object:nil];
}


- (void)appLaunched:(NSNotification *)notif {
	[[NSNotificationCenter defaultCenter] postNotificationName:QSProcessMonitorApplicationLaunched object:self];
}

- (void)appTerminated:(NSNotification *)notif {
	[[NSNotificationCenter defaultCenter] postNotificationName:QSProcessMonitorApplicationTerminated object:self];
}

@end
