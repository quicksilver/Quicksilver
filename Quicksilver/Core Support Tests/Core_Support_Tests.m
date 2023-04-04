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
    [f createSymbolicLinkAtPath:[tmpDir stringByAppendingPathComponent:@"Safari.app"] withDestinationPath:safariPath error:&e];
    // Alias
    NSData *bookmarkData = [[NSURL fileURLWithPath:safariPath] bookmarkDataWithOptions: NSURLBookmarkCreationSuitableForBookmarkFile includingResourceValuesForKeys:nil relativeToURL:nil error:nil];
    [NSURL writeBookmarkData:bookmarkData toURL:[NSURL fileURLWithPath:[tmpDir stringByAppendingPathComponent:@"Safari_alias.app"]] options:NSURLBookmarkCreationSuitableForBookmarkFile error:nil];
    
    QSDirectoryParser *parser = [QSDirectoryParser new];
    NSArray *res = [parser objectsFromPath:tmpDir depth:1 types:nil excludeTypes:nil descend:NO];
    XCTAssertEqual([res count], (NSUInteger)2, @"Number of files scanned is incorrect");
    
    res = [parser objectsFromPath:tmpDir depth:1 types:@[(__bridge NSString*)kUTTypeApplication] excludeTypes:nil descend:NO];
    
    XCTAssertEqual([res count], (NSUInteger)2, @"Number of application files scanned is incorrect");
    
    res = [parser objectsFromPath:tmpDir depth:1 types:nil excludeTypes:@[(__bridge NSString*)kUTTypeApplication] descend:NO];
    
    XCTAssertEqual([res count], (NSUInteger)0, @"Number of non-application files scanned is incorrect");
    
    
    [f removeItemAtPath:tmpDir error:nil];
}


@end
