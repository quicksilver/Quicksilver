//
//  TestQSSense.m
//  Quicksilver
//
//  Created by Etienne on 15/04/2017.
//
//

#import <XCTest/XCTest.h>

@interface TestQSSense : XCTestCase

@end

@implementation TestQSSense

- (void)testScoreSimple {
	CFStringRef str  = CFSTR("Test string");
	CGFloat score = 0;
	CGFloat prev_score = 0;
	// each abbreviation should score higher than the one before
	NSArray *testAbbreviations = @[
		@"ng", @"ts", @"tet", @"t", @"str", @"te", @"tstr"
	];
	for (NSString *abbr in testAbbreviations) {
		score = QSScoreForAbbreviation(str, (__bridge CFStringRef)(abbr), nil);
		XCTAssertGreaterThanOrEqual(score, prev_score, @"score for %@ was not higher", abbr);
		prev_score = score;
	}
}

- (void)testScoreLongString {
	CFStringRef str = CFSTR("This is a really long test string for testing");
	CGFloat score = 0;
	CGFloat prev_score = 0;
	// each abbreviation should score higher than the one before
	NSArray *testAbbreviations = @[
		@"ng", @"testi", @"for", @"str", @"tstr", @"tet", @"te", @"ts", @"t"
	];
	for (NSString *abbr in testAbbreviations) {
		score = QSScoreForAbbreviation(str, (__bridge CFStringRef)(abbr), nil);
		NSLog(@"%@ %g", abbr, score);
		XCTAssertGreaterThanOrEqual(score, prev_score, @"score for %@ was not higher", abbr);
		prev_score = score;
	}
}

- (void)testLongString {
	CFStringRef str = CFSTR("This excellent string tells us an interesting story");
	CFRange strRange = CFRangeMake(0, 27); // tells^
	CFStringRef abbr = CFSTR("test");
	CFRange abbrRange = CFRangeMake(0, CFStringGetLength(abbr));
	CGFloat score = 0;
	const float ACC = 0.00001;
	const int STEP = 4;
	NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
	NSIndexSet *results = nil;

	score = QSScoreForAbbreviationWithRanges(str, abbr, indexes, strRange, abbrRange);
	XCTAssertEqualWithAccuracy(score, 0.901851, ACC);
	results = [NSIndexSet indexSetFromArray:@[@(0), @(5), @(15), @(16)]];
	XCTAssertEqualObjects(indexes, results);

	strRange.length += STEP;
	indexes = [[NSMutableIndexSet alloc] init];
	score = QSScoreForAbbreviationWithRanges(str, CFSTR("testing"), indexes, strRange, CFRangeMake(0, 7));
	XCTAssertEqualWithAccuracy(score, 0.89838, ACC);
	results = [NSIndexSet indexSetFromArray:@[@(0), @(5), @(15), @(16), @(18), @(19), @(20)]];
	XCTAssertEqualObjects(indexes, results);

	strRange.length += STEP;
	indexes = [[NSMutableIndexSet alloc] init];
	score = QSScoreForAbbreviationWithRanges(str, CFSTR("telling"), indexes, strRange, CFRangeMake(0, 7));
	XCTAssertEqualWithAccuracy(score, 0.76, ACC);
	results = [NSIndexSet indexSetFromArray:@[@(0), @(8), @(9), @(10), @(18), @(19), @(20)]];
	XCTAssertEqualObjects(indexes, results);

	strRange.length = 51;
	indexes = [[NSMutableIndexSet alloc] init];
	score = QSScoreForAbbreviationWithRanges(str, CFSTR("history"), indexes, strRange, CFRangeMake(0, 7));
	XCTAssertEqualWithAccuracy(score, 0.56862, ACC);
	results = [NSIndexSet indexSetFromArray:@[@(1), @(2), @(3), @(47), @(48), @(49), @(50)]];
	XCTAssertEqualObjects(indexes, results);
}

- (void)testPerformance {
    [self measureBlock:^{
		CFStringRef str  = CFSTR("Test string");
		CFStringRef abbr = CFSTR("tsg");

		QSScoreForAbbreviationWithRanges(str, abbr, nil,
										 CFRangeMake(0, CFStringGetLength(str)),
										 CFRangeMake(0, CFStringGetLength(abbr)));
	}];
}

- (void)testPerformanceMicro {
	[self measureBlock:^{
		CFStringRef str  = CFSTR("This is a really long test string for testing");
		CFStringRef abbr = CFSTR("tsg");

		for (int i = 0; i <= 100000; i++) {
			QSScoreForAbbreviationWithRanges(str, abbr, nil,
											 CFRangeMake(0, CFStringGetLength(str)),
											 CFRangeMake(0, CFStringGetLength(abbr)));
		}
	}];
}

@end
