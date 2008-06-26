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

static void KeyArrayCallback(const void *key, const void *value, void *context) { CFArrayAppendValue(context, key);  }

@implementation NSScreen (BLTRExtensions)

+ (NSScreen *)screenWithNumber:(int)number {
	NSEnumerator *e = [[self screens] objectEnumerator];
	NSScreen *screen;
	while(screen = [e nextObject]) {
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
	CFArrayRef langKeys, orderLangKeys;
    CFStringRef langKey;
    io_connect_t displayPort;
    CFDictionaryRef dict, names;
    NSString *localName = nil;
    
	displayPort = CGDisplayIOServicePort((CGDirectDisplayID)_screenNumber);
	if ( displayPort == MACH_PORT_NULL )
		return NULL; /* No physical device to get a name from */
	dict = IODisplayCreateInfoDictionary(displayPort, 0);

	names = CFDictionaryGetValue( dict, CFSTR(kDisplayProductName) );
	/* Extract all the display name locale keys */
	langKeys = CFArrayCreateMutable( kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks );
	CFDictionaryApplyFunction( names, KeyArrayCallback, (void *)langKeys );
	/* Get the preferred order of localizations */
	orderLangKeys = CFBundleCopyPreferredLocalizationsFromArray( langKeys );
	CFRelease( langKeys );

	if ( orderLangKeys && CFArrayGetCount(orderLangKeys) ) {
		langKey = CFArrayGetValueAtIndex( orderLangKeys, 0 );
		localName = (NSString*)CFDictionaryGetValue( names, langKey );
		CFRetain( localName );
	}

	CFRelease(orderLangKeys);
	CFRelease(dict);

	if (!localName) {
		uint32_t model = CGDisplayModelNumber((CGDirectDisplayID) _screenNumber);
		uint32_t vendor = CGDisplayVendorNumber((CGDirectDisplayID) _screenNumber);
		localName = [[NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"/System/Library/Displays/Overrides/DisplayVendorID-%x/DisplayProductID-%x", vendor, model]] objectForKey:@"DisplayProductName"];
		if (!localName) localName = [NSString stringWithFormat:@"Unknown Display (%x:%x)", vendor, model];
	} else {
		[localName autorelease];
	}
	return localName;
}
@end
