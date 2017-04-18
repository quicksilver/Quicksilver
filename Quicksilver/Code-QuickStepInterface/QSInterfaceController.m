#import "QSPreferenceKeys.h"
#import "QSInterfaceController.h"
#import "QSHistoryController.h"
#import "QSObject.h"

#import "QSActionProvider.h"

#import "QSTypes.h"
#import "QSTaskController.h"
#import "QSNotifications.h"

#import "QSObjectCell.h"
#import "QSCommand.h"
#import "QSInterfaceController.h"

#import "QSObject_FileHandling.h"

#import "QSTaskViewer.h"
#import "QSNullObject.h"
#import "QSTaskController.h"
#import "QSController.h"
#import "QSInterfaceController.h"

#import "QSAction.h"
#import "QSWindow.h"
#import "QSSearchObjectView.h"
#import "QSMnemonics.h"
#import "QSLibrarian.h"
#import <QSCore/QSExecutor.h>
#import <IOKit/IOCFBundle.h>
#import <ApplicationServices/ApplicationServices.h>

#import "QSTextProxy.h"
#import "QSMenuButton.h"

#define KeyShift	0x38
#define KeyControl	0x3b
#define KeyOption	0x3A
#define KeyCommand	0x37
#define KeyCapsLock	0x39
#define KeySpace	0x31
#define KeyTabs		0x30

#import "CGSPrivate.h"

@implementation QSInterfaceController

+ (void)initialize {
	static BOOL initialized = NO;
	if (!initialized) {
        [NSApp registerServicesMenuSendTypes:[NSArray arrayWithObjects:NSStringPboardType, NSRTFPboardType, nil]
                                 returnTypes:[NSArray arrayWithObjects:NSStringPboardType, NSRTFPboardType, nil]];
    }
}

+ (NSString *)name { return @"DefaultInterface"; }

+ (NSResponder *)firstResponder {
    return [[[(QSController *)[NSApp delegate] interfaceController] window] firstResponder];
}

- (id)init {
	if (self = [super init]) {
		[self loadWindow];
	}
	return self;
}

- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
	if (!self) {
        return nil;
    }
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(windowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:self];
	[nc addObserver:self selector:@selector(windowDidResignKey:) name:NSWindowDidResignKeyNotification object:self];
	[nc addObserver:self selector:@selector(objectModified:) name:QSObjectModified object:nil];
	[nc addObserver:self selector:@selector(searchObjectChanged:) name:@"SearchObjectChanged" object:nil];
	[nc addObserver:self selector:@selector(sourceArrayCreated:) name:@"QSSourceArrayCreated" object:nil];
	[nc addObserver:self selector:@selector(sourceArrayChanged:) name:@"QSSourceArrayUpdated" object:nil];
	[nc addObserver:self selector:@selector(appChanged:) name:QSActiveApplicationChanged object:nil];
	[QSHistoryController sharedInstance];
	return self;
}

- (void)dealloc {
	if([actionsUpdateTimer isValid])
		[actionsUpdateTimer invalidate];
	if([hideTimer isValid])
		[hideTimer invalidate];
	//[progressIndicator release];
	//[iSelector release];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:progressIndicator];
	[nc removeObserver:self];
	
}

- (void)windowDidLoad {
	//if (![[self window] setFrameUsingName:[self window] Key]) [[self window] center];
	[progressIndicator stopAnimation:self];
	[progressIndicator setDisplayedWhenStopped:NO];
	[aSelector setEnabled:NO];
	[aSelector setAllowText:NO];
	// [aSelector setInitiatesDrags:NO];
	[aSelector setDropMode:QSRejectDropMode];

	[aSelector setSearchMode:SearchFilter];
	[aSelector setAllowNonActions:NO];
	// only store history for the first pane
	dSelector.recordsHistory = YES;
	aSelector.recordsHistory = NO;
	iSelector.recordsHistory = NO;

	[self hideIndirectSelector:nil];

	[[self window] setHidesOnDeactivate:NO];
    [[self window] useQuicksilverCollectionBehavior];
	[[self menuButton] setMenu:[(QSController *)[NSApp delegate] statusMenuWithQuit]];

#if 0
	QSObjectCell *attachmentCell = [[QSObjectCell alloc] initTextCell:@""];
	[attachmentCell setRepresentedObject:[QSObject fileObjectWithPath:@"/Volumes/Lore/"]];
	[[attachmentCell representedObject] loadIcon];

	NSTextAttachment *attachment = [[[NSTextAttachment alloc] init] autorelease];
	[attachment setAttachmentCell: attachmentCell];
#endif
    
    // NSAttributedString *attributedString = [NSAttributedString attributedStringWithAttachment: attachment];
	//[[commandView textStorage] appendAttributedString:attributedString];
	[self searchObjectChanged:nil];

	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:progressIndicator selector:@selector(startAnimation:) name:QSTasksStartedNotification object:nil];
	[nc addObserver:progressIndicator selector:@selector(stopAnimation:) name:QSTasksEndedNotification object:nil];
}

