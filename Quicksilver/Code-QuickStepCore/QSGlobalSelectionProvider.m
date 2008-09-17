//
// QSGlobalSelectionProvider.m
// Quicksilver
//
// Created by Alcor on 1/21/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "QSGlobalSelectionProvider.h"

#import "QSRegistry.h"

#import "QSProxyObject.h"
#import "QSObject_StringHandling.h"
#import "QSObject_Pasteboard.h"

#import "NDProcess.h"

#import "NDProcess+QSMods.h"

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
	if (VERBOSE) NSLog(@"Get Selection: %@ %d", userData, [userData characterAtIndex:0]);
    if(resultPboard)
        [resultPboard release]; 
	resultPboard = [pboard retain];
}

- (void)performService:(NSPasteboard *)pboard
			  userData:(NSString *)userData
				 error:(NSString **)error {
	if (VERBOSE) NSLog(@"xPerform Service: %@ %d", userData, [userData characterAtIndex:0]);
}

- (NSPasteboard *)getSelectionFromFrontApp {
	
	//NSLog(@"GET SEL");
	id oldServicesProvider = [[NSApp servicesProvider] retain];
	[NSApp setServicesProvider:self];
	//[self invokeService];
	[NSThread detachNewThreadSelector:@selector(invokeService)
							 toTarget:self withObject:nil];
	
	//	return nil;
	NSRunLoop *loop = [NSRunLoop currentRunLoop];
	NSDate *date = [NSDate date];
	while(!resultPboard && [date timeIntervalSinceNow] >-2) {
		[loop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
		//	NSLog(@"loop");
	}
	//	NSLog(@"got %@", resultPboard);
	[NSApp setServicesProvider:oldServicesProvider];
    [oldServicesProvider release];
	id result = [resultPboard autorelease];
	resultPboard = nil;
	return result;
}

- (void)dealloc {
	//	NSLog(@"release");
	[resultPboard release];
	[super dealloc];
}

- (void)invokeService {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	pid_t pid = [[[[NSWorkspace sharedWorkspace] activeApplication] objectForKey:@"NSApplicationProcessIdentifier"] intValue];
	AXUIElementRef app = AXUIElementCreateApplication (pid);
	
	//	NDProcess *proc = [NDProcess frontProcess];
	
	//BOOL carbon = [proc isCarbon];
	
	AXUIElementPostKeyboardEvent (app, (CGCharCode) 0, (CGKeyCode)55, true ); //Command
																			  //	if (carbon) AXUIElementPostKeyboardEvent (app, (CGCharCode) 0, (CGKeyCode)56, true ); //Shift
	AXUIElementPostKeyboardEvent (app, (CGCharCode) 0, (CGKeyCode)53, true ); //Escape
	AXUIElementPostKeyboardEvent (app, (CGCharCode) 0, (CGKeyCode)53, false ); //Escape
																			   //	if (carbon) AXUIElementPostKeyboardEvent (app, (CGCharCode) 0, (CGKeyCode)56, false ); //Shift
	AXUIElementPostKeyboardEvent (app, (CGCharCode) 0, (CGKeyCode)55, true ); //Command
	[pool release];
}

@end

@implementation QSGlobalSelectionProvider
//static QSObject *dropletSelection;

NSTimeInterval failDate = 0;

+ (id)currentSelection {
	NSDictionary *appDictionary = [[NSWorkspace sharedWorkspace] activeApplication];
	//while(1);
	NSString *identifier = [appDictionary objectForKey:@"NSApplicationBundleIdentifier"];
	
	NSDictionary *info = [[QSReg tableNamed:@"QSProxies"] objectForKey:identifier];
	if (info) {
		id provider = [QSReg getClassInstance:[info objectForKey:kQSProxyProviderClass]];
		//if (VERBOSE)
		//	NSLog(@"Using provider %@ for %@", provider, identifier);
		return [provider resolveProxyObject:nil];
	} else {
		
		QSTemporaryServiceProvider *sp = [[[QSTemporaryServiceProvider alloc] init] autorelease];
		NSPasteboard *pb = nil;
		
		if ([NSDate timeIntervalSinceReferenceDate] -failDate > 3.0)
			pb = [sp getSelectionFromFrontApp];
		
		if (!pb) {
			failDate = [NSDate timeIntervalSinceReferenceDate];
			return nil;
		}
		return [QSObject objectWithPasteboard:pb];
	}
	return [QSObject objectWithString:@"No Selection"]; //[QSObject nullObject];
}

- (id)resolveProxyObject:(id)proxy {
	id object = [QSGlobalSelectionProvider currentSelection];
	//NSLog(@"object %@", object);
	return object;
}

- (BOOL)bypassValidation {
	NSDictionary *appDictionary = [[NSWorkspace sharedWorkspace] activeApplication];
	NSString *identifier = [appDictionary objectForKey:@"NSApplicationBundleIdentifier"];
	if ([identifier isEqualToString:@"com.blacktree.Quicksilver"])
		return YES;
	else
		return NO;
}

- (NSArray *)typesForProxyObject:(id)proxy {
	NSDictionary *appDictionary = [[NSWorkspace sharedWorkspace] activeApplication];
	NSString *identifier = [appDictionary objectForKey:@"NSApplicationBundleIdentifier"];
	NSDictionary *info = [[QSReg tableNamed:@"QSProxies"] objectForKey:identifier];
	NSArray *array = [info objectForKey:kQSProxyTypes];
	if (!info) return [NSArray arrayWithObjects:NSStringPboardType, NSFilenamesPboardType, nil];
	if (array) return array;
	
	id provider = [QSReg getClassInstance:[info objectForKey:kQSProxyProviderClass]];
	return [provider typesForProxyObject:self];
}
@end

