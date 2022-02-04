//
//  TestQSObject.m
//  Quicksilver
//
//  Created by Rob McBroom on 2013/03/01.
//
//

#import "QSTypes.h"
#import "QSDefines.h"
#import "QSObject.h"
#import "QSObject_StringHandling.h"
#import "QSObject_FileHandling.h"
#import "QSObject_URLHandling.h"
#import "QSObject_PropertyList.h"

#import <XCTest/XCTest.h>

@interface TestQSObject : XCTestCase

@end


@implementation TestQSObject

- (void)testStringObject
{
    NSString *exampleString = @"Example string in Quicksilver";
    QSObject *object = [QSObject objectWithString:exampleString];
    XCTAssertEqualObjects([object stringValue], exampleString, @"stringValue mismatch");
    XCTAssertEqualObjects([object objectForType:QSTextType], exampleString, @"QSTextType mismatch");
}

- (void)testMultilineStringObject {

	NSString *multiline = @"line1\nline2";
	QSObject *object = [QSObject objectWithString:multiline];
	XCTAssertEqualObjects([object stringValue], multiline, @"multi line string values mismatch");
	XCTAssertEqualObjects([object objectForType:QSTextType], multiline, @"multiline QSTextType mismatch");

/*  These tests fail in a unit test environment, because QSReg is not loaded in unit tests and hence every object's handler is nil.
	This indicates some kind of refactoring needs to be done at some point in the future
*/
//	NSString *multilineFiles = @"~/\n~/Desktop";
//	object = [QSObject objectWithString:multilineFiles];
//	XCTAssertEqualObjects([object stringValue], multilineFiles, @"multi line file string values mismatch.");
//	XCTAssertEqualObjects([object objectForType:QSTextType], multilineFiles, @"multiline file QSTextType mismatch");
	
	NSString *mutlilineFakeFiles = @"~/ax03kjaj\n~/ak3p40kdj";
	object = [QSObject objectWithString:mutlilineFakeFiles];
	XCTAssertEqualObjects([object stringValue], mutlilineFakeFiles, @"multi line fake file string values mismatch");
	XCTAssertEqualObjects([object objectForType:QSTextType], mutlilineFakeFiles, @"multiline fake file QSTextType mismatch");
	
}

- (void)testURLObject
{
    NSArray *exampleURLs = @[@"qsapp.com", @"http://www.qsapp.com/"];
    for (NSString *url in exampleURLs) {
        QSObject *object = [QSObject URLObjectWithURL:url title:nil];
        XCTAssertTrue([object containsType:QSURLType] && [[object primaryType] isEqualToString:QSURLType], @"URL '%@' was not set up properly", url);
    }
    NSString *searchURL = [NSString stringWithFormat:@"http://www.qsapp.com/?q=%@&other_param=foo", QUERY_KEY];
    QSObject *object = [QSObject URLObjectWithURL:searchURL title:@"Web Search"];
    XCTAssertTrue([object containsType:QSSearchURLType] && [[object primaryType] isEqualToString:QSSearchURLType], @"URL '%@' was not recognized as a web search", searchURL);
}

