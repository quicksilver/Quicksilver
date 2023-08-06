//
//  QSPathsTests.m
//  QSCoreTests
//
//  Created by Nathan Henrie on 2023-09-11.
//

#import <XCTest/XCTest.h>
#import "QSPaths.h"


@interface QSPathsTests : XCTestCase

@end

@implementation QSPathsTests

- (void)testMockAppSupport {
    // When in a test context, `TESTING` should be defined, and the Application Support folder should
    // be mocked so user config doesn't interfere with testing.
    // See also: https://github.com/quicksilver/Quicksilver/pull/2954
    XCTAssert(TESTING);
    NSString *appSupportFolder = QSGetApplicationSupportFolder();
    NSString *defaultAppSupport = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Application Support/Quicksilver"];
    XCTAssertNotEqualObjects(appSupportFolder, defaultAppSupport);
}

@end
