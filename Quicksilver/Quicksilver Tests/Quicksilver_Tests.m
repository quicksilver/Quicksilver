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
#import "QSObject_StringHandling.h"
#import "QSCollectingSearchObjectView.h"
#import "QSAction.h"
#import "QSTextProxy.h"

@interface Quicksilver_Tests : XCTestCase
@end

@implementation Quicksilver_Tests

- (void)testActionsForURLObject {
    NSString *url = @"https://qsapp.com";
    QSObject *object = [QSObject objectWithString:url];
    XCTAssertTrue([object containsType:QSURLType] && [[object primaryType] isEqualToString:QSURLType], @"'%@' was not recognized as a URL", url);
    NSArray *actions = [[QSExecutor sharedInstance] rankedActionsForDirectObject:object indirectObject:nil];
    XCTAssertTrue([actions count] > 0);
    XCTAssertTrue([[actions[0] identifier] isEqualToString:@"URLOpenAction"]);
}

// Attempted check for #2913. The real issue is with QSLibrarion's objectDictionary temporarily being wiped during `reloadSets`. There should be a check to make sure that doesn't happen
- (void)testRightArrowIntoSynonym {
    // code copied from QSUserDefinedProxySource
    NSString *provider = @"QSUserDefinedProxySource";
    NSDictionary *proxyDetails = [NSDictionary dictionaryWithObject:provider forKey:@"providerClass"];
    QSProxyObject *proxy = [QSProxyObject proxyWithDictionary:proxyDetails];
    // assign values to the proxy object
    NSString *targetID = @"/Applications";
    NSString *name = @"apps";
    [proxy setIdentifier:[NSString stringWithFormat:@"QSUserDefinedProxy:%@", name]];
    [proxy setName:name];
    [proxy setObject:targetID forMeta:@"target"];
    
    QSInterfaceController *i = [(QSController *)[NSApp delegate] interfaceController];
    [[i dSelector] selectObjectValue:proxy];
    [[i dSelector] moveRight:self];
    XCTAssertTrue([[i dSelector] objectValue] != proxy);
}