- (void)testStringSniffing
{
    NSArray *shouldBeURL = @[
        @"localhost",
        @"localhost:1024",
        @"qsapp.com",
        @"http://qsapp.com/",
        @"http://hostname",
        @"http://qsapp.com:8080/path/",
        @"http://hostname.local/",
        @"qsapp/",
        @"qs-app/"
    ];
    for (NSString *url in shouldBeURL) {
        QSObject *object = [QSObject objectWithString:url];
        XCTAssertTrue([object containsType:QSURLType] && [[object primaryType] isEqualToString:QSURLType], @"'%@' was not recognized as a URL", url);
    }
    
    NSArray *shouldBeSearchURL = @[
        @"http://maps.google.com/maps?q=***",
        @"http://google.com:80/?searching=***",
        @"http://en.wikipedia.org/wiki/Special:Search?search=***",
        @"http://en.wikipedia.org:80/wiki/Special:Search?search=***",
        @"http://images.google.com/images?btnG=Search+Images&q=***"
    ];
    for (NSString *url in shouldBeSearchURL) {
        QSObject *object = [QSObject objectWithString:url];
        XCTAssertTrue([object containsType:QSSearchURLType] && [[object primaryType] isEqualToString:QSSearchURLType], @"'%@' was not recognized as a Search URL", url);
    }
    
    NSArray *shouldNotBeURL = @[
        @"com",
        @".com",
        @"ordinary text",
        @"localhost:",
        @"http://localhost:",
        @"host.invalid.topleveldomain",
        @"http://host.invalid.topleveldomain",
        @".co.uk",
        @"abcdefg\nhttp://qsapp.com/",
        @"http://qsapp.com:string:123",
        @"http://qsapp.com:2:colons",
        @"/qsapp/",
        @"qsapp//",
        @"qsapp-/",
        @"qsapp:80/"
    ];
    for (NSString *text in shouldNotBeURL) {
        QSObject *object = [QSObject objectWithString:text];
        XCTAssertTrue([[object primaryType] isEqualToString:QSTextType], @"'%@' was not recognized as plain text", text);
    }
    
    NSArray *shouldBeEmail = @[@"mailto:example@fake.tld", @"example@fake.tld"];
    for (NSString *mailto in shouldBeEmail) {
        QSObject *email = [QSObject objectWithString:mailto];
        XCTAssertTrue([[email primaryType] isEqualToString:QSEmailAddressType], @"'%@' was not recongnized as an e-mail address", mailto);
    }
    NSArray *shouldNotBeEmail = @[@"mailto:invalid address", @"example@fake.", @"invalid email@validdomain.com", @"mailto:@domain.com", @"mailto:helpme@.com"];
    for (NSString *mailto in shouldNotBeEmail) {
        QSObject *email = [QSObject objectWithString:mailto];
        XCTAssertTrue([[email primaryType] isEqualToString:QSTextType], @"'%@' should not be treated as an e-mail address", mailto);
    }
    
    NSString *calculation = @"=5*5";
    QSObject *object = [QSObject objectWithString:calculation];
    XCTAssertTrue([[object primaryType] isEqualToString:QSFormulaType], @"'%@' was not recognized as a caculation", calculation);
}

- (void)testObjectType
{
    NSDictionary *objectsAndTypes = @{
        @"QSUnitTestStringType": @"string",
        @"QSUnitTestDictionaryType": @{@"key": @"value"},
        @"QSUnitTestArraySingleValueType" : @[@"alone"],
        @"QSUnitTestArrayType": @[@"one", @"two", @"three"],
        @"QSUnitTestExoticType": [NSImage imageNamed:NSImageNameUser],
        @"QSUnitTestEmptyArrayType" : @[]
    };
    QSObject *object = [QSObject makeObjectWithIdentifier:@"QSUnitTest:objectType"];
    for (NSString *type in [objectsAndTypes allKeys]) {
        id originalObject = [objectsAndTypes objectForKey:type];
        [object setObject:originalObject forType:type];
        id storedObject = [object objectForType:type];
        if ([originalObject isKindOfClass:[NSArray class]]) {
            if ([(NSArray *)originalObject count] == 1) {
                XCTAssertEqualObjects([originalObject lastObject], storedObject, @"Stored arrays with a single object should return the single object as opposed to the array. arrayForType: is used when an array is required");
            } else if ([(NSArray *)originalObject count] > 1 || [(NSArray *)originalObject count] == 0) {
                XCTAssertEqualObjects(nil, storedObject, @"objectForType: should return nil when attempting to retrieve an array or empty array. arrayForType: should be used to retrieve the array instead");
            }
        } else {
            XCTAssertEqualObjects(storedObject, originalObject, @"Stored object doesn't match original object. Class: '%@'", [originalObject class]);
        }
    }
}

- (void)testDisplayName
{
    NSString *name = @"Object Name";
    NSString *label = @"Object Label";
    QSObject *object = [QSObject makeObjectWithIdentifier:@"QSUnitTest:displayName"];
    [object setName:name];
    XCTAssertEqualObjects([object displayName], name, @"");
    [object setLabel:label];
    XCTAssertEqualObjects([object displayName], label, @"");
    [object setName:label];
    XCTAssertNil([object label], @"");
    XCTAssertEqualObjects([object displayName], label, @"");
}


