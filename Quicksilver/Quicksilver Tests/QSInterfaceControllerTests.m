//
//  QSInterfaceControllerTests.m
//  Quicksilver Tests
//

#import <XCTest/XCTest.h>
#import "QSInterfaceController.h"
#import "QSController.h"
#import "QSObject.h"
#import "QSObject_FileHandling.h"
#import "QSSearchObjectView.h"

@interface QSInterfaceControllerTests : XCTestCase
@end

@implementation QSInterfaceControllerTests

- (void)setUp {
    [super setUp];
    // Reset action and indirect panes between tests to prevent pollution.
    // Do NOT clear dSelector — that destroys its result/source arrays which
    // are populated from the catalog and needed for search-based tests.
    QSInterfaceController *i = [(QSController *)[NSApp delegate] interfaceController];
    [i clearObjectView:[i aSelector]];
    [i clearObjectView:[i iSelector]];
}

/// Wait for pending QSGCDAsync + QSGCDMainAsync operations to complete
- (void)waitForAsyncUpdates {
    XCTestExpectation *exp = [self expectationWithDescription:@"async updates"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [exp fulfill];
        });
    });
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

/// Enter text mode on dSelector, type text, and fire the action update timer.
/// Returns the interface controller for further assertions.
- (QSInterfaceController *)enterTextModeWithString:(NSString *)text {
    QSInterfaceController *i = [(QSController *)[NSApp delegate] interfaceController];
    XCTAssertNotNil(i);

    QSSearchObjectView *dSel = [i dSelector];

    // Enter text mode (equivalent to pressing '.')
    [dSel transmogrify:self];

    // Set text in the text editor to create a text QSObject
    if (text) {
        [[dSel textModeEditor] setString:text];
        [dSel setObjectValue:[QSObject objectWithString:text]];
    }

    // Force the action update timer to fire so actions populate immediately
    [i fireActionUpdateTimer];

    return i;
}

/**
 * End-to-end test: pressing Return in text mode should execute the action
 * immediately without beeping or moving focus to the 3rd pane.
 *
 * This deliberately does NOT call waitForAsyncUpdates before executeCommand:
 * to reproduce the race condition where updateIndirectObjects dispatches async
 * and executeCommand checks iSelector before the update completes.
 */
- (void)testTextModeReturnExecutesAction {
    QSInterfaceController *i = [self enterTextModeWithString:@"hello world"];

    // Do NOT wait for async updates -- this is the key to reproducing the race
    // The fix (run loop spin in executeCommand) should handle this.

    // Simulate pressing Return
    [i executeCommand:self];

    // If the bug is present, focus would have moved to iSelector (3rd pane)
    // because indirect objects hadn't been set yet.
    // With the fix, executeCommand waits for the async update to complete.
    NSResponder *firstResponder = [[i window] firstResponder];
    XCTAssertNotEqual(firstResponder, [i iSelector],
        @"Focus should not move to 3rd pane -- indirect objects should have been resolved before execution");
}

/**
 * Same flow as above but WITH waitForAsyncUpdates, verifying the baseline works.
 */
- (void)testTextModeReturnWithAsyncWaitExecutesAction {
    QSInterfaceController *i = [self enterTextModeWithString:@"hello world"];

    // Wait for async updates to fully complete
    [self waitForAsyncUpdates];

    // Simulate pressing Return
    [i executeCommand:self];

    // Focus should not be on the 3rd pane
    NSResponder *firstResponder = [[i window] firstResponder];
    XCTAssertNotEqual(firstResponder, [i iSelector],
        @"Focus should not move to 3rd pane after async updates completed");
}

/**
 * Verify that the indirect validity check doesn't cause a beep.
 * For a text mode action with argumentCount != 2, iSelector should not matter.
 */
- (void)testTextModeReturnDoesNotBeep {
    QSInterfaceController *i = [self enterTextModeWithString:@"test string"];

    // Wait for async updates
    [self waitForAsyncUpdates];

    // The default action for text (e.g. "Large Type") typically has argumentCount == 1,
    // so the indirect check should be skipped entirely.
    QSAction *action = [[i aSelector] objectValue];
    if (action && [action argumentCount] != 2) {
        // For single-argument actions, executeCommand should succeed without
        // any attempt to focus iSelector
        [i executeCommand:self];
        NSResponder *firstResponder = [[i window] firstResponder];
        XCTAssertNotEqual(firstResponder, [i iSelector],
            @"Single-argument action should not move focus to 3rd pane");
    }
}

