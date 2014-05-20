//
//  Quicksilver_Tests.m
//  Quicksilver Tests
//
//  Created by Patrick Robertson on 20/05/2014.
//
//

#import <XCTest/XCTest.h>
#import "QSInterfaceController.h"
#import "QSController.h"
#import "QSObject.h"
#import "QSObject_FileHandling.h"
#import "QSCollectingSearchObjectView.h"

@interface Quicksilver_Tests : XCTestCase {
    BOOL finishedLaunching;
}
@end

@implementation Quicksilver_Tests

- (void)setUp
{
    finishedLaunching = NO;
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)didFinishLaunching:(NSNotification *)notif {
    finishedLaunching = YES;
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/**
 *  This is a test for bug #670, #203
 */
- (void)testClearingFirstPane
{
    // It seems QS hasn't finished launching at this point. Sleep for 5 secs to make sure everything is 'set up' properly (crude)
    sleep(5);
    
    QSInterfaceController *i = [[NSApp delegate] interfaceController];
    [i showMainWindow:self];
    // Assumes the current interface can collect
    QSCollectingSearchObjectView *dSelector = (QSCollectingSearchObjectView *)[i dSelector];
    
    // Make a couple of file objects and add them to the dSelector
    NSArray *paths = @[@"/System", @"/Users"];
    NSArray *objs = @[[QSObject fileObjectWithPath:paths[0]], [QSObject fileObjectWithPath:paths[1]]];
    for (QSObject *o in objs) {
        [dSelector setObjectValue:o];
        [dSelector collect:o];
    }
    
    // Ensure the collected objects are the same as those added
    XCTAssertEqualObjects([[dSelector objectValue] splitObjects], objs, @"Collected objects aren't correct");
    
    // Call some action on the objects (Get File URL known to be problematic
    QSAction *getFileURLAction = [QSAction actionWithIdentifier:@"FileGetURLAction"];
    [[i aSelector] setObjectValue:getFileURLAction];
    [i executeCommandThreaded];
    
    // Ensure the returned files are what we expected (for this action)
    NSString *fileURLs = [[NSURL performSelector:@selector(fileURLWithPath:) onObjectsInArray:paths returnValues:YES] componentsJoinedByString:@"\n"];
    QSObject *fileURLStringObject = [QSObject objectWithType:QSTextType value:fileURLs name:fileURLs];
    XCTAssertEqualObjects([[dSelector objectValue] stringValue], [fileURLStringObject stringValue], @"Returned object by getFileURLs: doesn't match what was expected. String values: dSelector:\n%@\n\nShould be:\n%@", [[dSelector objectValue] stringValue], [fileURLStringObject stringValue]);
}

/**
 *  This is a test for bug #1760
 */
- (void)testClearingSearchStringOnTrigger {
    QSInterfaceController *i = [[NSApp delegate] interfaceController];
    [i showMainWindow:self];
    NSEvent *typeAEvent = [NSEvent keyEventWithType:10 location:NSMakePoint(0, 0) modifierFlags:256 timestamp:15127.081604936 windowNumber:[[i window] windowNumber] context:nil characters:@"a" charactersIgnoringModifiers:@"a" isARepeat:NO keyCode:0];
    // Simulate typing 'a' into the dSelector
    [[i dSelector] keyDown:typeAEvent];
    
    XCTAssertEqualObjects(@"a", [[i dSelector] searchString], @"The search string typed into the dSelector is incorrect");
    
    // Simulate opening a trigger like iTunes' 'Search Artists' (a.k.a. a search children action)
    QSAction *searchChildrenAction = [QSAction actionWithIdentifier:@"QSObjectSearchChildrenAction"];
    [[i aSelector] setObjectValue:searchChildrenAction];
    [i executeCommandThreaded];
    
    [[i dSelector] keyDown:typeAEvent];
    
    XCTAssertEqualObjects(@"a", [[i dSelector] searchString], @"The previous search string was not cleared when invoking a 'search children' command");
}

@end
