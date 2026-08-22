//
//  TestNSURLCanonicalPath.m
//  Quicksilver
//
//  Tests for the NSURL (QSCanonicalPath) category (issue #3125)
//

#import <XCTest/XCTest.h>
#import "NSURL_BLTRExtensions.h"

@interface TestNSURLCanonicalPath : XCTestCase
@end

@implementation TestNSURLCanonicalPath

- (void)testRegularPathsAreUnchanged {
	for (NSString *path in @[@"/Applications", NSHomeDirectory(), @"/usr/bin/yes"]) {
		NSURL *url = [NSURL fileURLWithPath:path];
		XCTAssertEqualObjects([url URLByResolvingToUserVisiblePath].path, path);
		XCTAssertEqualObjects([url URLByMappingSystemApplicationsToLocalDomain].path, path);
	}
}

- (void)testNonexistentPathIsUnchanged {
	NSURL *url = [NSURL fileURLWithPath:@"/Applications/QSDoesNotExist.app"];
	XCTAssertEqualObjects([url URLByResolvingToUserVisiblePath], url);
}

- (void)testNonFileURLIsUnchanged {
	NSURL *url = [NSURL URLWithString:@"https://qsapp.com/"];
	XCTAssertEqualObjects([url URLByResolvingToUserVisiblePath], url);
	XCTAssertEqualObjects([url URLByMappingSystemApplicationsToLocalDomain], url);
}

- (void)testCryptexBackedAppResolvesToUserVisiblePath {
	// Safari ships in a cryptex; Launch Services and directory scans can
	// report it at the backing location instead of the /Applications symlink
	NSString *userVisiblePath = @"/Applications/Safari.app";
	NSFileManager *manager = [NSFileManager defaultManager];
	if (![manager fileExistsAtPath:userVisiblePath]
		|| ![manager fileExistsAtPath:@"/System/Cryptexes/App/System/Applications/Safari.app"]) {
		XCTSkip(@"Safari is not cryptex-backed on this system");
	}
	for (NSString *backingPath in @[@"/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app",
	                                @"/System/Cryptexes/App/System/Applications/Safari.app"]) {
		NSURL *resolved = [[NSURL fileURLWithPath:backingPath] URLByResolvingToUserVisiblePath];
		XCTAssertEqualObjects(resolved.path, userVisiblePath);
	}
}

- (void)testSystemApplicationWithoutLocalCounterpart {
	NSString *terminalPath = @"/System/Applications/Utilities/Terminal.app";
	if (![[NSFileManager defaultManager] fileExistsAtPath:terminalPath]) {
		XCTSkip(@"Terminal.app is not in /System/Applications on this system");
	}
	// The catalog mapping requires an existing file, so the real path is kept...
	XCTAssertEqualObjects([[NSURL fileURLWithPath:terminalPath] URLByResolvingToUserVisiblePath].path, terminalPath);
	// ...while the Finder-location mapping gives the /Applications location
	XCTAssertEqualObjects([[NSURL fileURLWithPath:terminalPath] URLByMappingSystemApplicationsToLocalDomain].path,
	                      @"/Applications/Utilities/Terminal.app");
	// Paths inside a bundle are never remapped
	NSString *interiorPath = [terminalPath stringByAppendingPathComponent:@"Contents/Info.plist"];
	XCTAssertEqualObjects([[NSURL fileURLWithPath:interiorPath] URLByMappingSystemApplicationsToLocalDomain].path, interiorPath);
}

@end