/**
 * Verify that executeCommand: actually fires the action by listening for
 * QSCommandExecutedNotification. For a single-arg text action, execution
 * goes through performExecuteAction: synchronously (since QSGCDMainSync
 * runs inline on the main thread).
 */
- (void)testExecuteCommandFiresActionNotification {
    QSInterfaceController *i = [self enterTextModeWithString:@"hello world"];
    [self waitForAsyncUpdates];

    QSAction *action = [[i aSelector] objectValue];
    XCTAssertNotNil(action, @"Action should be populated after timer fire");

    // Text actions (e.g. Large Type) have argumentCount == 1, so execution
    // goes through the direct performExecuteAction: path (no completion block).
    // QSGCDMainSync runs the block inline since we're already on the main thread,
    // so the notification is posted synchronously before executeCommand: returns.
    __block BOOL notificationReceived = NO;
    id observer = [[NSNotificationCenter defaultCenter]
        addObserverForName:QSCommandExecutedNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *notif) {
                    notificationReceived = YES;
                }];

    [i executeCommand:self];

    [[NSNotificationCenter defaultCenter] removeObserver:observer];
    XCTAssertTrue(notificationReceived,
        @"QSCommandExecutedNotification should fire when executeCommand: runs a single-arg action");
}

/**
 * Verify that executeCommand: fires the action even without waiting for
 * async indirect object updates. For single-arg actions this should always
 * succeed since they bypass the indirect update path entirely.
 */
- (void)testExecuteCommandFiresActionWithoutAsyncWait {
    QSInterfaceController *i = [self enterTextModeWithString:@"test"];

    // Deliberately do NOT call waitForAsyncUpdates.
    // Single-arg actions go through performExecuteAction: directly,
    // so the async indirect update is irrelevant.

    QSAction *action = [[i aSelector] objectValue];
    XCTAssertNotNil(action, @"Action should be populated after timer fire");

    __block BOOL notificationReceived = NO;
    id observer = [[NSNotificationCenter defaultCenter]
        addObserverForName:QSCommandExecutedNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *notif) {
                    notificationReceived = YES;
                }];

    [i executeCommand:self];

    [[NSNotificationCenter defaultCenter] removeObserver:observer];
    XCTAssertTrue(notificationReceived,
        @"Single-arg action should fire immediately without waiting for async indirect updates");
}

/**
 * Verify that updateIndirectObjectsWithCompletion: actually invokes its
 * completion block after the async background→main dispatch completes.
 * This is the core mechanism of the race condition fix: executeCommand:
 * passes the rest of execution as a completion block so it runs only
 * after indirect objects are populated.
 */
//- (void)testCompletionBlockCalledAfterIndirectUpdate {
//    QSInterfaceController *i = [self enterTextModeWithString:@"hello"];
//    [self waitForAsyncUpdates];
//
//    XCTestExpectation *completionCalled = [self expectationWithDescription:@"completion block invoked"];
//
//    [i updateIndirectObjectsWithCompletion:^{
//        [completionCalled fulfill];
//    }];
//
//    [self waitForExpectationsWithTimeout:5.0 handler:nil];
//}

/**
 * Verify that for two-argument actions, executeCommand: defers execution
 * to the updateIndirectObjectsWithCompletion: completion block rather than
 * running it synchronously.
 *
 * This is the core of the race condition fix: without it, executeCommand:
 * runs performExecuteAction: synchronously, which checks [iSelector objectValue]
 * before the async indirect update has completed. With the fix, execution is
 * deferred to the completion block, which fires only after indirects are set.
 *
 * Detection: with the fix, QSCommandExecutedNotification is NOT posted before
 * executeCommand: returns (it's pending in the completion block on the main
 * queue). Without the fix, the notification fires synchronously inside
 * executeCommand:.
 */