- (QSCommand *)currentCommand { 
    return [QSCommand commandWithDirectObject:[dSelector objectValue] actionObject:[aSelector objectValue] indirectObject:[iSelector objectValue]];
}

- (void)setCommand:(QSCommand *)command {
    [self window];
    [dSelector setObjectValue:[command dObject]];
    [aSelector setObjectValue:[command aObject]];
    [iSelector setObjectValue:[command iObject]];
}

- (void)setCommandWithArray:(NSArray *)array {
	[dSelector setObjectValue:[array objectAtIndex:0]];
	[actionsUpdateTimer invalidate];
	[aSelector setObjectValue:[array objectAtIndex:1]];
	if ([array count] > 2)
		[iSelector setObjectValue:[array objectAtIndex:2]];
	else
		[iSelector setObjectValue:nil];
}

- (void)selectObject:(QSBasicObject *)object {
	[dSelector setObjectValue:object];
}

- (QSBasicObject *)selection {
	return [dSelector objectValue];
}

- (void)showMainWindow:(id)sender {
    QSGCDMainAsync(^{
        [[self window] makeKeyAndOrderFront:sender];
        // Switch the keyboard/hotkey on the main thread.
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kSuppressHotKeysInCommand]) {
            CGSConnection conn = _CGSDefaultConnection();
            CGSSetGlobalHotKeyOperatingMode(conn, CGSGlobalHotKeyDisable);
        }
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"QSSwitchKeyboardOnActivation"]) {
            savedKeyboard = TISCopyCurrentKeyboardLayoutInputSource();
            NSString *forcedKeyboardId = [[NSUserDefaults standardUserDefaults] objectForKey:@"QSForcedKeyboardIDOnActivation"];
            NSDictionary *filter = [NSDictionary dictionaryWithObject:forcedKeyboardId forKey:(NSString *)kTISPropertyInputSourceID];
            CFArrayRef keyboards = TISCreateInputSourceList((__bridge CFDictionaryRef)filter, false);
            if (keyboards) {
                TISInputSourceRef selected = (TISInputSourceRef)CFArrayGetValueAtIndex(keyboards, 0);
                TISSelectInputSource(selected);
                CFRelease(keyboards);
            } else {
                // If previously selected keyboard is no longer available, turn off automatic switch
                [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"QSSwitchKeyboardOnActivation"];
            }
        }
    });
}

- (void)willHideMainWindow:(id)sender {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kSuppressHotKeysInCommand]) {
		CGSConnection conn = _CGSDefaultConnection();
		CGSSetGlobalHotKeyOperatingMode(conn, CGSGlobalHotKeyEnable);
	}
	if ([[self window] isVisible] && ![[self window] attachedSheet]) {
		[[self window] makeFirstResponder:nil];
	}
    // Close the Quicklook panel if the QS window closes
    if([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible]) {
        [(QSSearchObjectView *)[[QLPreviewPanel sharedPreviewPanel] delegate] closePreviewPanel];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"QSSwitchKeyboardOnActivation"] && savedKeyboard) {
        TISSelectInputSource(savedKeyboard);
        CFRelease(savedKeyboard);
        savedKeyboard = nil;
    }
}

