//
// NSScreen_BLTRExtensions.m
// Quicksilver
//
// Created by Alcor on 12/19/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "NSScreen_BLTRExtensions.h"
#include <IOKit/IOKitLib.h>
#include <IOKit/graphics/IOFramebufferShared.h>
#include <IOKit/graphics/IOGraphicsInterface.h>
#include <IOKit/graphics/IOGraphicsLib.h>
#include <IOKit/graphics/IOGraphicsTypes.h>
#include <ApplicationServices/ApplicationServices.h>
#include <objc/objc-runtime.h>
#import <CoreGraphics/CGDisplayStream.h>

@implementation NSScreen (BLTRExtensions)

+ (BOOL)screenRecordingPermissionAllowed {
		if ([[NSScreen mainScreen] hasScreenRecordingPermission]) {
				return YES;
		}
		// maybe the main screen can't produce a CGDisplayStream, but another screen can
		// a positive on any screen must mean that the permission is granted; we try on the other screens
		for (NSScreen *screen in [NSScreen screens]) {
				if ([screen screenNumber] == [[NSScreen mainScreen] screenNumber]) {
						continue;
				}
				if ([screen hasScreenRecordingPermission]) {
						return YES;
				}
		}
		return NO;
}

- (BOOL)hasScreenRecordingPermission {
		CGDirectDisplayID displayId = (CGDirectDisplayID)[self screenNumber];
		
		CGDisplayStreamRef ref = CGDisplayStreamCreateWithDispatchQueue(
																									 displayId,
																									 1,
																									 1,
																										kCVPixelFormatType_32BGRA,
																									 nil,
																									 dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
																										^(CGDisplayStreamFrameStatus status, uint64_t displayTime, IOSurfaceRef frameSurface, CGDisplayStreamUpdateRef updateRef) {
																												NSLog(@"Next Frame"); // This line is never called.
																										});

		BOOL hasPermission = (ref != nil);
		if (ref != nil) {
				CFRelease(ref);
		}
		return hasPermission;
}

+ (NSScreen *)screenWithNumber:(NSInteger)number {
	for(NSScreen *screen in [self screens]) {
		if ([screen screenNumber] == number) {
			return screen;
		}
	}
    //NSLog(@"Can't find Screen %d", number);NSLog(@"screenx %d %d", [screen screenNumber] , number);
	return nil;
}

- (NSInteger)screenNumber {
	// gets the screen number for a given NSScreen
    NSDictionary* screenDictionary = [self deviceDescription];
    NSNumber* screenID = [screenDictionary objectForKey:@"NSScreenNumber"];
    return [screenID integerValue];
} 

- (BOOL)usesOpenGLAcceleration {
	return (BOOL)CGDisplayUsesOpenGLAcceleration((uint32_t)[self screenNumber]);
}

- (NSString *)deviceName {
	if ([NSApplication isCatalina]) {
		// macOS 10.15+ available
		return [self localizedName];
	}
    io_connect_t displayPort;
    NSString *localName = nil;
    
	displayPort = CGDisplayIOServicePort((uint32_t)[self screenNumber]);
	if ( displayPort == MACH_PORT_NULL )
		return NULL; /* No physical device to get a name from */
	NSDictionary *dict = (NSDictionary *)CFBridgingRelease(IODisplayCreateInfoDictionary(displayPort, kIODisplayOnlyPreferredName));

    NSDictionary *localizedNames = [dict objectForKey:[NSString stringWithUTF8String:kDisplayProductName]];
    
	if ([localizedNames count] > 0) {
        localName = [localizedNames objectForKey:[[localizedNames allKeys] objectAtIndex:0]];
    }
    
	if (!localName) {
		uint32_t model = CGDisplayModelNumber((CGDirectDisplayID) [self screenNumber]);
		uint32_t vendor = CGDisplayVendorNumber((CGDirectDisplayID) [self screenNumber]);
		localName = [[NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"/System/Library/Displays/Overrides/DisplayVendorID-%x/DisplayProductID-%x", vendor, model]] objectForKey:@"DisplayProductName"];
		if (!localName) localName = [NSString stringWithFormat:@"Unknown Display (%x:%x)", vendor, model];
	}
	return localName;
}


- (NSURL*)wallpaperURL {
	return [[NSWorkspace sharedWorkspace] desktopImageURLForScreen:self];

}
@end