- (void)testCombinedObjects
{
    QSObject *one = [QSObject objectWithString:@"one"];
    QSObject *two = [QSObject objectWithString:@"two"];
    QSObject *combined = [QSObject objectByMergingObjects:@[one, two]];
    XCTAssertEqual([combined count], (NSUInteger)2, @"");
    NSSet *originals = [NSSet setWithObjects:one, two, nil];
    NSSet *split = [NSSet setWithArray:[combined splitObjects]];
    XCTAssertEqualObjects(originals, split, @"");
    NSSet *originalStrings = [NSSet setWithObjects:@"one", @"two", nil];
    NSSet *stringValues = [NSSet setWithArray:[combined arrayForType:QSTextType]];
    XCTAssertEqualObjects(originalStrings, stringValues, @"");
}

- (void)testCacheExpiration
{
    // requires #1218
//    NSString *cacheKey = @"temporaryData";
//    NSString *data = @"string";
//    QSObject *object = [QSObject makeObjectWithIdentifier:@"QSUnitTest:tempCache"];
//    [object setObject:data forCache:cacheKey forTimeInterval:0.5];
//    STAssertEqualObjects(data, [object objectForCache:cacheKey], nil);
//    sleep(1);
//    STAssertNil([object objectForCache:cacheKey], nil);
}

- (void)testEquality
{
	// tests for -[QSObject isEqual:]
	QSObject *one = [QSObject objectWithName:@"one"];
	QSObject *otherOne = one;
	QSObject *two = [QSObject objectWithName:@"two"];
	// literally the same object
	XCTAssertEqual(one, otherOne);
	XCTAssertEqualObjects(one, otherOne);
	// unequal objects
	XCTAssertNotEqual(one, two);
	// same data
	QSObject *data1 = [QSObject objectWithName:@"Data 1"];
	QSObject *data2 = [QSObject objectWithName:@"Data 2"];
	[data1 setObject:@"string data" forType:QSTextType];
	[data2 setObject:@"string data" forType:QSTextType];
	[data1 setPrimaryType:QSTextType];
	[data2 setPrimaryType:QSTextType];
	[data1 setObject:@"/System/Library" forType:QSFilePathType];
	[data2 setObject:@"/System/Library" forType:QSFilePathType];
	// make sure they aren't literally the same object
	// otherwise, the next test would be pointless
	XCTAssertNotEqual(data1, data2);
	XCTAssertEqualObjects(data1, data2);
	// mismatched data
	[data1 setObject:@"https://qsapp.com/" forType:QSURLType];
	[data2 setObject:@"https://qsapp.com/download.php" forType:QSURLType];
	XCTAssertNotEqualObjects(data1, data2);
	// combined objects
	NSArray *multipleObjects = @[data1, data2];
	QSObject *combined1 = [QSObject objectByMergingObjects:multipleObjects];
	QSObject *combined2 = [QSObject objectByMergingObjects:[multipleObjects copy]];
	// make sure they aren't literally the same object
	// otherwise, the next test would be pointless
	XCTAssertNotEqual(combined1, combined2);
	XCTAssertEqualObjects(combined1, combined2);
	QSObject *data3 = [QSObject URLObjectWithURL:@"https://qsapp.com/" title:@"QS"];
	QSObject *combined3 = [QSObject objectByMergingObjects:@[data1, data2, data3]];
	XCTAssertNotEqualObjects(combined1, combined3);
	QSObject *data4 = [QSObject URLObjectWithURL:@"https://apple.com/" title:@"Apple"];
	QSObject *combined4 = [QSObject objectByMergingObjects:@[data1, data2, data4]];
	XCTAssertNotEqualObjects(combined3, combined4);
	QSObject *combined5 = [QSObject objectByMergingObjects:@[data1, data2, data4] withObject:data2];
	XCTAssertEqualObjects(combined4, combined5);
	QSObject *combined6 = [QSObject objectByMergingObjects:@[data1, data2] withObject:data4];
	XCTAssertEqualObjects(combined4, combined6);
	// string objects
	QSObject *string1 = [QSObject objectWithString:@"a b c d e f"];
	QSObject *string2 = [QSObject objectWithString:@"a b c d e f"];
	QSObject *string3 = [QSObject objectWithString:@"f e d c b a"];
	XCTAssertEqualObjects(string1, string2);
	XCTAssertNotEqualObjects(string1, string3);
}

@end
