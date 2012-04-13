//
//  TestPathWildcards.m
//  Quicksilver
//
//  Created by Henning Jungkurth on 21/2/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "NSString_BLTRExtensions.h"

@interface TestPathWildcards : SenTestCase {
	NSString *basePath;
}
@end

@implementation TestPathWildcards

-(void)setUp{
	basePath = [[NSBundle bundleForClass:[self class]] resourcePath];
}

-(void) testOneNonambiguousWildcard{
	NSString *unresolvedPath = [basePath stringByAppendingPathComponent:@"PathWildcardsData/*/testSubFolder1/testFile1.txt"];
	NSString *resolvedPath = [unresolvedPath stringByResolvingWildcardsInPath];
	NSString *correctPath = [basePath stringByAppendingPathComponent:@"PathWildcardsData/testFolder1/testSubFolder1/testFile1.txt"];
	
	STAssertTrue([resolvedPath isEqualToString:correctPath], @"Path not resolved correctly. Got %@ instead of %@", resolvedPath, correctPath);
}

-(void) testTwoNonambiguousWildcards{
	// documents issue #633
	NSString *unresolvedPath = [basePath stringByAppendingPathComponent:@"PathWildcardsData/*/*/testFile2.txt"];
	NSString *resolvedPath = [unresolvedPath stringByResolvingWildcardsInPath];
	NSString *correctPath = [basePath stringByAppendingPathComponent:@"PathWildcardsData/testFolder1/testSubFolder1/testFile2.txt"];
	
	STAssertTrue([resolvedPath isEqualToString:correctPath], @"Path not resolved correctly. Got %@ instead of %@", resolvedPath, correctPath);
}

-(void) testOneAmbiguousWildcard{
	// documents issue #633
	NSString *unresolvedPath = [basePath stringByAppendingPathComponent:@"PathWildcardsData/testFolder1/*/testFile1.txt"];
	NSString *resolvedPath = [unresolvedPath stringByResolvingWildcardsInPath];
	NSString *correctPath = [basePath stringByAppendingPathComponent:@"PathWildcardsData/testFolder1/testSubFolder1/testFile1.txt"];
	
	STAssertTrue([resolvedPath isEqualToString:correctPath], @"Path not resolved correctly. Got %@ instead of %@", resolvedPath, correctPath);
}

-(void) testNoWildcard{
	NSString *unresolvedPath = [basePath stringByAppendingPathComponent:@"PathWildcardsData"];
	NSString *resolvedPath = [unresolvedPath stringByResolvingWildcardsInPath];
	NSString *correctPath = [basePath stringByAppendingPathComponent:@"PathWildcardsData"];
	
	STAssertTrue([resolvedPath isEqualToString:correctPath], @"Path not resolved correctly. Got %@ instead of %@", resolvedPath, correctPath);
}

-(void) testStandardizingAndNoWildcard{
	NSString *unresolvedPath = @"~/Library";
	NSString *resolvedPath = [unresolvedPath stringByResolvingWildcardsInPath];
	NSString *correctPath = [@"~/Library" stringByStandardizingPath];
	
	STAssertTrue([resolvedPath isEqualToString:correctPath], @"Path not resolved correctly. Got %@ instead of %@", resolvedPath, correctPath);
}

-(void) testResolvedPathNotFound {
	// issue 814
	NSString *unresolvedPath = @"Contents/Resources/ExtraScripts/";
	NSString *resolvedPath = [unresolvedPath stringByResolvingWildcardsInPath];
	NSString *correctPath = unresolvedPath;

	STAssertTrue([resolvedPath isEqualToString:correctPath], @"Path not resolved correctly. Got %@ instead of %@", resolvedPath, correctPath);
}


@end