- (void)hideMainWindowWithEffect:(id)effect {
	[self willHideMainWindow:nil];
	[self setHiding:YES];
	if (effect && [[NSUserDefaults standardUserDefaults] boolForKey:kUseEffects])
		[(QSWindow *)[self window] hideWithEffect:effect];
	else {
        if ([self isKindOfClass:[QSCommandBuilder class]]) {
            [self hideWindows:nil];
        }
        else {
            [[self window] orderOut:nil];
        }
    }
	[self setHiding:NO];
	[dSelector clearSearch];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSReleaseOldCachesNotification object:self];
    
}

- (void)hideMainWindow:(id)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:QSInterfaceDeactivatedNotification object:self];
	[self hideMainWindowWithEffect:nil];
}

- (void)hideMainWindowFromExecution:(id)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:QSInterfaceDeactivatedNotification object:self userInfo:@{kQSInterfaceDeactivatedReason: @"execution"}];
	[self hideMainWindowWithEffect:
     [[self window] windowPropertyForKey:kQSWindowExecEffect]];
}

- (void)hideMainWindowFromCancel:(id)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:QSInterfaceDeactivatedNotification object:self userInfo:@{kQSInterfaceDeactivatedReason: @"cancel"}];
	[self hideMainWindowWithEffect:
     [[self window] windowPropertyForKey:kQSWindowCancelEffect]];
}

- (void)hideMainWindowFromFade:(id)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:QSInterfaceDeactivatedNotification object:self userInfo:@{kQSInterfaceDeactivatedReason: @"fade"}];
	if ([[self window] respondsToSelector:@selector(windowPropertyForKey:)])
		[self hideMainWindowWithEffect:
         [[self window] windowPropertyForKey:kQSWindowFadeEffect]];
}

- (void)showIndirectSelector:(id)sender {
    if (![[[[self window] contentView] subviews] containsObject:iSelector]) {
        [[[self window] contentView] addSubview:iSelector];
        [aSelector setNextKeyView:iSelector];
    }
}

- (void)hideIndirectSelector:(id)sender {
    if ([[[[self window] contentView] subviews] containsObject:iSelector]) {
        [iSelector removeFromSuperview];
    }
}

- (void)clearObjectView:(QSSearchObjectView *)view {
    [view clearObjectValue];
    [view clearSearch];
}

- (void)updateControl:(QSSearchObjectView *)control withArray:(NSArray *)array {
	id defaultSelection = nil;
	if ([array count]) {
        defaultSelection = [array objectAtIndex:0];
        if ([defaultSelection isKindOfClass:[NSNull class]]) {
            defaultSelection = nil;
        }
		if ([[array lastObject] isKindOfClass:[NSArray class]]) {
			array = [array lastObject];
		} else if (defaultSelection == nil) {
            // first object is NULL, so make the resultsList an array excluding this first object
            array = [array tail];
        }
	}
	[control clearObjectValue];
	[control setSourceArray:[array mutableCopy]];
	[control setResultArray:[array mutableCopy]];
    [control reloadResultTable];
	[control selectObject:defaultSelection];
}

- (NSTimer *)actionsUpdateTimer {
    return actionsUpdateTimer;
}

- (void)setActionUpdateTimer {
	if ([actionsUpdateTimer isValid]) {
		// *** this was causing actions not to update for the search contents action
		[actionsUpdateTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:0.10]];
		//[actionsUpdateTimer fire];
		//	NSLog(@"action %@", [actionsUpdateTimer fireDate]);
	} else {
		[actionsUpdateTimer invalidate];
		actionsUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.10 target:self selector:@selector(updateActionsNow) userInfo:nil repeats:NO];
	}
}

- (void)fireActionUpdateTimer {
	[actionsUpdateTimer fire];
}

- (NSArray *)rankedActions {
    id dObject = [dSelector objectValue];
    id iObject = [iSelector objectValue];
    if([dObject isKindOfClass:[QSRankedObject class]])
        dObject = [dObject object];
    
    if([iObject isKindOfClass:[QSRankedObject class]])
        iObject = [iObject object];
    
	return [QSExec rankedActionsForDirectObject:dObject indirectObject:iObject];
}

- (void)updateActions {
    // update the actions after a delay (see setActionUpdateTimer for the delay length)
	[self performSelectorOnMainThread:@selector(setActionUpdateTimer) withObject:nil waitUntilDone:YES];
}

