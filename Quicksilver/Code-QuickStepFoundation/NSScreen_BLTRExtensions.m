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
//#include <Carbon/Carbon.h>
#include <ApplicationServices/ApplicationServices.h>

@implementation NSScreen (BLTRExtensions)

+ (NSScreen *)screenWithNumber:(int)number {
	for(NSScreen *screen in [self screens]) {
		if ([screen screenNumber] == number) {
			return screen;
		}
	}
    //NSLog(@"Can't find Screen %d", number);NSLog(@"screenx %d %d", [screen screenNumber] , number);
	return nil;
}

- (int)screenNumber{
	return _screenNumber;//[[[self deviceDescription]objectForKey:@"NSScreenNumber"]intValue]; 
} 

- (BOOL)usesOpenGLAcceleration {
	return (BOOL)CGDisplayUsesOpenGLAcceleration((CGDirectDisplayID)_screenNumber);
}

- (NSString *)deviceName {
    io_connect_t displayPort;
    NSString *localName = nil;
    
	displayPort = CGDisplayIOServicePort((CGDirectDisplayID)_screenNumber);
	if ( displayPort == MACH_PORT_NULL )
		return NULL; /* No physical device to get a name from */
	NSDictionary *dict = (NSDictionary *)IODisplayCreateInfoDictionary(displayPort, kIODisplayOnlyPreferredName);

    NSDictionary *localizedNames = [dict objectForKey:[NSString stringWithUTF8String:kDisplayProductName]];
    
	if ([localizedNames count] > 0) {
        localName = [localizedNames objectForKey:[[localizedNames allKeys] objectAtIndex:0]];
    }
    if (localName) {
        [[localName retain] autorelease];
    }

    [dict release];
    
	if (!localName) {
		uint32_t model = CGDisplayModelNumber((CGDirectDisplayID) _screenNumber);
		uint32_t vendor = CGDisplayVendorNumber((CGDirectDisplayID) _screenNumber);
		localName = [[NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"/System/Library/Displays/Overrides/DisplayVendorID-%x/DisplayProductID-%x", vendor, model]] objectForKey:@"DisplayProductName"];
		if (!localName) localName = [NSString stringWithFormat:@"Unknown Display (%x:%x)", vendor, model];
	}
	return localName;
}
@end
