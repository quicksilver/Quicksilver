//
// QSGlobalSelectionProvider.m
// Quicksilver
//
// Created by Alcor on 1/21/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "QSGlobalSelectionProvider.h"

#import "QSRegistry.h"
#import "QSProcessMonitor.h"
#import "QSProxyObject.h"
#import "QSObject_StringHandling.h"
#import "QSObject_Pasteboard.h"


@interface QSTemporaryServiceProvider : NSObject {
	NSPasteboard *resultPboard;
	//	NSString *resultUserData;
}
- (void)invokeService;
- (NSPasteboard *)getSelectionFromFrontApp;
@end

@implementation QSTemporaryServiceProvider
- (id)init {
	if (self = [super init]) {
		resultPboard = nil;
	}
	return self;
}

- (void)getSelection:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error {
#ifdef DEBUG
	if (VERBOSE) NSLog(@"Get Selection: %@ %C", userData, [userData characterAtIndex:0]);
#endif
	resultPboard = pboard;
}

#ifdef DEBUG
- (void)performService:(NSPasteboard *)pboard
			  userData:(NSString *)userData
				 error:(NSString **)error {
	if (VERBOSE) NSLog(@"xPerform Service: %@ %C", userData, [userData characterAtIndex:0]);
}
#endif

- (NSPasteboard *)getSelectionFromFrontApp {
	id __block result = nil;
	QSGCDMainSync(^{
		//NSLog(@"GET SEL");
		id oldServicesProvider = [NSApp servicesProvider];
		[NSApp setServicesProvider:self];
		[self performSelector:@selector(invokeService) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
		NSRunLoop *loop = [NSRunLoop currentRunLoop];
		NSDate *date = [NSDate date];
		while(!self->resultPboard && [date timeIntervalSinceNow] >-1) {
			[loop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
			//	NSLog(@"loop");
		}
		//	NSLog(@"got %@", resultPboard);
		[NSApp setServicesProvider:oldServicesProvider];
		result = self->resultPboard;
		self->resultPboard = nil;
	});
	return result;
}


- (void)invokeService {
	@autoreleasepool {
#ifdef DEBUG
		NSLog(@"Frontmost application is active: %@", [[[NSWorkspace sharedWorkspace] frontmostApplication] isActive]? @"YES" : @"NO");
#endif
		pid_t pid = [[[NSWorkspace sharedWorkspace] frontmostApplication] processIdentifier];
		
		
		CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);
		CGEventRef keyDown = CGEventCreateKeyboardEvent (source, (CGKeyCode)53, true); //Escape
		CGEventSetFlags(keyDown, kCGEventFlagMaskCommand);
		CGEventPostToPid(pid, keyDown);
		CGEventRef keyUp = CGEventCreateKeyboardEvent (source, (CGKeyCode)53, false); //Escape
		CGEventSetFlags(keyUp, kCGEventFlagMaskCommand);
		CGEventPostToPid(pid, keyUp);
		CFRelease(keyDown);
		CFRelease(keyUp);
		CFRelease(source);
	}
}

@end

@interface QSGlobalSelectionProvider ()

@property (assign) NSTimeInterval failDate;
@property (retain) NSDictionary *currentAppSelectionProxyInfo;
@property (retain) id currentAppSelectionProxyProvider;

@end

@implementation QSGlobalSelectionProvider

- (id)init
{
    self = [super init];
    if (self) {
        _failDate = 0.0;
    }
    return self;
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    static QSGlobalSelectionProvider *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)currentSelection
{
    // check to see if a plug-in is providing special behavior for the current application
    NSRunningApplication *app = [[NSWorkspace sharedWorkspace] frontmostApplication];
    NSString *identifier = [app bundleIdentifier];
    if ([identifier isEqualToString:kQSBundleID]) {
        identifier = [[[QSProcessMonitor sharedInstance] previousApplication] objectForKey:@"NSApplicationBundleIdentifier"];
    }
    self.currentAppSelectionProxyInfo = [[QSReg tableNamed:@"QSProxies"] objectForKey:identifier];
	if (self.currentAppSelectionProxyInfo) {
		self.currentAppSelectionProxyProvider = [QSReg getClassInstance:[self.currentAppSelectionProxyInfo objectForKey:kQSProxyProviderClass]];
		//if (VERBOSE)
		//	NSLog(@"Using provider %@ for %@", provider, identifier);
		return [self.currentAppSelectionProxyProvider resolveProxyObject:nil];
	} else {
        self.currentAppSelectionProxyInfo = nil;
        self.currentAppSelectionProxyProvider = nil;
		QSTemporaryServiceProvider *sp = [[QSTemporaryServiceProvider alloc] init];
		NSPasteboard *pb = nil;
		
		if ([NSDate timeIntervalSinceReferenceDate] - self.failDate > kQSDefaultProxyCacheTime)
			pb = [sp getSelectionFromFrontApp];
		
		if (!pb) {
			self.failDate = [NSDate timeIntervalSinceReferenceDate];
			return nil;
		}
		return [QSObject objectWithPasteboard:pb];
	}
	return [QSObject objectWithString:@"No Selection"]; //[QSObject nullObject];
}

+ (id)currentSelection
{
    return [[QSGlobalSelectionProvider sharedInstance] currentSelection];
}

- (id)resolveProxyObject:(id)proxy {
	return [self currentSelection];
}

- (BOOL)bypassValidation {
	NSRunningApplication *app = [[NSWorkspace sharedWorkspace] frontmostApplication];
	NSString *identifier = [app bundleIdentifier];
	if ([identifier isEqualToString:kQSBundleID])
		return YES;
	else
		return NO;
}

- (NSArray *)typesForProxyObject:(id)proxy {
    if ([self.currentAppSelectionProxyProvider respondsToSelector:@selector(typesForProxyObject:)]) {
        return [self.currentAppSelectionProxyProvider typesForProxyObject:self];
    }
    
    NSArray *array = [self.currentAppSelectionProxyInfo objectForKey:kQSProxyTypes];
    if (array) {
        return array;
    }
    
    return @[QSTextType];
}

- (NSTimeInterval)cacheTimeForProxy:(id)proxy
{
    if ([self.currentAppSelectionProxyProvider respondsToSelector:@selector(cacheTimeForProxy:)]) {
        return [self.currentAppSelectionProxyProvider cacheTimeForProxy:proxy];
    }
    return kQSDefaultProxyCacheTime;
}
@end