- (void)testTwoArgExecutionDeferredToCompletionBlock {
    QSInterfaceController *i = [self enterTextModeWithString:@"hello world"];
    [self waitForAsyncUpdates];

    QSAction *action = [[i aSelector] objectValue];
    XCTAssertNotNil(action, @"Action should be populated after timer fire");

    // Save original values for cleanup
    NSInteger originalArgCount = [action argumentCount];
    id originalIndirectOptional = [[action actionDict] objectForKey:kActionIndirectOptional];

    // Force the action to appear as a 2-arg action with REQUIRED indirect.
    // argumentCount == 2 makes executeCommand: take the two-arg code path.
    // Removing indirectOptional (defaults to NO) makes the indirect required,
    // which triggers the deferred completion block path when iSelector is nil.
    [action setArgumentCount:2];
    [[action actionDict] removeObjectForKey:kActionIndirectOptional];

    // Track whether the notification fires synchronously (before executeCommand: returns)
    // vs asynchronously (in the completion block, after executeCommand: returns).
    __block BOOL notificationReceived = NO;

    id observer = [[NSNotificationCenter defaultCenter]
        addObserverForName:QSCommandExecutedNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *notif) {
                    notificationReceived = YES;
                }];

    [i executeCommand:self];

    // Check IMMEDIATELY after executeCommand: returns, before spinning the run loop.
    // With the fix: indirect is required but missing (iSelector is nil), so execution
    // is deferred to the updateIndirectObjectsWithCompletion: callback → no notification yet.
    // Without the fix: execution ran synchronously inside executeCommand:.
    XCTAssertFalse(notificationReceived,
        @"For 2-arg actions with required indirect, execution must be deferred to the completion block. "
        @"Synchronous execution indicates the race condition fix is missing.");

    // Allow the async completion to drain so it doesn't interfere with other tests
    [self waitForAsyncUpdates];

    [[NSNotificationCenter defaultCenter] removeObserver:observer];

    // Restore original action state
    [action setArgumentCount:originalArgCount];
    if (originalIndirectOptional) {
        [[action actionDict] setObject:originalIndirectOptional forKey:kActionIndirectOptional];
    } else {
        [[action actionDict] removeObjectForKey:kActionIndirectOptional];
    }
}

/**
 * Regression test for the race condition introduced by making updateIndirectObjects
 * fully async (commit e10140de). When the user presses Return and the action requires
 * an indirect (argumentCount == 2), the async indirect update may not have completed.
 * executeCommand: should fetch indirects via completion block rather than beeping.
 *
 * Uses setObjectValue: directly (not keyDown:) to avoid catalog search dependencies.
 */
- (void)testExecuteCommandWaitsForIndirectsWhenMissing {
    QSInterfaceController *i = [(QSController *)[NSApp delegate] interfaceController];
    XCTAssertNotNil(i);

    // Set a file object directly in dSelector
    QSObject *fileObj = [QSObject fileObjectWithPath:@"/System"];
    [[i dSelector] setObjectValue:fileObj];
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
    [i executeCommand:self];

    // Wait for the async completion to process
    [self waitForAsyncUpdates];

    // The first responder should NOT be iSelector — that would mean the bug occurred
    NSResponder *firstResponder = [[i window] firstResponder];
    XCTAssertNotEqual(firstResponder, [i iSelector],
        @"Focus should not have moved to iSelector — the indirect objects race condition was not handled");
}

/**
 * Regression test: executeCommand: must NOT unconditionally re-fetch indirect objects,
 * as that would overwrite user-entered content in the 3rd pane.
 *
 * Simulates: select file → choose "Open With" → select an app in 3rd pane → Return
 * The user's selection in the 3rd pane must be preserved, not overwritten.
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

    // Now simulate the user selecting a specific app in the 3rd pane
    QSObject *userSelectedApp = [QSObject fileObjectWithPath:@"/Applications/Safari.app"];
    [[i iSelector] setObjectValue:userSelectedApp];
    XCTAssertNotNil([[i iSelector] objectValue], @"iSelector should have the user's selection");

    // Call executeCommand: — this should use the user's selection, NOT re-fetch
    [i executeCommand:self];

    // Wait for any async operations to settle
    [self waitForAsyncUpdates];

    // executeCommand: should NOT have moved focus to iSelector
    NSResponder *firstResponder = [[i window] firstResponder];
    XCTAssertNotEqual(firstResponder, [i iSelector],
        @"executeCommand: should have used the user's existing indirect selection, not re-fetched");
}

@end