- (void)updateActionsNow {
    // Clear the current results in the aSelector ready for the new results
    if ([aSelector resultArray]) {
        [aSelector setResultArray:nil];
    }
	[actionsUpdateTimer invalidate];

	[aSelector setEnabled:YES];
	NSString *type = [NSString stringWithFormat:@"QSActionMnemonic:%@", [[dSelector objectValue] primaryType]];
	NSArray *actions = [self rankedActions];

	[self updateControl:aSelector withArray:actions];

	[aSelector setMatchedString:type];
	[aSelector setSearchString:nil];
}

- (void)updateIndirectObjects {
    // Don't update the indirect objects if this is a 'silent' update.
    if ([aSelector updatesSilently]) {
        return;
    }
    QSAction *aObj = [aSelector objectValue];
    id actionProvider = [aObj provider];
    NSArray *indirects = nil;
    if (actionProvider && [actionProvider respondsToSelector:@selector(validIndirectObjectsForAction:directObject:)]) {
        QSObject *directObject = [[dSelector objectValue] resolvedObject];
        indirects = [actionProvider validIndirectObjectsForAction:[aObj identifier] directObject:directObject];
    }
    // If the validIndirectObjectsForAction... method hasn't been implemented, attempt to get valid indirects from the action's 'indirectTypes'
    if(!indirects) {
        if ([aObj indirectTypes]) {
            NSMutableArray *indirectsForAllTypes = [[NSMutableArray alloc] initWithCapacity:0];
            [[aObj indirectTypes] enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *eachType, NSUInteger idx, BOOL *stop) {
                [indirectsForAllTypes addObjectsFromArray:[QSLib arrayForType:eachType]];
            }];
            if ([indirectsForAllTypes count]) {
                indirects = [indirectsForAllTypes copy];
            }
        }
    }
	[self updateControl:iSelector withArray:indirects];
	[iSelector setSearchMode:(indirects?SearchFilter:SearchFilterAll)];
}

- (void)updateViewLocations {
    QSAction *obj = [aSelector objectValue];
	if (obj && ([obj respondsToSelector:@selector(argumentCount)]) && ([obj argumentCount] == 2)) {
		[self showIndirectSelector:nil];
	} else if ([dSelector objectValue] == nil || [aSelector objectValue] != nil) {
		[self hideIndirectSelector:nil];
    }
}

- (void)performService:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error {
	QSObject *entry;
	entry = [[QSObject alloc] initWithPasteboard:pboard];
	[dSelector setObjectValue:entry];
	[self activate:self];
}

- (void)searchArray:(NSMutableArray *)array {
    // show the results list with the first pane empty
    [self showArray:array withDirectObject:nil];
}

- (void)showArray:(NSMutableArray *)array {
    // display the results list with these items
    if (array && [array count] > 0) {
        // put the first item from the array into the first pane
        [self showArray:array withDirectObject:[array objectAtIndex:0]];
    } else {
        // nothing to display - present a blank interface
        [self showArray:array withDirectObject:nil];
    }

    [dSelector showResultView:self];
}

- (void)showArray:(NSMutableArray *)array withDirectObject:(QSObject *)dObject {
    [actionsUpdateTimer invalidate];
    [self clearObjectView:dSelector];
    [dSelector setSourceArray:array];
    [dSelector setResultArray:array];
    [dSelector setSearchMode:SearchFilter];
    if (dObject) {
        // show an item from this array if set
        [dSelector selectObjectValue:dObject];
    }
    [self updateViewLocations];
    [self updateActionsNow];
    [self showMainWindow:self];
    [[self window] makeFirstResponder:dSelector];
}

#pragma mark -
#pragma mark Notifications
- (void)objectModified:(NSNotification*)notif {
	if ([[dSelector objectValue] isEqual:[notif object]]) {
#ifdef DEBUG
		if (VERBOSE) NSLog(@"Reloading actions for: %@", [notif object]);
#endif
		[self updateActions];
	}
}

