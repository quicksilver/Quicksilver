//
//  TestNDHotkey.m
//  QSFoundationTests
//
//  Created by Patrick Robertson on 08/07/2022.
//

#import <XCTest/XCTest.h>

@interface TestNDHotkey : XCTestCase

@end

@implementation TestNDHotkey

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testCorrectKeyStrings {
    NSString *str = [[NDKeyboardLayout keyboardLayout] stringForKeyCode:124 modifierFlags:11534600];
    XCTAssertEqualObjects(str, @"⌘→");
}

@end
