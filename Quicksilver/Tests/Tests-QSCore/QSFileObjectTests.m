//
//  QSFileObjectTests.m
//  Quicksilver
//
//  Created by Patrick Robertson on 29/05/2014.
//
//

#import <XCTest/XCTest.h>
#import "QSTypes.h"
#import "QSObject.h"
#import "QSObject_FileHandling.h"
#import "QSDirectoryParser.h"

@interface QSFileObjectTests : XCTestCase

@end

@implementation QSFileObjectTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class. 
    [super tearDown];
}

- (void)testFileNaming
{
    NSString *path = @"/bin/ls";
    QSObject *object = [QSObject fileObjectWithPath:path];
    XCTAssertEqualObjects([object name], @"ls", @"");
    XCTAssertNil([object label], @"");
    // label is localized, so this test might only work for a specific locale
    path = @"/Applications/Safari.app";
    object = [QSObject fileObjectWithPath:path];
    XCTAssertEqualObjects([object name], @"Safari.app");
    
    path = @"/System/Library/PreferencePanes/Accounts.prefPane";
    object = [QSObject fileObjectWithPath:path];
    XCTAssertEqualObjects(@"Accounts.prefPane", [object name], @"The name for pref pane objects should be the same as the filename");
    XCTAssertEqualObjects(@"Users & Groups", [object label], @"The label for pref pane objects should be 'nice' (not the filename)");

}

- (void)testFileUTI
{
    NSString *fakePythonScriptPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"/qs_test_script.py"];
    [[NSFileManager defaultManager] createFileAtPath:fakePythonScriptPath contents:nil attributes:nil];
    QSObject *object = [QSObject fileObjectWithPath:fakePythonScriptPath];
    NSString *type = [object fileUTI];

    XCTAssertEqualObjects(type, @"public.python-script", @"");
    object = [QSObject fileObjectWithPath:@"/usr/bin/yes"];
    XCTAssertTrue(UTTypeConformsTo((__bridge CFStringRef)[object fileUTI], (__bridge CFStringRef)@"public.executable"), @"/usr/bin/yes does not conform to public.executable");
    
    // Test that folders with extensions are given the correct UTI. Issue #1742
    NSString *path = @"/tmp/javascript.js";
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    object = [QSObject fileObjectWithPath:path];
    XCTAssertEqualObjects([object fileUTI], (NSString *)kUTTypeFolder, @"Folders with extensions should still be considered as folders (UTI of public.folder");
    
    // Test that text scripts are still considered as public.script. Issue #1841
    path = [[NSBundle bundleForClass:[self class]] pathForResource:@"Fast Logout" ofType:@"sh"];
    object = [QSObject fileObjectWithPath:path];
    XCTAssertTrue(UTTypeConformsTo((__bridge CFStringRef)[object fileUTI], (__bridge CFStringRef)@"public.script"), @"The fast logout script should be seen as a script by Quicksilver");
}

- (void)testFileObject
{
    NSString *path;
    if (@available(macOS 12, *)) {
        path = @"/System/Applications/TextEdit.app";
    } else {
        path = @"/Applications/TextEdit.app";
    }

    QSObject *object = [QSObject fileObjectWithPath:path];
    XCTAssertEqualObjects([object objectForType:QSFilePathType], path, @"");
    XCTAssertEqualObjects([object singleFilePath], path, @"");
    XCTAssertTrue([object isApplication], @"%@ should be seen as an application.", [object displayName]);
    XCTAssertTrue([object isDirectory], @"%@ should be seen as a directory.", [object displayName]);
    XCTAssertFalse([object isFolder], @"%@ should not be seen as a folder.", [object displayName]);
    XCTAssertEqualObjects([object fileExtension], @"app", @"");
    XCTAssertEqualObjects([object fileUTI], @"com.apple.application-bundle", @"");
}


@end