- (void)searchObjectChanged:(NSNotification*)notif {
	[[self window] disableFlushWindow];
	if ([notif object] == dSelector) {
        [self updateActions];
	} else if ([notif object] == aSelector) {
        QSAction *obj = [aSelector objectValue];
        if (!obj) {
            [iSelector setObjectValue:nil];
        }
        if ([obj isKindOfClass:[QSRankedObject class]])
            obj = [(QSRankedObject*)obj object];
        if ([obj isKindOfClass:[QSAction class]]) {
            NSInteger argumentCount = [obj argumentCount];
            // update indirects if the action requires it, or if the iSelector is already visible and the action has indirectOptional
            if (argumentCount == 2 || ([[[[self window] contentView] subviews] containsObject:iSelector] && [obj indirectOptional])) {
                [self updateIndirectObjects];
            }
            [self updateViewLocations];
        }
    } else if ([notif object] == iSelector) {
        [self updateViewLocations];
    }
	[[self window] enableFlushWindow];
}

- (void)sourceArrayCreated:(NSNotification *)notif
{
	[self showArray:[[notif userInfo] objectForKey:kQSResultArrayKey]];
}

- (void)sourceArrayChanged:(NSNotification *)notif
{
	//NSLog(@"notif %@ - change to %@", [notif name], [notif userInfo]);
	// resultArray and sourceArray point to the same object until the user starts typing.
	// We want to stop getting updates at that point, so we compare to the resultArray instead.
	if ([[dSelector resultArray] isEqual:[[notif userInfo] objectForKey:kQSResultArrayKey]]) {
		//NSLog(@"arraychanged");
		if ([[dSelector->resultController window] isVisible]) {
			[dSelector reloadResultTable];
			[dSelector->resultController updateSelectionInfo];
		}
		if (![[dSelector resultArray] containsObject:[dSelector selectedObject]]) {
			if ([[dSelector resultArray] count]) {
				[dSelector selectObjectValue:[[dSelector resultArray] objectAtIndex:0]];
			} else {
				[dSelector clearObjectValue];
			}
		}
		if ([self respondsToSelector:@selector(searchView:changedResults:)])
			[self searchView:dSelector changedResults:[dSelector resultArray]];
	}
}

- (void)appChanged:(NSNotification *)aNotification {
    // Close the QS window if it's visible and the Quicksilver itself isn't the application gaining focus
	if ([[self window] isVisible] && ![[[[NSWorkspace sharedWorkspace] activeApplication] objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:kQSBundleID]) {
		[self hideWindows:self];
    }
}

- (void)invalidateHide {
	[hideTimer invalidate];
}

- (void)timerHide:(NSTimer *)timer {
	if (preview) return;
	bool stayOpen = [NSEvent pressedMouseButtons];
	if (!stayOpen) {
		 // NSLog(@"Window Closing");
		if ([[NSApp keyWindow] level] <= [[self window] level])
			// ***warning  * this needs to be better
			[self hideMainWindowFromFade:self];
		[hideTimer invalidate];
	} else {
		//	NSLog(@"Window Staying Open");
	}
}

- (void)clear:(NSTimer *)timer {
	[dSelector clearObjectValue];
	[self updateActionsNow];
}

- (void)ignoreInterfaceNotifications
{
	// subclasses (namely the Command Builder) need a way to overlook notifications meant for the main interface
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name:@"QSSourceArrayCreated" object:nil];
	[nc removeObserver:self name:@"QSSourceArrayUpdated" object:nil];
}

#pragma mark -
#pragma mark NSWindow
#pragma mark Delegate
- (BOOL)windowShouldClose:(id)sender {
	[self hideMainWindowFromCancel:self];
	return NO;
}

#pragma mark Notifications
- (void)windowDidResignMain:(NSNotification *)aNotification {}

- (void)windowDidResignKey:(NSNotification *)aNotification {
    // Close the Quicklook panel if the QS window closes
    if([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible]) {
        return;
    }
	if ([aNotification object] == [self window]) {
		if (hidingWindow) return;
		if ([hideTimer isValid]) {
			[hideTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		} else {
			hideTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerHide:) userInfo:nil repeats:YES];
			[hideTimer fire];
		}
	} else if (![NSApp keyWindow]) {
		[self hideMainWindowFromFade:self];
	}
}

- (void)windowDidBecomeKey:(NSNotification *)notification {
	NSWindow *window = [notification object];
	if ([[self window] attachedSheet] == window)
		return;
	if (window == [self window]) {
		[hideTimer invalidate];
	} else if ([window level] <= [[self window] level]) {
		//NSLog(@"hide! %@", window);
		// ***warning  * this needs to be better
		[self hideWindows:self];
	}
}


