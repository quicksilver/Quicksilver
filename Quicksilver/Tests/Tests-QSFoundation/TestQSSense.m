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

const float ACC = 0.00001;

- (void)testScoreSimple {
	CFStringRef str  = CFSTR("Test string");
	CGFloat score = 0;

	score = QSScoreForAbbreviation(str, CFSTR("t"), nil);
	XCTAssertEqualWithAccuracy(score, 0.90909, ACC);

	score = QSScoreForAbbreviation(str, CFSTR("ts"), nil);
	XCTAssertEqualWithAccuracy(score, 0.92727, ACC);

	score = QSScoreForAbbreviation(str, CFSTR("te"), nil);
	XCTAssertEqualWithAccuracy(score, 0.91818, ACC);

	score = QSScoreForAbbreviation(str, CFSTR("tet"), nil);
	XCTAssertEqualWithAccuracy(score, 0.93636, ACC);

	score = QSScoreForAbbreviation(str, CFSTR("str"), nil);
	XCTAssertEqualWithAccuracy(score, 0.91818, ACC);

	score = QSScoreForAbbreviation(str, CFSTR("tstr"), nil);
	XCTAssertEqualWithAccuracy(score, 0.79090, ACC);

	score = QSScoreForAbbreviation(str, CFSTR("ng"), nil);
	XCTAssertEqualWithAccuracy(score, 0.63636, ACC);
}

- (void)testScoreSimpleNS {
	NSString *str = @"Test string";
	CGFloat score = 0;

	score =	[str scoreForAbbreviation:@"t"];
	XCTAssertEqualWithAccuracy(score, 0.90909, ACC);

	score = [str scoreForAbbreviation:@"ts"];
	XCTAssertEqualWithAccuracy(score, 0.83636, ACC);

	score = [str scoreForAbbreviation:@"te"];
	XCTAssertEqualWithAccuracy(score, 0.91818, ACC);

	score = [str scoreForAbbreviation:@"tet"];
	XCTAssertEqualWithAccuracy(score, 0.84545, ACC);

	score = [str scoreForAbbreviation:@"str"];
	XCTAssertEqualWithAccuracy(score, 0.91818, ACC);

	score = [str scoreForAbbreviation:@"tstr"];
	XCTAssertEqualWithAccuracy(score, 0.93181, ACC);

	score = [str scoreForAbbreviation:@"ng"];
	XCTAssertEqualWithAccuracy(score, 0.18181, ACC);
}

- (void)testScoreLongString {
	CFStringRef str = CFSTR("This is a really long test string for testing");
	CGFloat score = 0;

	score = QSScoreForAbbreviation(str, CFSTR("t"), nil);
	XCTAssertEqualWithAccuracy(score, 0.90222, ACC);

	score = QSScoreForAbbreviation(str, CFSTR("ts"), nil);
	XCTAssertEqualWithAccuracy(score, 0.88666, ACC);

	score = QSScoreForAbbreviation(str, CFSTR("te"), nil);
	XCTAssertEqualWithAccuracy(score, 0.80777, ACC);

	score = QSScoreForAbbreviation(str, CFSTR("tet"), nil);
	XCTAssertEqualWithAccuracy(score, 0.81222, ACC);

	score = QSScoreForAbbreviation(str, CFSTR("str"), nil);
	XCTAssertEqualWithAccuracy(score, 0.78555, ACC);

	score = QSScoreForAbbreviation(str, CFSTR("tstr"), nil);
	XCTAssertEqualWithAccuracy(score, 0.67777, ACC);

	score = QSScoreForAbbreviation(str, CFSTR("testi"), nil);
	XCTAssertEqualWithAccuracy(score, 0.74000, ACC);

	score = QSScoreForAbbreviation(str, CFSTR("for"), nil);
	XCTAssertEqualWithAccuracy(score, 0.75888, ACC);

	score = QSScoreForAbbreviation(str, CFSTR("ng"), nil);
	XCTAssertEqualWithAccuracy(score, 0.74666, ACC);
}

