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
	//NSLog(@"GET SEL");
	id oldServicesProvider = [NSApp servicesProvider];
	[NSApp setServicesProvider:self];
	[NSThread detachNewThreadSelector:@selector(invokeService)
							 toTarget:self withObject:nil];
	NSRunLoop *loop = [NSRunLoop currentRunLoop];
	NSDate *date = [NSDate date];
	while(!resultPboard && [date timeIntervalSinceNow] >-2) {
		[loop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		//	NSLog(@"loop");
	}
	//	NSLog(@"got %@", resultPboard);
	[NSApp setServicesProvider:oldServicesProvider];
	id result = resultPboard;
	resultPboard = nil;
	return result;
}


- (void)invokeService {
    @autoreleasepool {
        pid_t pid = [[[[NSWorkspace sharedWorkspace] activeApplication] objectForKey:@"NSApplicationProcessIdentifier"] intValue];
        //AXUIElement* is unable to post keys into sandboxed app since 10.7, use Quartz Event Services instead
		/* We need the PSN because CGEventPostToPSN below. Its PID-taking replacement is 10.11+ only */
		ProcessSerialNumber psn;
        BOOL usePID = GetProcessForPID(pid, &psn) == 0;
        CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStatePrivate);
        CGEventRef keyDown = CGEventCreateKeyboardEvent (source, (CGKeyCode)53, true); //Escape
        CGEventSetFlags(keyDown, kCGEventFlagMaskCommand);
        if (usePID) {
            CGEventPostToPSN(&psn, keyDown);
        } else {
            CGEventPost(kCGHIDEventTap, keyDown);
        }
        CGEventRef keyUp = CGEventCreateKeyboardEvent (source, (CGKeyCode)53, false); //Escape
        CGEventSetFlags(keyUp, kCGEventFlagMaskCommand);
        if (usePID) {
            CGEventPostToPSN(&psn, keyUp);
        } else {
            CGEventPost(kCGHIDEventTap, keyUp);
        }
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
	NSRunningApplication *app = [[NSWorkspace sharedWorkspace] menuBarOwningApplication];
	NSString *identifier = [app bundleIdentifier];
    if ([identifier isEqualToString:kQSBundleID]) {
		app = [[QSProcessMonitor sharedInstance] previousApplication];
		identifier = [app bundleIdentifier];
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
	NSDictionary *appDictionary = [[NSWorkspace sharedWorkspace] activeApplication];
	NSString *identifier = [appDictionary objectForKey:@"NSApplicationBundleIdentifier"];
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
