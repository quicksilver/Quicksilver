//
//  TestNSApplicationMethods.m
//  Quicksilver
//
//  Created by Patrick Robertson on 01/10/2014.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "NSApplication_BLTRExtensions.h"

@interface TestNSApplicationMethods : XCTestCase

@end

@implementation TestNSApplicationMethods

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCompareOSXVersions {
    // Assumes that all development is done on at least a Mountain Lion machine
    XCTAssertTrue([NSApplication isLeopard], @"Current operating system is not seen as Leopard or newer");;
    XCTAssertTrue([NSApplication isSnowLeopard], @"Current operating system is not seen as Snow Leopard or newer");
    XCTAssertTrue([NSApplication isLion], @"Current operating system is not seen as Lion or newer");
    XCTAssertTrue([NSApplication isMountainLion], @"Current operating system is not seen as Mountain Lion or newer");
}

- (void)testNSScreenAdditions {
	NSURL *u = [[NSScreen mainScreen] wallpaperURL];
	XCTAssertNotNil(u);
	
	NSString *name = [[NSScreen mainScreen] deviceName];
	XCTAssertNotNil(name);
	
}

@end