- (void)testScoreLongStringNS {
	NSString *str = @"This is a really long test string for testing";
	CGFloat score = 0;

	score = [str scoreForAbbreviation:@"t"];
	XCTAssertEqualWithAccuracy(score, 0.90222, ACC);

	score = [str scoreForAbbreviation:@"ts"];
	XCTAssertEqualWithAccuracy(score, 0.86444, ACC);

	score = [str scoreForAbbreviation:@"te"];
	XCTAssertEqualWithAccuracy(score, 0.80777, ACC);

	score = [str scoreForAbbreviation:@"tet"];
	XCTAssertEqualWithAccuracy(score, 0.79000, ACC);

	score = [str scoreForAbbreviation:@"str"];
	XCTAssertEqualWithAccuracy(score, 0.78555, ACC);

	score = [str scoreForAbbreviation:@"tstr"];
	XCTAssertEqualWithAccuracy(score, 0.78888, ACC);

	score = [str scoreForAbbreviation:@"testi"];
	XCTAssertEqualWithAccuracy(score, 0.74000, ACC);

	score = [str scoreForAbbreviation:@"for"];
	XCTAssertEqualWithAccuracy(score, 0.75888, ACC);

	score = [str scoreForAbbreviation:@"ng"];
	XCTAssertEqualWithAccuracy(score, 0.52444, ACC);
}

- (void)testLongString {
	CFStringRef str = CFSTR("This excellent string tells us an interesting story");
	CFRange strRange = CFRangeMake(0, 27); // tells^
	CFStringRef abbr = CFSTR("test");
	CFRange abbrRange = CFRangeMake(0, CFStringGetLength(abbr));
	CGFloat score = 0;
	const int STEP = 4;
	NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
	NSIndexSet *results = nil;

	score = QSScoreForAbbreviationWithRanges(str, CFSTR("test"), indexes, strRange, abbrRange);
	XCTAssertEqualWithAccuracy(score, 0.74074, ACC);
	results = [NSIndexSet indexSetFromArray:@[@(0), @(5), @(15), @(16), @(22), @(23)]];
	XCTAssertEqualObjects(indexes, results);

	strRange.length += STEP;
	score = QSScoreForAbbreviationWithRanges(str, CFSTR("test"), indexes, strRange, abbrRange);
	XCTAssertEqualWithAccuracy(score, 0.76129, ACC);
	results = [NSIndexSet indexSetFromArray:@[@(0), @(5), @(15), @(16), @(22), @(23), @(26)]];
	XCTAssertEqualObjects(indexes, results);

	strRange.length += STEP;
	score = QSScoreForAbbreviationWithRanges(str, CFSTR("test"), indexes, strRange, abbrRange);
	XCTAssertEqualWithAccuracy(score, 0.77714, ACC);
	results = [NSIndexSet indexSetFromArray:@[@(0), @(5), @(15), @(16), @(22), @(23), @(26)]];
	XCTAssertEqualObjects(indexes, results);

	strRange.length += STEP;
	score = QSScoreForAbbreviationWithRanges(str, CFSTR("test"), indexes, strRange, abbrRange);
	XCTAssertEqualWithAccuracy(score, 0.74230, ACC);
	results = [NSIndexSet indexSetFromArray:@[@(0), @(5), @(15), @(16), @(22), @(23), @(26), @(36)]];
	XCTAssertEqualObjects(indexes, results);

	strRange.length += STEP;
	score = QSScoreForAbbreviationWithRanges(str, CFSTR("test"), indexes, strRange, abbrRange);
	XCTAssertEqualWithAccuracy(score, 0.69883, ACC);
	results = [NSIndexSet indexSetFromArray:@[@(0), @(5), @(15), @(16), @(22), @(23), @(26), @(36), @(40), @(41)]];
	XCTAssertEqualObjects(indexes, results);

	strRange.length += STEP;
	score = QSScoreForAbbreviationWithRanges(str, CFSTR("test"), indexes, strRange, abbrRange);
	XCTAssertEqualWithAccuracy(score, 0.71595, ACC);
	results = [NSIndexSet indexSetFromArray:@[@(0), @(5), @(15), @(16), @(22), @(23), @(26), @(36), @(40), @(41)]];
	XCTAssertEqualObjects(indexes, results);

	strRange.length += STEP;
	score = QSScoreForAbbreviationWithRanges(str, CFSTR("test"), indexes, strRange, abbrRange);
	XCTAssertEqualWithAccuracy(score, 0.73039, ACC);
	results = [NSIndexSet indexSetFromArray:@[@(0), @(5), @(15), @(16), @(22), @(23), @(26), @(36), @(40), @(41)]];
	XCTAssertEqualObjects(indexes, results);
}

