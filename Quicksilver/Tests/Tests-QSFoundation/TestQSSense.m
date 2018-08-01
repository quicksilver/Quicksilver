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
	results = [NSIndexSet indexSetFromArray:@[@(0), @(5), @(15), @(16), @(22), @(23)]];
	XCTAssertEqualObjects(indexes, results);

	strRange.length += STEP;
	score = QSScoreForAbbreviationWithRanges(str, abbr, indexes, strRange, abbrRange);
	XCTAssertEqualWithAccuracy(score, 0.901612, ACC);
	results = [NSIndexSet indexSetFromArray:@[@(0), @(5), @(15), @(16), @(22), @(23), @(26)]];
	XCTAssertEqualObjects(indexes, results);

	strRange.length += STEP;
	score = QSScoreForAbbreviationWithRanges(str, abbr, indexes, strRange, abbrRange);
	XCTAssertEqualWithAccuracy(score, 0.901428, ACC);
	results = [NSIndexSet indexSetFromArray:@[@(0), @(5), @(15), @(16), @(22), @(23), @(26)]];
	XCTAssertEqualObjects(indexes, results);

	strRange.length += STEP;
	score = QSScoreForAbbreviationWithRanges(str, abbr, indexes, strRange, abbrRange);
	XCTAssertEqualWithAccuracy(score, 0.72948, ACC);
	results = [NSIndexSet indexSetFromArray:@[@(0), @(5), @(15), @(16), @(22), @(23), @(26), @(36)]];
	XCTAssertEqualObjects(indexes, results);

	strRange.length += STEP;
	score = QSScoreForAbbreviationWithRanges(str, abbr, indexes, strRange, abbrRange);
	XCTAssertEqualWithAccuracy(score, 0.69883, ACC);
	results = [NSIndexSet indexSetFromArray:@[@(0), @(5), @(15), @(16), @(22), @(23), @(26), @(36), @(40), @(41)]];
	XCTAssertEqualObjects(indexes, results);

	strRange.length += STEP;
	score = QSScoreForAbbreviationWithRanges(str, abbr, indexes, strRange, abbrRange);
	XCTAssertEqualWithAccuracy(score, 0.71595, ACC);
	results = [NSIndexSet indexSetFromArray:@[@(0), @(5), @(15), @(16), @(22), @(23), @(26), @(36), @(40), @(41)]];
	XCTAssertEqualObjects(indexes, results);

	strRange.length += STEP;
	score = QSScoreForAbbreviationWithRanges(str, abbr, indexes, strRange, abbrRange);
	XCTAssertEqualWithAccuracy(score, 0.73039, ACC);
	results = [NSIndexSet indexSetFromArray:@[@(0), @(5), @(15), @(16), @(22), @(23), @(26), @(36), @(40), @(41)]];
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