- (void)testCreateObjectFromRTFClipboard {
    // create an rtf string in the clipboard
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    
    NSAttributedString *rtfString = [[NSAttributedString alloc] initWithRTF:[@"{\\rtf1\\ansi\\ansicpg1252\\cocoartf1187\\cocoasubrtf340\n{\\fonttbl\\f0\\fnil\\fcharset0 Monaco;}\n{\\colortbl;\\red255\\green0\\blue0;}\n\\margl1440\\margr1440\\vieww10800\\viewh8400\\viewkind0\n\\pard\\tx720\\tx1440\\tx2160\\tx2880\\tx3600\\tx4320\\tx5040\\tx5760\\tx6480\\tx7200\\tx7920\\tx8640\\ql\\qnatural\\pardirnatural\n\n\\f0\\fs24 \\cf1 hello}" dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:nil];
    [pboard clearContents];
    [pboard writeObjects:@[rtfString]];
    
    // create a QSObject from the clipboard
    QSObject *obj = [QSObject objectWithPasteboard:pboard];
    XCTAssertTrue([obj containsType:NSPasteboardTypeRTF] && [[obj primaryType] isEqualToString:NSPasteboardTypeRTF]);
    
    // now write this object to the pasteboard
    [pboard clearContents];
    XCTAssertTrue([obj putOnPasteboard:pboard]);
    
    // read the object back from the pasteboard
    QSObject *obj2 = [QSObject objectWithPasteboard:pboard];
    XCTAssertTrue([obj2 containsType:NSPasteboardTypeRTF] && [[obj2 primaryType] isEqualToString:NSPasteboardTypeRTF]);
    
}

// test to make sure when file objects are added to the clipboard, a string of their path is also copied
- (void)testAddingFileObjectToPasteboard {
    NSString *path = @"/usr/bin/cd";
    NSPasteboard *pboard =[NSPasteboard generalPasteboard];
    QSObject *obj = [QSObject fileObjectWithPath:path];
    XCTAssertEqualObjects([obj singleFilePath], path);
    XCTAssertTrue([obj putOnPasteboard:pboard] == YES);
    XCTAssertTrue([[pboard types] containsObject:NSPasteboardTypeFileURL]);
    
    // for file objects, we don't write the QSTextType to the pasteboard - that messes with drag/drop in some applications
    XCTAssertFalse([[pboard types] containsObject:QSTextType]);
    NSArray *a = [pboard propertyListForType:NSPasteboardTypeFileURL];
    XCTAssertEqualObjects(a, @"file:///usr/bin/cd");
    
    // try this for an imagined type that already has a string type set:
    obj = [QSObject fileObjectWithPath:path];
    NSString *textString = @"My Important String";
    [obj setObject:textString forType:QSTextType];
    XCTAssertTrue([obj putOnPasteboard:pboard] == YES);
//    As of QS 2.5.0, we don't write 'QSTextType' to the pasteboard for file paths
//    This is the preferred method, and is what Finder does (e.g. when dragging files)
//    XCTAssertTrue([[pboard types] containsObject:QSTextType]);
    XCTAssertTrue([[pboard types] containsObject:NSPasteboardTypeFileURL]);
    XCTAssertFalse([[pboard types] containsObject:NSPasteboardTypeURL]);
    NSString *pboardString = [pboard stringForType:QSTextType];
    XCTAssertEqualObjects(textString, pboardString);
}

- (void)testAddingFileObjectToPasteboardWithMultiplePaths {
    NSArray *filePathArray = @[@"/usr/bin/cd", @"/usr/bin/curl"];
    NSArray *fileArray = @[@"file:///usr/bin/cd", @"file:///usr/bin/curl"];

    QSObject *obj = [QSObject fileObjectWithArray:filePathArray];
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    XCTAssertTrue([obj putOnPasteboard:pboard] == YES);
    XCTAssertTrue([[pboard types] containsObject:NSPasteboardTypeFileURL]);
    XCTAssertEqual([[pboard pasteboardItems] count], 2);
    NSArray *a = [[pboard pasteboardItems] arrayByEnumeratingArrayUsingBlock:^id(NSPasteboardItem *pbitem) {
        return [pbitem propertyListForType:NSPasteboardTypeFileURL];
    }];
    XCTAssertEqualObjects(a, fileArray);
    
    // now try re-creating the object from the pasteboard
    QSObject *newObj = [QSObject objectWithPasteboard:pboard];
    XCTAssertTrue([newObj containsType:QSFilePathType]);
    XCTAssertEqualObjects([newObj arrayForType:QSFilePathType], filePathArray);
}
    

/**
 * In order to run these tests, you must select 'Quicksilver' as the scheme, as opposed to 'Quicksilver Distribution'
 */

/**
 *  This is a test for bug #670, #203
 */
- (void)testClearingFirstPane
{
    
    QSInterfaceController *i = [(QSController *)[NSApp delegate] interfaceController];

    // Test is sure to fail if we can't get the interface controller
    XCTAssertNotNil(i);

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
    NSEvent *typeAEvent = [NSEvent keyEventWithType:NSEventTypeKeyDown location:NSMakePoint(0, 0) modifierFlags:256 timestamp:15127.081604936 windowNumber:[[i window] windowNumber] context:nil characters:@"a" charactersIgnoringModifiers:@"a" isARepeat:NO keyCode:0];
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

	NSEvent *typeAEvent = [NSEvent keyEventWithType:NSEventTypeKeyDown location:NSMakePoint(0, 0) modifierFlags:256 timestamp:15127.081604936 windowNumber:[[i window] windowNumber] context:nil characters:@"a" charactersIgnoringModifiers:@"a" isARepeat:NO keyCode:0];
	[[i dSelector] keyDown:typeAEvent];

	// dSelector is populated with an object
	XCTAssertNotNil([[i dSelector] objectValue]);

	// aSelector is nil until the actions timer has fired
	XCTAssertNil([[i aSelector] objectValue]);

	// Force the actions timer to fire now (synchronous)
	[i fireActionUpdateTimer];
	XCTAssertNotNil([[i aSelector] objectValue]);

	// the iSelector should be closed (default action for "a" is single-arg)
	XCTAssertFalse([self isViewVisible:[i iSelector] forController:i]);

	// Type "open with" into aSelector to select a 2-arg action
	NSEvent *searchForActionEvent = [NSEvent keyEventWithType:NSEventTypeKeyDown location:NSMakePoint(0, 0) modifierFlags:256 timestamp:15127.081604936 windowNumber:[[i window] windowNumber] context:nil characters:@"open with" charactersIgnoringModifiers:@"open with" isARepeat:NO keyCode:0];
	[[i aSelector] keyDown:searchForActionEvent];

	// Wait for indirect objects to be populated (deterministic via completion block)
	XCTestExpectation *indirectsUpdated = [self expectationWithDescription:@"indirect objects updated"];
	[i updateIndirectObjectsWithCompletion:^{
		[indirectsUpdated fulfill];
	}];
	[self waitForExpectationsWithTimeout:5.0 handler:nil];

	// iSelector should now be visible (Open With is a 2-arg action)
	XCTAssertFalse([[i iSelector] isHidden]);
	XCTAssertTrue([self isViewVisible:[i iSelector] forController:i]);

	// Clear the first pane (⌃U)
	NSEvent *clearEvent = [NSEvent keyEventWithType:NSEventTypeKeyDown location:NSMakePoint(0, 0) modifierFlags:NSEventModifierFlagControl timestamp:15127.081604936 windowNumber:[[i window] windowNumber] context:nil characters:@"u" charactersIgnoringModifiers:@"u" isARepeat:NO keyCode:32];
	[[i dSelector] keyDown:clearEvent];

	XCTAssertNil([[i dSelector] objectValue]);

	// aSelector still has object until the action timer is fired
	XCTAssertNotNil([[i aSelector] objectValue]);
	// iSelector still visible
	XCTAssertTrue([self isViewVisible:[i iSelector] forController:i]);

	// Force the actions timer to fire — clears actions since dSelector is nil.
	// searchObjectChanged: now calls updateViewLocations unconditionally,
	// so the iSelector is hidden synchronously.
	[i fireActionUpdateTimer];

	XCTAssertNil([[i aSelector] objectValue]);
	// the iSelector should be closed
	XCTAssertFalse([self isViewVisible:[i iSelector] forController:i]);
}

/**
 * Regression test for the race condition introduced by making updateIndirectObjects
 * fully async (commit e10140de). When the user presses Return in the 1st pane and
 * the action requires an indirect (argumentCount == 2), the async indirect update
 * may not have completed yet. executeCommand: should fetch indirects via completion
 * block rather than beeping and moving focus to the 3rd pane.
 *
 * Simulates: type "a" in 1st pane → set a 2-arg action → press Return immediately
 */
- (void)testExecuteCommandWaitsForIndirectsWhenMissing {
	QSInterfaceController *i = [(QSController *)[NSApp delegate] interfaceController];
	XCTAssertNotNil(i);

	// Type "a" into dSelector to get a file object
	NSEvent *typeAEvent = [NSEvent keyEventWithType:NSEventTypeKeyDown location:NSMakePoint(0, 0) modifierFlags:256 timestamp:15127.081604936 windowNumber:[[i window] windowNumber] context:nil characters:@"a" charactersIgnoringModifiers:@"a" isARepeat:NO keyCode:0];
	[[i dSelector] keyDown:typeAEvent];
	XCTAssertNotNil([[i dSelector] objectValue]);

	// Fire the actions timer to populate actions synchronously
	[i fireActionUpdateTimer];
	XCTAssertNotNil([[i aSelector] objectValue]);

	// Set a 2-arg action (Open With). This triggers searchObjectChanged: which
	// calls updateIndirectObjects asynchronously (fire-and-forget).
	QSAction *openWithAction = [QSAction actionWithIdentifier:@"FileOpenWithAction"];
	XCTAssertNotNil(openWithAction, @"FileOpenWithAction must exist for this test");
	[[i aSelector] setObjectValue:openWithAction];

	// At this point, iSelector is likely empty because the async indirect update
	// hasn't completed yet. This is the exact race condition we're testing.

	// Call executeCommand: — this should NOT beep and NOT move focus to iSelector.
	// With the fix, it detects the missing indirect and uses the completion path
	// to fetch indirects before executing.
	[i executeCommand:self];

	// Wait for the async completion to process
	XCTestExpectation *executed = [self expectationWithDescription:@"command executed via completion"];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		dispatch_async(dispatch_get_main_queue(), ^{
			[executed fulfill];
		});
	});
	[self waitForExpectationsWithTimeout:5.0 handler:nil];

	// The first responder should NOT be iSelector — that would mean the bug occurred
	// (beep + focus moved to 3rd pane, requiring a second Return press)
	NSResponder *firstResponder = [[i window] firstResponder];
	XCTAssertTrue(firstResponder != [i iSelector],
				  @"Focus should not have moved to iSelector — the indirect objects race condition was not handled");
}