- (void)testLongStringNS {
	NSString *str = @"This excellent string tells us an interesting story";
	NSRange strRange = NSMakeRange(0, 27); // tells^
	NSString *abbr = @"test";
	NSRange abbrRange = NSMakeRange(0, [abbr length]);
	CGFloat score = 0;
	const int STEP = 4;
	NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
	NSIndexSet *results = nil;

	score = [str scoreForAbbreviation:abbr inRange:strRange fromRange:abbrRange hitMask:indexes];
	XCTAssertEqualWithAccuracy(score, 0.90185, ACC);
	results = [NSIndexSet indexSetFromArray:@[@(0), @(5), @(15), @(16), @(22), @(23)]];
	XCTAssertEqualObjects(indexes, results);

	strRange.length += STEP;
	score = [str scoreForAbbreviation:abbr inRange:strRange fromRange:abbrRange hitMask:indexes];
	XCTAssertEqualWithAccuracy(score, 0.90161, ACC);
	results = [NSIndexSet indexSetFromArray:@[@(0), @(5), @(15), @(16), @(22), @(23), @(26)]];
	XCTAssertEqualObjects(indexes, results);

	strRange.length += STEP;
	score = [str scoreForAbbreviation:abbr inRange:strRange fromRange:abbrRange hitMask:indexes];
	XCTAssertEqualWithAccuracy(score, 0.90142, ACC);
	results = [NSIndexSet indexSetFromArray:@[@(0), @(5), @(15), @(16), @(22), @(23), @(26)]];
	XCTAssertEqualObjects(indexes, results);

	strRange.length += STEP;
	score = [str scoreForAbbreviation:abbr inRange:strRange fromRange:abbrRange hitMask:indexes];
	XCTAssertEqualWithAccuracy(score, 0.58846, ACC);
	results = [NSIndexSet indexSetFromArray:@[@(0), @(5), @(15), @(16), @(22), @(23), @(26), @(36)]];
	XCTAssertEqualObjects(indexes, results);

	strRange.length += STEP;
	score = [str scoreForAbbreviation:abbr inRange:strRange fromRange:abbrRange hitMask:indexes];
	XCTAssertEqualWithAccuracy(score, 0.51279, ACC);
	results = [NSIndexSet indexSetFromArray:@[@(0), @(5), @(15), @(16), @(22), @(23), @(26), @(36), @(40), @(41)]];
	XCTAssertEqualObjects(indexes, results);

	strRange.length += STEP;
	score = [str scoreForAbbreviation:abbr inRange:strRange fromRange:abbrRange hitMask:indexes];
	XCTAssertEqualWithAccuracy(score, 0.54574, ACC);
	results = [NSIndexSet indexSetFromArray:@[@(0), @(5), @(15), @(16), @(22), @(23), @(26), @(36), @(40), @(41)]];
	XCTAssertEqualObjects(indexes, results);

	strRange.length += STEP;
	score = [str scoreForAbbreviation:abbr inRange:strRange fromRange:abbrRange hitMask:indexes];
	XCTAssertEqualWithAccuracy(score, 0.57352, ACC);
	results = [NSIndexSet indexSetFromArray:@[@(0), @(5), @(15), @(16), @(22), @(23), @(26), @(36), @(40), @(41)]];
	XCTAssertEqualObjects(indexes, results);
}

- (void)testPerformanceNS {
	[self measureBlock:^{
		[@"Test string" scoreForAbbreviation:@"tsg"];
	}];
}
- (void)testPerformanceCF {
    [self measureBlock:^{
		CFStringRef str  = CFSTR("Test string");
		CFStringRef abbr = CFSTR("tsg");

		QSScoreForAbbreviationWithRanges(str, abbr, nil,
										 CFRangeMake(0, CFStringGetLength(str)),
										 CFRangeMake(0, CFStringGetLength(abbr)));
	}];
}

- (void)testPerformanceCFMicro {
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
