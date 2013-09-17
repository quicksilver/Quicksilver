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
	if (self = [super init]) {
		processScanDate = [NSDate timeIntervalSinceReferenceDate];
		processes = [NSMutableArray arrayWithCapacity:1];

		[[QSProcessMonitor sharedInstance] addObserver:self forKeyPath:@"allProcesses" options:NSKeyValueObservingOptionNew context:QSProcessSourceObservationContext];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values." kQSShowBackgroundProcesses options:NSKeyValueObservingOptionNew context:QSProcessSourceObservationContext];
	}
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == QSProcessSourceObservationContext) {
		if ([keyPath isEqualToString:@"allProcesses"]
			|| [keyPath isEqualToString:@"values." kQSShowBackgroundProcesses])
			[self invalidateSelf];
	}
}

- (void)invalidateSelf {
	processScanDate = [NSDate timeIntervalSinceReferenceDate];
	[super invalidateSelf];
}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry {
	return ([indexDate timeIntervalSinceReferenceDate] >processScanDate);
}

- (NSImage *)iconForEntry:(NSDictionary *)dict {
	return [QSResourceManager imageNamed:@"ExecutableBinaryIcon"];
}

- (NSArray *)objectsForEntry:(NSDictionary *)theEntry {
	BOOL showBackground = [[NSUserDefaults standardUserDefaults] boolForKey:kQSShowBackgroundProcesses];
	return showBackground ? [[QSProcessMonitor sharedInstance] allProcesses] : [[QSProcessMonitor sharedInstance] visibleProcesses];
}

@end

@implementation QSProcessActionProvider

- (QSObject *)activateApplication:(QSObject *)dObject {
	NSArray *array = [dObject arrayForType:QSProcessType];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [[NSWorkspace sharedWorkspace] activateApplication:obj];
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
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [[NSWorkspace sharedWorkspace] hideApplication:obj];
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
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [[NSWorkspace sharedWorkspace] quitApplication:obj];
    }];
	return nil;
}

- (QSObject *)relaunchApplication:(QSObject *)dObject {
	NSArray *array = [dObject arrayForType:QSProcessType];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [[NSWorkspace sharedWorkspace] performSelector:@selector(relaunchApplication:) withObject:obj];
    }];
	return nil;
}

@end
