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

@interface Quicksilver_Tests : XCTestCase
@end

@implementation Quicksilver_Tests

/**
 * In order to run these tests, you must select 'Quicksilver' as the scheme, as opposed to 'Quicksilver Distribution'
 */

/**
 *  This is a test for bug #670, #203
 */
- (void)testClearingFirstPane
{
    
    QSInterfaceController *i = [(QSController *)[NSApp delegate] interfaceController];
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

    QSInterfaceController *i = [(QSController *)[NSApp delegate] interfaceController];
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

- (bool)isViewVisible:(QSSearchObjectView *)v forController:(QSInterfaceController *)i {
	return [[[[i window] contentView] subviews] containsObject:v];
}
/**
 * This is a test for #1468 and one that cropped up in #2249
 * This test is equivalent to you typing "a" ⇥ "open with", checking the iSelector is visible,
 * then typing ⌃U and checking the iSelector is closed
 */
- (void)testThirdPaneClosingBehaviour {
	QSInterfaceController *i = [(QSController *)[NSApp delegate] interfaceController];
	[i activate:nil];
	NSEvent *typeAEvent = [NSEvent keyEventWithType:10 location:NSMakePoint(0, 0) modifierFlags:256 timestamp:15127.081604936 windowNumber:[[i window] windowNumber] context:nil characters:@"a" charactersIgnoringModifiers:@"a" isARepeat:NO keyCode:0];
	[[i dSelector] keyDown:typeAEvent];
	
	// dSelector is populated with an object
	XCTAssertNotNil([[i dSelector] objectValue]);
	
	// aSelector is nil until the actions timer has fired
	XCTAssertNil([[i aSelector] objectValue]);

	// UI tests hack: force the actions timer to fire now
	[i fireActionUpdateTimer];
	XCTAssertNotNil([[i aSelector] objectValue]);
	
	// the iSelector should be closed
	XCTAssertFalse([self isViewVisible:[i iSelector] forController:i]);
	
	NSEvent *searchForActionEvent = [NSEvent keyEventWithType:10 location:NSMakePoint(0, 0) modifierFlags:256 timestamp:15127.081604936 windowNumber:[[i window] windowNumber] context:nil characters:@"open with" charactersIgnoringModifiers:@"open with" isARepeat:NO keyCode:0];
	[[i aSelector] keyDown:searchForActionEvent];
	XCTAssertFalse([[i iSelector] isHidden]);
	// iSelector should now be visible
	XCTAssertTrue([self isViewVisible:[i iSelector] forController:i]);
	
	// Clear the first pane (use ⌃U is easiest)
	NSEvent *clearEvent = [NSEvent keyEventWithType:10 location:NSMakePoint(0, 0) modifierFlags:NSEventModifierFlagControl timestamp:15127.081604936 windowNumber:[[i window] windowNumber] context:nil characters:@"u" charactersIgnoringModifiers:@"u" isARepeat:NO keyCode:32];
	[[i dSelector] keyDown:clearEvent];


	XCTAssertNil([[i dSelector] objectValue]);
	
	// aSelector still has object until the action timer is fired
	XCTAssertNotNil([[i aSelector] objectValue]);
	// iSeletor still visible
	XCTAssertTrue([self isViewVisible:[i iSelector] forController:i]);

	// UI tests hack: force the actions timer to fire now
	[i fireActionUpdateTimer];
	
	XCTAssertNil([[i aSelector] objectValue]);
	// the iSelector should be closed
	XCTAssertFalse([self isViewVisible:[i iSelector] forController:i]);
	
	
}

@end