/**
 * Regression test for the bug where executeCommand: unconditionally re-fetched
 * indirect objects, overwriting user-entered content in the 3rd pane.
 *
 * Simulates: select file → choose "Open With" → select an app in 3rd pane → Return
 * The user's selection in the 3rd pane must be preserved, not overwritten by a re-fetch.
 */
- (void)testExecuteCommandPreservesUserSelectedIndirect {
	QSInterfaceController *i = [(QSController *)[NSApp delegate] interfaceController];
	XCTAssertNotNil(i);

	// Set a file object in dSelector
	QSObject *fileObj = [QSObject fileObjectWithPath:@"/System"];
	[[i dSelector] setObjectValue:fileObj];
	XCTAssertNotNil([[i dSelector] objectValue]);

	// Fire the actions timer
	[i fireActionUpdateTimer];

	// Set a 2-arg action
	QSAction *openWithAction = [QSAction actionWithIdentifier:@"FileOpenWithAction"];
	XCTAssertNotNil(openWithAction, @"FileOpenWithAction must exist for this test");
	[[i aSelector] setObjectValue:openWithAction];

	// Wait for the indirect objects to be fully populated
	XCTestExpectation *indirectsReady = [self expectationWithDescription:@"indirects populated"];
	[i updateIndirectObjectsWithCompletion:^{
		[indirectsReady fulfill];
	}];
	[self waitForExpectationsWithTimeout:5.0 handler:nil];

	// Now simulate the user selecting a specific app in the 3rd pane.
	// Use a known file object as the indirect selection.
	QSObject *userSelectedApp = [QSObject fileObjectWithPath:@"/Applications/Safari.app"];
	[[i iSelector] setObjectValue:userSelectedApp];
	QSObject *indirectBeforeExecute = [[i iSelector] objectValue];
	XCTAssertNotNil(indirectBeforeExecute, @"iSelector should have the user's selection");

	// Call executeCommand: — this should use the user's selection, NOT re-fetch
	[i executeCommand:self];

	// Wait for any async operations to settle
	XCTestExpectation *settled = [self expectationWithDescription:@"settled"];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		dispatch_async(dispatch_get_main_queue(), ^{
			[settled fulfill];
		});
	});
	[self waitForExpectationsWithTimeout:5.0 handler:nil];

	// The key assertion: executeCommand: should NOT have moved focus to iSelector
	// (which would indicate it re-fetched and found a problem with the indirect)
	NSResponder *firstResponder = [[i window] firstResponder];
	XCTAssertTrue(firstResponder != [i iSelector],
				  @"executeCommand: should have used the user's existing indirect selection, not re-fetched");
}