#pragma mark -
#pragma mark Command Execution
- (void)executeCommandThreaded {
    @autoreleasepool {
#ifdef DEBUG
        NSDate *startDate = [NSDate date];
#endif
        QSAction *action = [aSelector objectValue];
        QSObject *dObject = [dSelector objectValue];
        QSObject *iObject = [iSelector objectValue];
        if( [dObject isKindOfClass:[QSRankedObject class]] )
            dObject = [(QSRankedObject*)dObject object];
        if( [iObject isKindOfClass:[QSRankedObject class]] )
            iObject = [(QSRankedObject*)iObject object];
        QSCommand *command = [QSCommand commandWithDirectObject:dObject actionObject:action indirectObject:iObject];
        [command execute];
#ifdef DEBUG
        if (VERBOSE) NSLog(@"Command executed (%ldms) ", (long)(-[startDate timeIntervalSinceNow] *1000));
#endif
    }
}

- (void)executePartialCommand:(NSArray *)array {
	// remove objects previously selected by the comma trick
	[self clearObjectView:dSelector];
	[dSelector setObjectValue:[array objectAtIndex:0]];
	if ([array count] == 1) {
		[self updateActionsNow];
		[[self window] makeFirstResponder:aSelector];
	} else {
		[actionsUpdateTimer invalidate];
		[aSelector setObjectValue:[array objectAtIndex:1]];
		if ([array count] > 2) {
			[iSelector setObjectValue:[array objectAtIndex:2]];
		} else {
			[self updateIndirectObjects];
		}
		[[self window] makeFirstResponder:iSelector];
	}
	[self updateViewLocations];
	[self showInterface:self];
}

- (void)executeCommand:(id)sender cont:(BOOL)cont encapsulate:(BOOL)encapsulate {
	if ([actionsUpdateTimer isValid]) {
		[actionsUpdateTimer fire];
	}
	if (![aSelector objectValue]) {
		NSBeep();
		return;
	}

    QSAction *action = [aSelector objectValue];
	NSInteger argumentCount = [action argumentCount];
	if (argumentCount == 2) {
		BOOL indirectIsRequired = ![action indirectOptional];
		BOOL indirectIsInvalid = ![iSelector objectValue];
		BOOL indirectIsTextProxy = [[[iSelector objectValue] primaryType] isEqual:QSTextProxyType];
		if (indirectIsRequired && (indirectIsInvalid || indirectIsTextProxy) ) {
			if (indirectIsInvalid) NSBeep();
			[[self window] makeFirstResponder:iSelector];
			return;
		}
		[QSExec noteIndirect:[iSelector objectValue] forAction:action];
	}
	
	// add the object being executed to the history
	[dSelector updateHistory];
	// make sure to save mnemonics before interface is closed. Closing the interface clears the search string so they must be saved before this
	[QSHist addCommand:[self currentCommand]];
	[dSelector saveMnemonic];
	[aSelector saveMnemonic];
	if (argumentCount == 2) {
		[iSelector saveMnemonic];
	}
	
	if (encapsulate) {
		[self encapsulateCommand];
		return;
	}
	if (!cont) {
		// this ensures the interface is hidden before an action is run e.g. the 'capture screen region' and 'type text' actions needs this
		[self hideMainWindowFromExecution:self]; // *** this should only hide if no result comes in like 2 seconds
	}
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kExecuteInThread] && [action canThread]) {
		QSGCDAsync(^{
			[self executeCommandThreaded];
		});
	} else {
		// action can only be run on main thread 
		QSGCDMainSync(^{
			[self executeCommandThreaded];
		});
	}
	if (cont) {
		[[self window] makeFirstResponder:aSelector];
	}
}

- (void)encapsulateCommand {
#ifdef DEBUG
	if (VERBOSE) NSLog(@"Encapsulating Command");
#endif
	QSCommand *commandObject = [self currentCommand];
    [self clearObjectView:dSelector];
	[self selectObject:commandObject];
	[self actionActivate:commandObject];
}


