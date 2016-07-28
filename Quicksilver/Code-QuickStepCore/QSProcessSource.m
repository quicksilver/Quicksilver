#import "QSProcessSource.h"
#import "QSResourceManager.h"
#import "QSObject.h"

#import <signal.h>
#include <sys/time.h>
#include <sys/resource.h>

#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>

#import "QSObject_FileHandling.h"
#import "QSProcessMonitor.h"
#import "NSWorkspace_BLTRExtensions.h"

#import "QSTypes.h"
#import "QSMacros.h"

@interface QSProcessObjectSource ()

@property (retain) NSRunningApplication *currentApplication;
@property (retain) NSRunningApplication *previousApplication;
@property (assign) NSTimeInterval processScanDate;

@end

@implementation QSProcessObjectSource
- (BOOL)usesGlobalSettings {return YES;}

- (NSView *)settingsView {
	if (![super settingsView]) {
		[NSBundle loadNibNamed:NSStringFromClass([self class]) owner:self];
	}
	return [super settingsView];
}

#define QSProcessSourceObservationContext "QSProcessSourceObservationContext"

- (id)init {
	self = [super init];
	if (!self) return nil;

	_processScanDate = [NSDate timeIntervalSinceReferenceDate];

	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values." kQSShowBackgroundProcesses options:NSKeyValueObservingOptionNew context:QSProcessSourceObservationContext];

	NSNotificationCenter *nc = [[NSWorkspace sharedWorkspace] notificationCenter];

	[nc addObserver:self selector:@selector(appChanged:) name:NSWorkspaceDidActivateApplicationNotification object:nil];

	return self;
}

- (void)dealloc {
	NSNotificationCenter *nc = [[NSWorkspace sharedWorkspace] notificationCenter];

	[nc removeObserver:self name:NSWorkspaceDidActivateApplicationNotification object:nil];

	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values." kQSShowBackgroundProcesses];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == QSProcessSourceObservationContext) {
		if ([keyPath isEqualToString:@"values." kQSShowBackgroundProcesses])
			[self invalidateSelf];
	}
}

#pragma mark -
#pragma mark Object Source