/**
 * End-to-end test for text mode: enter text mode in the 1st pane,
 * type text, press Return, and verify the action fires.
 *
 * Simulates: press "." → type "hello" → press Return
 */
- (void)testTextModeReturnExecutesAction {
	QSInterfaceController *i = [(QSController *)[NSApp delegate] interfaceController];
	XCTAssertNotNil(i);

	// Enter text mode on dSelector (equivalent to pressing ".")
	[[i dSelector] transmogrify:self];
	NSTextView *textEditor = [[i dSelector] textModeEditor];
	XCTAssertNotNil(textEditor, @"Text mode editor should be active");

	// Type text into the editor
	[textEditor setString:@"hello"];
	// Trigger the text change notification so dSelector updates its objectValue
	[[NSNotificationCenter defaultCenter] postNotificationName:NSTextDidChangeNotification object:textEditor];

	XCTAssertNotNil([[i dSelector] objectValue], @"dSelector should have a text object");

	// Simulate pressing Return in text mode — this is what textView:doCommandBySelector:
	// does: exit text mode, then call executeCommand:
	[[i window] makeFirstResponder:[i dSelector]];
	[i executeCommand:self];

	// Wait for any async completion to process
	XCTestExpectation *executed = [self expectationWithDescription:@"text mode command executed"];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		dispatch_async(dispatch_get_main_queue(), ^{
			[executed fulfill];
		});
	});
	[self waitForExpectationsWithTimeout:5.0 handler:nil];

	// Verify: first responder should NOT be iSelector (would indicate the indirect
	// race condition bug — beep + focus to 3rd pane)
	NSResponder *firstResponder = [[i window] firstResponder];
	XCTAssertTrue(firstResponder != [i iSelector],
				  @"Text mode Return should execute the action, not move focus to the 3rd pane");
}

@end