#pragma mark -
#pragma mark IBActions
- (IBAction)showInterface:(id)sender {
	 
	[[NSNotificationCenter defaultCenter] postNotificationName:QSInterfaceActivatedNotification object:self];
	[self showMainWindow:self];
}

- (IBAction)activate:(id)sender {
	if ([[self window] isVisible]) {
		[self hideMainWindowFromCancel:sender];
		return;
	}

	[hideTimer invalidate];
	[dSelector reset:self];
	[self updateActions];
	[iSelector reset:self];
	[[dSelector objectValue] loadIcon];
	[self setPreview:NO];
	[self showInterface:self];
    
	[[self window] makeFirstResponder:dSelector];
    
	[dSelector setSearchMode:SearchFilterAll];
}

- (IBAction)activateInTextMode:(id)sender {
	[dSelector transmogrify:sender];
	[iSelector reset:self];
	[self showInterface:self];
}

// Method that detects which pane should be focused on re-activating of Quicksilver interface
- (IBAction)actionActivate:(id)sender {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"QSJumpToActionOnResult"]) {
        [self updateActionsNow];
        [iSelector reset:self];
        [[self window] makeFirstResponder:aSelector];
    }
	[self showInterface:self];
}

- (IBAction)executeCommand:(id)sender {
    // run the action and set focus to the 1st pane
    [self executeCommand:sender cont:NO encapsulate:NO];
}

- (IBAction)executeCommandAndContinue:(id)sender {
    // run the action and set focus to the 2nd pane
	[self executeCommand:sender cont:YES encapsulate:NO];
}

- (IBAction)shortCircuit:(id)sender {
	//NSLog(@"scirr");
	[self fireActionUpdateTimer];
	NSArray *array = [aSelector resultArray];
    
	NSInteger argumentCount = [(QSAction *)[aSelector objectValue] argumentCount];
    
	if (sender == iSelector) {
		NSInteger index = [array indexOfObject:[aSelector objectValue]];
		NSInteger count = [array count];
		if (index != count-1)
			array = [[array subarrayWithRange:NSMakeRange(index+1, count-index-1)] arrayByAddingObjectsFromArray:
                     [array subarrayWithRange:NSMakeRange(0, index+1)]];
		argumentCount = 0;
		[[self window] makeFirstResponder:nil];
	}
    
    QSAction *bestAction = nil;
	if (argumentCount != 2) {
		QSAction *action = nil;
		for(action in array) {
			if ([action argumentCount] == 2) {
				bestAction = action;
				[aSelector selectObject:action];
				break;
			}
		}
		if (!bestAction) {
			NSBeep();
			return;
		}
	}
	[[self window] makeFirstResponder:iSelector];
}

- (IBAction)encapsulateCommand:(id)sender {
	[self executeCommand:sender cont:NO encapsulate:YES];
}

- (IBAction)hideWindows:(id)sender {
	[self hideMainWindow:self];
}

- (IBAction)showTasks:(id)sender {
	[[NSClassFromString(@"QSTaskViewer") sharedInstance] showWindow:self];
}

- (IBAction)showAbout:(id)sender {
	[(QSController *)[NSApp delegate] showAbout:sender];
}

#pragma mark -
#pragma mark NSResponder overrides
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent {
	if (([theEvent modifierFlags] & NSCommandKeyMask) && 
       ([theEvent modifierFlags] & NSShiftKeyMask) && 
       ([[theEvent characters] length]) && 
       ([[NSCharacterSet letterCharacterSet] characterIsMember:[[theEvent characters] characterAtIndex:0]])) {
		return [[self aSelector] executeText:(NSEvent *)theEvent];
	}
	return NO;
}

#pragma mark -
#pragma mark Accessors

- (QSSearchObjectView *)dSelector { return dSelector; }

- (QSSearchObjectView *)aSelector { return aSelector; }

- (QSSearchObjectView *)iSelector { return iSelector; }

- (QSMenuButton *)menuButton { return menuButton; }

- (NSProgressIndicator *)progressIndicator { return progressIndicator;  }

- (NSSize) maxIconSize { return QSSize256; }

- (BOOL)preview { return preview; }
- (void)setPreview: (BOOL)flag { preview = flag; }

- (BOOL)hiding { return hidingWindow; }
- (void)setHiding:(BOOL)flag { hidingWindow = flag; }


@end