- (void)enableEntry:(QSCatalogEntry *)entry {
	NSNotificationCenter *nc = [[NSWorkspace sharedWorkspace] notificationCenter];

	[nc addObserver:self selector:@selector(appTerminated:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
	[nc addObserver:self selector:@selector(appLaunched:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
}

- (void)disableEntry:(QSCatalogEntry *)entry {
	NSNotificationCenter *nc = [[NSWorkspace sharedWorkspace] notificationCenter];

	[nc removeObserver:self name:NSWorkspaceDidTerminateApplicationNotification object:nil];
	[nc removeObserver:self name:NSWorkspaceDidLaunchApplicationNotification object:nil];

}

- (void)invalidateSelf {
	self.processScanDate = [NSDate timeIntervalSinceReferenceDate];
	[super invalidateSelf];
}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry {
	return ([indexDate timeIntervalSinceReferenceDate] > self.processScanDate);
}

- (NSImage *)iconForEntry:(QSCatalogEntry *)theEntry {
	return [QSResourceManager imageNamed:@"ExecutableBinaryIcon"];
}

- (QSObject *)imbuedObjectWithApplication:(NSRunningApplication *)application {
	NSURL *applicationURL = application.bundleURL;
	if (!applicationURL) applicationURL = application.executableURL;

	QSObject *newObject = [QSObject fileObjectWithFileURL:applicationURL];

	[newObject setObject:application forType:QSProcessType];

	return newObject;
}

- (NSArray *)objectsForEntry:(NSDictionary *)theEntry {
	BOOL showBackground = [[NSUserDefaults standardUserDefaults] boolForKey:kQSShowBackgroundProcesses];

	NSMutableArray *objects = [NSMutableArray array];
	for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
		if (!showBackground && app.isHidden) continue;

		QSObject *obj = [self imbuedObjectWithApplication:app];
		if (!obj) continue;
		[objects addObject:obj];
	}

	return objects;
}

#pragma mark -
#pragma mark Process Notifications

- (void)appLaunched:(NSNotification *)notif {
	NSRunningApplication *app = notif.userInfo[NSWorkspaceApplicationKey];
	if (!app) return;

	[self imbuedObjectWithApplication:app];
}

- (void)appTerminated:(NSNotification *)notif {
	NSRunningApplication *app = notif.userInfo[NSWorkspaceApplicationKey];
	if (!app) return;

	QSObject *object = [self imbuedObjectWithApplication:app];
	[object setObject:nil forType:QSProcessType];
}

- (void)appChanged:(NSNotification *)aNotification {
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	NSDictionary *newApp = [workspace activeApplication];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"Hide Other Apps When Switching"]) {
		if (!(GetCurrentKeyModifiers() & shiftKey) ) {
			//if (VERBOSE) NSLog(@"Hide Other Apps");
			[workspace hideOtherApplications:[NSArray arrayWithObject:newApp]];
		}
	}
	NSRunningApplication *application = aNotification.userInfo[NSWorkspaceApplicationKey];

	self.previousApplication = self.currentApplication;
	self.currentApplication = application;
}


#pragma mark -
#pragma mark Proxy provider

- (id)resolveProxyObject:(id)proxy {
	if ([[proxy identifier] isEqualToString:@"QSCurrentApplicationProxy"]) {
		//	NSLog(@"return");
		return [self imbuedObjectWithApplication:[[NSWorkspace sharedWorkspace] frontmostApplication]];
	} else if ([[proxy identifier] isEqualToString:@"QSPreviousApplicationProxy"]) {
		return [self imbuedObjectWithApplication:self.previousApplication];
	}
	return nil;
}

- (NSTimeInterval) cacheTimeForProxy:(id)proxy {
	return 0.0f;
}

@end

@implementation QSProcessActionProvider

- (QSObject *)activateApplication:(QSObject *)dObject {
	NSArray *array = [dObject arrayForType:QSProcessType];
	[array enumerateObjectsUsingBlock:^(NSRunningApplication *app, NSUInteger idx, BOOL *stop) {
		[app activateWithOptions:0];
	}];
	return nil;
}

- (QSObject *)switchToApplication:(QSObject *)dObject {
	NSArray *array = [dObject arrayForType:QSProcessType];
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];

	if (!array) {
		array = [dObject arrayForType:QSFilePathType];

		for(NSString * app in array) {
			[workspace openFile:app];
		}
		return nil;
	}

	if ([[NSApp currentEvent] type] == NSKeyDown && [[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)
		[workspace hideOtherApplications:array];

	NSDictionary *procDict;

	for(procDict in array) {

		if (!procDict ) {
			[workspace launchApplication:[procDict objectForKey:@"NSApplicationPath"]];
			continue;
		}
		BOOL frontmost = [workspace applicationIsFrontmost:procDict];
		NSInteger behavior = [[NSUserDefaults standardUserDefaults] integerForKey:@"QSActionAppReopenBehavior"];
		if (frontmost) behavior = 2;

		switch (behavior) {
			case 0:
				[workspace reopenApplication:procDict];
				break;
			case 1:
				[[NSWorkspace sharedWorkspace] activateApplication:procDict];
				break;
			case 2:
				[workspace reopenApplication:procDict];
				[workspace switchToApplication:procDict frontWindowOnly:NO];
				break;
		}
	}

	return nil;
}

- (QSObject *)toggleApplication:(QSObject *)dObject {

	NSArray *array = [dObject arrayForType:QSProcessType];
	//NSLog(@"arr %@", array);
	if (array) {
		if ([[NSWorkspace sharedWorkspace] applicationIsFrontmost:[array lastObject]]) {
		//	NSLog(@"showing");
            [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [[NSWorkspace sharedWorkspace] hideApplication:obj];
            }];
		} else {
            [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [[NSWorkspace sharedWorkspace] activateApplication:obj];
            }];
		}
	} else {
		array = [dObject validPaths];
        [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [[NSWorkspace sharedWorkspace] openFile:obj];
        }];
	}
	return nil;
}

- (QSObject *)hideApplication:(QSObject *)dObject {
	NSArray *array = [dObject arrayForType:QSProcessType];
	[array enumerateObjectsUsingBlock:^(NSRunningApplication *app, NSUInteger idx, BOOL *stop) {
		[app hide];
	}];
	return nil;
}

- (QSObject *)hideOtherApplications:(QSObject *)dObject {
	NSArray *array = [dObject arrayForType:QSProcessType];
	[[NSWorkspace sharedWorkspace] hideOtherApplications:array];
	return nil;
}

- (QSObject *)quitOtherApplications:(QSObject *)dObject {
	NSArray *array = [dObject arrayForType:QSProcessType];
	[[NSWorkspace sharedWorkspace] quitOtherApplications:array];
	return nil;
}

- (QSObject *)quitApplication:(QSObject *)dObject {
	NSArray *array = [dObject arrayForType:QSProcessType];
	[array enumerateObjectsUsingBlock:^(NSRunningApplication *app, NSUInteger idx, BOOL *stop) {
		[app terminate];
	}];
	return nil;
}

- (QSObject *)relaunchApplication:(QSObject *)dObject {
	NSArray *array = [dObject arrayForType:QSProcessType];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [[NSWorkspace sharedWorkspace] relaunchApplication:obj];
    }];
	return nil;
}

@end
