//
//  QSFileObjectTests.m
//  Quicksilver
//
//  Created by Patrick Robertson on 29/05/2014.
//
//

#import <SenTestingKit/SenTestingKit.h>
#import "QSTypes.h"
#import "QSObject.h"
#import "QSObject_FileHandling.h"

@interface QSFileObjectTests : SenTestCase

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
    STAssertEqualObjects([object name], @"ls", nil);
    STAssertNil([object label], nil);
    // label is localized, so this test might only work for a specific locale
    path = @"/Applications/Safari.app";
    object = [QSObject fileObjectWithPath:path];
    STAssertEqualObjects([object name], @"Safari.app", nil);
    STAssertEqualObjects([object label], @"Safari", nil);
}

- (void)testFileUTI
{
    QSObject *object = [QSObject fileObjectWithPath:@"/usr/bin/smtpd.py"];
    NSString *type = [object fileUTI];
    STAssertEqualObjects(type, @"public.python-script", nil);
    object = [QSObject fileObjectWithPath:@"/usr/bin/2to3"];
    STAssertTrue(UTTypeConformsTo((CFStringRef)[object fileUTI], (CFStringRef)@"public.executable"), @"/usr/bin/2to3 does not conform to public.executable");
    
    // Test that folders with extensions are given the correct UTI. Issue #1742
    NSString *path = @"/tmp/javascript.js";
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    object = [QSObject fileObjectWithPath:path];
    STAssertEqualObjects([object fileUTI], (NSString *)kUTTypeFolder, @"Folders with extensions should still be considered as folders (UTI of public.folder");
    
    // Test that text scripts are still considered as public.script. Issue #1841
    path = [[NSBundle bundleForClass:[self class]] pathForResource:@"Fast Logout" ofType:@"sh"];
    object = [QSObject fileObjectWithPath:path];
    STAssertTrue(UTTypeConformsTo((CFStringRef)[object fileUTI], (CFStringRef)@"public.script"), @"The fast logout script should be seen as a script by Quicksilver");
}

- (void)testFileObject
{
    NSString *path = @"/Applications/TextEdit.app";
    QSObject *object = [QSObject fileObjectWithPath:path];
    STAssertEqualObjects([object objectForType:QSFilePathType], path, nil);
    STAssertEqualObjects([object singleFilePath], path, nil);
    STAssertTrue([object isApplication], @"%@ should be seen as an application.", [object displayName]);
    STAssertTrue([object isDirectory], @"%@ should be seen as a directory.", [object displayName]);
    STAssertFalse([object isFolder], @"%@ should not be seen as a folder.", [object displayName]);
    STAssertEqualObjects([object fileExtension], @"app", nil);
    STAssertEqualObjects([object fileUTI], @"com.apple.application-bundle", nil);
}


@end
