//
//  TestQSObject.m
//  Quicksilver
//
//  Created by Rob McBroom on 2013/03/01.
//
//

#import "TestQSObject.h"
#import "QSTypes.h"
#import "QSDefines.h"
#import "QSObject.h"
#import "QSObject_StringHandling.h"
#import "QSObject_FileHandling.h"
#import "QSObject_URLHandling.h"
#import "QSObject_PropertyList.h"

@implementation TestQSObject

- (void)testStringObject
{
    NSString *exampleString = @"Example string in Quicksilver";
    QSObject *object = [QSObject objectWithString:exampleString];
    STAssertEqualObjects([object stringValue], exampleString, @"stringValue mismatch");
    STAssertEqualObjects([object objectForType:QSTextType], exampleString, @"QSTextType mismatch");
}

- (void)testURLObject
{
    NSArray *exampleURLs = @[@"qsapp.com", @"http://www.qsapp.com/"];
    for (NSString *url in exampleURLs) {
        QSObject *object = [QSObject URLObjectWithURL:url title:nil];
        STAssertTrue([object containsType:QSURLType] && [[object primaryType] isEqualToString:QSURLType], @"URL '%@' was not set up properly", url);
    }
    NSString *searchURL = [NSString stringWithFormat:@"http://www.qsapp.com/?q=%@&other_param=foo", QUERY_KEY];
    QSObject *object = [QSObject URLObjectWithURL:searchURL title:@"Web Search"];
    STAssertTrue([object containsType:QSSearchURLType] && [[object primaryType] isEqualToString:QSSearchURLType], @"URL '%@' was not recognized as a web search", searchURL);
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

- (void)testStringSniffing
{
    NSArray *shouldBeURL = @[@"localhost", @"localhost:1024", @"qsapp.com", @"http://qsapp.com/", @"http://hostname", @"http://qsapp.com:8080/path/"];
    for (NSString *url in shouldBeURL) {
        QSObject *object = [QSObject objectWithString:url];
        STAssertTrue([object containsType:QSURLType] && [[object primaryType] isEqualToString:QSURLType], @"'%@' was not recognized as a URL", url);
    }
    
    NSArray *shouldNotBeURL = @[@"com", @".com", @"ordinary text", @"localhost:", @"http://localhost:", @"host.invalid.topleveldomain", @"http://host.invalid.topleveldomain", @".co.uk", @"abcdefg\nhttp://qsapp.com/"];
    for (NSString *text in shouldNotBeURL) {
        QSObject *object = [QSObject objectWithString:text];
        STAssertTrue([[object primaryType] isEqualToString:QSTextType], @"'%@' was not recognized as plain text", text);
    }
    
    NSArray *shouldBeEmail = @[@"mailto:example@fake.tld", @"example@fake.tld"];
    for (NSString *mailto in shouldBeEmail) {
        QSObject *email = [QSObject objectWithString:mailto];
        STAssertTrue([[email primaryType] isEqualToString:QSEmailAddressType], @"'%@' was not recongnized as an e-mail address", mailto);
    }
    NSArray *shouldNotBeEmail = @[@"mailto:invalid address", @"example@fake.", @"invalid email@validdomain.com", @"mailto:@domain.com", @"mailto:helpme@.com"];
    for (NSString *mailto in shouldNotBeEmail) {
        QSObject *email = [QSObject objectWithString:mailto];
        STAssertTrue([[email primaryType] isEqualToString:QSTextType], @"'%@' should not be treated as an e-mail address", mailto);
    }
    
    NSString *calculation = @"=5*5";
    QSObject *object = [QSObject objectWithString:calculation];
    STAssertTrue([[object primaryType] isEqualToString:QSFormulaType], @"'%@' was not recognized as a caculation", calculation);
}

- (void)testObjectType
{
    NSDictionary *objectsAndTypes = @{
        @"QSUnitTestStringType": @"string",
        @"QSUnitTestDictionaryType": @{@"key": @"value"},
        @"QSUnitTestArraySingleValueType" : @[@"alone"],
        @"QSUnitTestArrayType": @[@"one", @"two", @"three"],
        @"QSUnitTestExoticType": [NSImage imageNamed:NSImageNameUser]
    };
    QSObject *object = [QSObject makeObjectWithIdentifier:@"QSUnitTest:objectType"];
    for (NSString *type in [objectsAndTypes allKeys]) {
        id originalObject = [objectsAndTypes objectForKey:type];
        [object setObject:originalObject forType:type];
        id storedObject = [object objectForType:type];
        if ([originalObject isKindOfClass:[NSArray class]] && [originalObject count] == 1) {
            STAssertEqualObjects([originalObject lastObject], storedObject, @"Stored arrays with a single object should return the single object as opposed to the array. (p_j_r doesn't know why");
        } else {
            STAssertEqualObjects(storedObject, originalObject, @"Stored object doesn't match original object. Class: '%@'", [originalObject class]);
        }
    }
}

- (void)testDisplayName
{
    NSString *name = @"Object Name";
    NSString *label = @"Object Label";
    QSObject *object = [QSObject makeObjectWithIdentifier:@"QSUnitTest:displayName"];
    [object setName:name];
    STAssertEqualObjects([object displayName], name, nil);
    [object setLabel:label];
    STAssertEqualObjects([object displayName], label, nil);
    [object setName:label];
    STAssertNil([object label], nil);
    STAssertEqualObjects([object displayName], label, nil);
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

- (void)testFileType
{
    NSString *path = @"/usr/bin/2to3";
    QSObject *object = [QSObject fileObjectWithPath:path];
    NSString *type = [object fileUTI];
    STAssertEqualObjects(type, @"public.python-script", nil);
    QSObject *ls = [QSObject fileObjectWithPath:@"/bin/ls"];
    STAssertTrue(UTTypeConformsTo((CFStringRef)[ls fileUTI], (CFStringRef)@"public.executable"), @"/bin/ls does not conform to public.executable");
}

- (void)testCombinedObjects
{
    QSObject *one = [QSObject objectWithString:@"one"];
    QSObject *two = [QSObject objectWithString:@"two"];
    QSObject *combined = [QSObject objectByMergingObjects:@[one, two]];
    STAssertEquals([combined count], (NSUInteger)2, nil);
    NSSet *originals = [NSSet setWithObjects:one, two, nil];
    NSSet *split = [NSSet setWithArray:[combined splitObjects]];
    STAssertEqualObjects(originals, split, nil);
    NSSet *originalStrings = [NSSet setWithObjects:@"one", @"two", nil];
    NSSet *stringValues = [NSSet setWithArray:[combined arrayForType:QSTextType]];
    STAssertEqualObjects(originalStrings, stringValues, nil);
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

@end
