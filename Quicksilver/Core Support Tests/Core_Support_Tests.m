//
//  Core_Support_Tests.m
//  Core Support Tests
//
//  Created by Patrick Robertson on 22/06/2014.
//
//

#import <XCTest/XCTest.h>
#import "QSDirectoryParser.h"

@interface Core_Support_Tests : XCTestCase

@end

@implementation Core_Support_Tests

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

- (void)testDirectoryScanning {
    // Create temp directory
    NSString *tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"/qs_tests"];
    NSFileManager *f = [NSFileManager defaultManager];
    [f createDirectoryAtPath:tmpDir withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *safariPath = @"/Applications/Safari.app";

    // Symlink
    NSError *e;
    NSString *symlinkPath = [tmpDir stringByAppendingPathComponent:@"Safari.app"];
    [f createSymbolicLinkAtPath:symlinkPath withDestinationPath:safariPath error:&e];

    // Recursive symlink
    NSString *badSymlinkPath = [tmpDir stringByAppendingPathComponent:@"Safari_recursive.app"];
    [f createSymbolicLinkAtPath:badSymlinkPath withDestinationPath:badSymlinkPath error:&e];

    // Alias
    NSData *bookmarkData = [[NSURL fileURLWithPath:safariPath] bookmarkDataWithOptions: NSURLBookmarkCreationSuitableForBookmarkFile includingResourceValuesForKeys:nil relativeToURL:nil error:nil];
    NSString *aliasPath = [tmpDir stringByAppendingPathComponent:@"Safari_alias.app"];
    [NSURL writeBookmarkData:bookmarkData toURL:[NSURL fileURLWithPath:aliasPath] options:NSURLBookmarkCreationSuitableForBookmarkFile error:nil];

    // Symlink to alias
    [f createSymbolicLinkAtPath:[tmpDir stringByAppendingPathComponent:@"Safari.app_alias_symlink"] withDestinationPath:aliasPath error:&e];

    // Alias to symlink
    NSData *bookmarkData2 = [[NSURL fileURLWithPath:symlinkPath] bookmarkDataWithOptions: NSURLBookmarkCreationSuitableForBookmarkFile includingResourceValuesForKeys:nil relativeToURL:nil error:nil];
    [NSURL writeBookmarkData:bookmarkData2 toURL:[NSURL fileURLWithPath:[tmpDir stringByAppendingPathComponent:@"Safari.app_symlink_alias"]] options:NSURLBookmarkCreationSuitableForBookmarkFile error:nil];

    QSDirectoryParser *parser = [QSDirectoryParser new];
    NSArray *res = [parser objectsFromPath:tmpDir depth:1 types:nil excludeTypes:nil descend:NO];
    XCTAssertEqual([res count], 5, @"Number of files scanned is incorrect");
    
    res = [parser objectsFromPath:tmpDir depth:1 types:@[(__bridge NSString*)kUTTypeApplication] excludeTypes:nil descend:NO];
    
    XCTAssertEqual([res count], 4, @"Number of application files scanned is incorrect");
    
    res = [parser objectsFromPath:tmpDir depth:1 types:nil excludeTypes:@[(__bridge NSString*)kUTTypeApplication] descend:NO];
    
    XCTAssertEqual([res count], 1, @"Number of non-application files scanned is incorrect");
    
    
    [f removeItemAtPath:tmpDir error:nil];
}


@end
