#import "QSPreferenceKeys.h"
#import "QSSearchObjectView.h"
#import "QSLibrarian.h"
#import "QSResultController.h"
#import "QSInterfaceController.h"
#import "QSFSBrowserMediator.h"
#import "QSMnemonics.h"
#import "QSWindow.h"
#import "QSRegistry.h"
#import "QSExecutor.h"
#import "QSHistoryController.h"

#import <QSFoundation/QSFoundation.h>
#import "QSNotifications.h"

#import "QSObject.h"
#import "QSObject_Drag.h"
#import "QSAction.h"
#import "QSObject_FileHandling.h"
#import "QSObject_StringHandling.h"

#import "QSObject_Pasteboard.h"
#import "NSString_Purification.h"
#import "QSObject_PropertyList.h"
#import "QSBackgroundView.h"
#import "QSController.h"

#import "QSGlobalSelectionProvider.h"

#import "QSTextProxy.h"

#define pUserKeyBindingsPath QSApplicationSupportSubPath(@"KeyBindings.qskeys", NO)
#define MAX_HISTORY_COUNT 20
#define SEARCH_RESULT_DELAY 0.05f
#define kQSSmartSpace @"smartspace"

NSMutableDictionary *bindingsDict = nil;

@implementation QSSearchObjectView

@synthesize textModeEditor, alternateActionCounterpart, resultController, updatesSilently, resultArray = _resultArray;

+ (void)initialize {
    if( bindingsDict == nil ) {
        NSDictionary *defaultBindings = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[QSSearchObjectView class]] pathForResource:@"DefaultBindings" ofType:@"qskeys"]];
        bindingsDict = [[NSMutableDictionary alloc] initWithDictionary:[defaultBindings objectForKey:@"QSSearchObjectView"]];
        [bindingsDict addEntriesFromDictionary:[[NSDictionary dictionaryWithContentsOfFile:pUserKeyBindingsPath] objectForKey:@"QSSearchObjectView"]];
		// replace \n with \r for compatibility with NDKeyboardLayout
		for (NSString *key in [bindingsDict allKeys]) {
			if ([key containsString:@"\n"]) {
				NSString *newKey = [key stringByReplacingOccurrencesOfString:@"\n" withString:@"\r"];
				bindingsDict[newKey] = bindingsDict[key];
				[bindingsDict removeObjectForKey:key];
			}
		}
    }
}
#pragma mark -
#pragma mark Lifetime
- (void)awakeFromNib {
	[super awakeFromNib];
	resetTimer = nil;
	searchTimer = nil;
	resultTimer = nil;
	preferredEdge = NSMaxXEdge;
	partialString = [[NSMutableString alloc] initWithCapacity:1];
	[partialString setString:@""];

	matchedString = nil;

	_sourceArray = nil;
	_searchArray = nil;
	_resultArray = nil;
	self.recordsHistory = YES;
	shouldResetSearchArray = YES;
	allowNonActions = YES;
	allowText = YES;
    updatesSilently = NO;
    // FIXME: Look, a view that owns a controller...
	resultController = [[QSResultController alloc] initWithObjectView:self];
	resultController.nextResponder = self;

	[self setTextCellFont:[NSFont systemFontOfSize:12.0]];
    [self setTextCellFontColor:[NSColor blackColor]];
    
    [self setTextModeEditor:(NSTextView *)[[self window] fieldEditor:YES forObject:self]];
    
    [[self textModeEditor] bind:@"textColor" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.QSAppearance3T" options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:NSValueTransformerNameBindingOption]];
    [[self textModeEditor] bind:@"insertionPointColor" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.QSAppearance3T" options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:NSValueTransformerNameBindingOption]];
    [[self textModeEditor] setAllowsUndo:YES];
    
    [[self textModeEditor] setAutomaticTextReplacementEnabled:YES];
    
	searchMode = QSSearchModeFilter;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideResultView:) name:@"NSWindowDidResignKeyNotification" object:[self window]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearAll) name:QSReleaseAllNotification object:nil];

	resultsPadding = 0;
	historyArray = [[NSMutableArray alloc] initWithCapacity:10];
	parentStack = [[NSMutableArray alloc] initWithCapacity:10];

	validSearch = YES;
    
	[resultController window];
	[self setVisibleString:@""];

	[[self cell] bind:@"highlightColor" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.QSAppearance2A" options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:NSValueTransformerNameBindingOption]];
}

- (void)dealloc {
	[self unbind:@"highlightColor"];
    [self unbind:@"textColor"];
    [self unbind:@"backgroundColor"];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark Mnemonics Handling
- (IBAction)assignMnemonic:(id)sender {}

- (IBAction)defineMnemonicImmediately:(id)sender {
	if ([self matchedString])
		[[QSMnemonics sharedInstance] addAbbrevMnemonic:[self matchedString] forObject:[self objectValue] immediately:YES];
	[self rescoreSelectedItem];
}

- (IBAction)promoteAction:(id)sender {
	[QSExec orderActions:[NSArray arrayWithObject:[self objectValue]] aboveActions:[self resultArray]];
	[self rescoreSelectedItem];
}


- (IBAction)defineMnemonic:(id)sender {
	if ([self matchedString])
		[[QSMnemonics sharedInstance] addAbbrevMnemonic:[self matchedString] forObject:[self objectValue]];
	[self rescoreSelectedItem];
}

- (IBAction)removeImpliedMnemonic:(id)sender {
	if ([self matchedString])
		[[QSMnemonics sharedInstance] removeObjectMnemonic:[self matchedString] forID:[[self objectValue] identifier]];
	[self rescoreSelectedItem];
}

- (IBAction)removeMnemonic:(id)sender {
	if ([self matchedString]) {
		[[QSMnemonics sharedInstance] removeAbbrevMnemonic:[self matchedString] forID:[[self objectValue] identifier]];
		[self rescoreSelectedItem];
	}
}

- (IBAction)clearMnemonics:(id)sender {
	[self removeImpliedMnemonic:sender];
	[self removeMnemonic:sender];
}

- (BOOL)mnemonicDefined {
	return [[[QSMnemonics sharedInstance] abbrevMnemonicsForString:[self matchedString]]
            indexOfObject:[[self objectValue] identifier]] != NSNotFound;
}

- (BOOL)impliedMnemonicDefined {
	return nil != [[[QSMnemonics sharedInstance] objectMnemonicsForID:[[self objectValue] identifier]]objectForKey:[self matchedString]];
}

- (void)saveMnemonic {
	NSString *mnemonicKey = [self matchedString];
	if (!mnemonicKey || [mnemonicKey isEqualToString:@""]) return;
	QSObject *mnemonicValue = [self alternateActionCounterpart] ? [self alternateActionCounterpart] : [self objectValue];
	if ([mnemonicValue count] > 1) {
		mnemonicValue = [[[self objectValue] splitObjects] lastObject];
	}

	[[QSMnemonics sharedInstance] addObjectMnemonic:mnemonicKey forObject:mnemonicValue];
	if (![self sourceArray]) { // don't add abbreviation if in a subsearch
		[[QSMnemonics sharedInstance] addAbbrevMnemonic:mnemonicKey forObject:mnemonicValue relativeToID:nil immediately:NO];
	}

	[mnemonicValue updateMnemonics];
	[self rescoreSelectedItem];
#ifdef DEBUG
	if (VERBOSE) {
		NSLog(@"Added Mnemonic: %@ for object: %@", [self matchedString], [mnemonicValue identifier]);
	}
#endif
}

- (void)rescoreSelectedItem {
	if (![self objectValue]) return;
    // FIXME: This leaks the fact that rank data is effectively global
	[[QSLibrarian sharedInstance] scoredArrayForString:[self matchedString] inSet:[NSArray arrayWithObject:[self objectValue]]];
	if ([[resultController window] isVisible])
		[resultController.resultTable reloadData];
}

#pragma mark -
#pragma mark NSView
- (void)drawRect:(NSRect)rect {
	if ([self currentEditor]) {
		//NSLog(@"editor draw");
		[super drawRect:rect];
		rect = [self frame];

		if (NSWidth(rect) > QSSizeMax.width && NSHeight(rect) > QSSizeMax.height) {
			CGContextRef context = (CGContextRef) ([[NSGraphicsContext currentContext] graphicsPort]);
			CGContextSetAlpha(context, 0.92);
		}
        // Use the background colour from the prefs for the text editor bg color (with a slight transparency)
        NSColor *highlightColor = [[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"QSAppearance3B"]] colorWithAlphaComponent:0.7];
        [highlightColor set];
        NSBezierPath *roundRect = [NSBezierPath bezierPath];
		rect = [self frame];
		rect.origin = NSZeroPoint;
        CGFloat radius = 0;
        NSRect drawRect;
        // Interfaces that have 'bezeled' cells are very picky. See QSObjectCell.m (search for [self isBezeled])
        if ([[self cell] isBezeled] ){
            drawRect = NSInsetRect(rect, 2.25, 2.25);
            radius = drawRect.size.height/2;
        } else {
            radius = [self frame].size.height/[[self cell] cellRadiusFactor];
            drawRect = rect;
        }
        [roundRect appendBezierPathWithRoundedRectangle:drawRect withRadius:radius];
		[roundRect fill];
	} else {
		[super drawRect:rect];
	}
}

- (void)setFrame:(NSRect)frameRect {
	[super setFrame:frameRect];
	if ([self currentEditor]) {
		NSRect editorFrame = [self frame];
		editorFrame.origin = NSZeroPoint;
		editorFrame = NSInsetRect(editorFrame, 3, 3);
		[[[self currentEditor] enclosingScrollView] setFrame: editorFrame];
		[[self currentEditor] setMinSize:editorFrame.size];
	}
}

- (void)viewWillMoveToSuperview:(NSView *)newSuperview {
	if (!newSuperview) {
		[self reset:self];
	}
}

#pragma mark -
#pragma mark Accessors
- (NSMutableString *)partialString { return partialString;}

- (NSString *)visibleString { return visibleString; }
- (void)setVisibleString:(NSString *)newVisibleString {
	if (visibleString != newVisibleString) {
		visibleString = [newVisibleString copy];
		[resultController.searchStringField setStringValue:visibleString];
		if ([[self controller] respondsToSelector:@selector(searchView:changedString:)])
			[(id)[self controller] searchView:self changedString:visibleString];
	}
}

- (NSArray *)resultArray {
	return _resultArray;
}

- (void)setResultArray:(NSMutableArray *)newResultArray {
	_resultArray = newResultArray;
    
	if ([[resultController window] isVisible])
		[self reloadResultTable];
    
	if ([[self controller] respondsToSelector:@selector(searchView:changedResults:)])
		[(id)[self controller] searchView:self changedResults:newResultArray];
}


- (BOOL)shouldResetSearchString { return shouldResetSearchString;  }
- (void)setShouldResetSearchString:(BOOL)flag { shouldResetSearchString = flag; }

- (BOOL)shouldResetSearchArray { return shouldResetSearchArray;  }
- (void)setShouldResetSearchArray:(BOOL)flag { shouldResetSearchArray = flag; }

- (NSRectEdge)preferredEdge { return preferredEdge; }
- (void)setPreferredEdge:(NSRectEdge)newPreferredEdge { preferredEdge = newPreferredEdge; }

- (NSString *)matchedString { return matchedString; }
- (void)setMatchedString:(NSString *)newMatchedString {
    if (matchedString != newMatchedString) {
        matchedString = [newMatchedString copy];
        [self setNeedsDisplay:YES];
    }
}

- (id)selectedObject { return selectedObject;  }
- (void)setSelectedObject:(id)newSelectedObject {
    if (selectedObject != newSelectedObject) {
        selectedObject = newSelectedObject;
    }
}

- (QSSearchMode)searchMode { return [[self resultController] searchMode]; }
- (void)setSearchMode:(QSSearchMode)newSearchMode {
	// Do not allow the setting of 'Filter Catalog' when in the aSelector (action)
	if (!((self == [self actionSelector]) && newSearchMode == QSSearchModeAll)) {
		searchMode = newSearchMode;
	}
	
    [resultController.resultTable setNeedsDisplay:YES];
	if (browsing) {
        [[NSUserDefaults standardUserDefaults] setInteger:searchMode forKey:kBrowseMode];
	}

    [[self resultController] setSearchMode:searchMode];
}

- (NSText *)currentEditor {
	if ([super currentEditor])
		return [super currentEditor];
	else
		return currentEditor;
}

- (void)setCurrentEditor:(NSText *)aCurrentEditor {
	if (currentEditor != aCurrentEditor) {
		currentEditor = aCurrentEditor;
	}
}

- (QSSearchObjectView *)directSelector { return [[self controller] dSelector]; }
- (QSSearchObjectView *)actionSelector { return [[self controller] aSelector]; }
- (QSSearchObjectView *)indirectSelector { return [[self controller] iSelector]; }

- (BOOL)allowText { return allowText; }
- (void)setAllowText:(BOOL)flag { allowText = flag; }

- (BOOL)allowNonActions { return allowNonActions;  }
- (void)setAllowNonActions:(BOOL)flag {
	allowNonActions = flag;
	self.recordsHistory = flag;
}

- (void)setResultsPadding:(CGFloat)aResultsPadding { resultsPadding = aResultsPadding; }

#pragma mark -
#pragma mark Menu Items
- (BOOL)validateMenuItem:(NSMenuItem*)anItem {
	if ([anItem action] == @selector(newFile:) ) {
		return YES;
	}
	if ([anItem action] == @selector(goForward:) ) {
		return historyIndex > 0;
	}
	if ([anItem action] == @selector(goBackward:) ) {
		return YES;
	}
	if ([anItem action] == @selector(defineMnemonicImmediately:) ) {
		if (![self matchedString]) return NO;
		[anItem setTitle:[NSString stringWithFormat:@"Set as Default for \"%@\"", [[self matchedString] uppercaseString]]];
		return YES;
	}
	if ([anItem action] == @selector(removeMnemonic:) ) {
		if (![self matchedString]) return NO;
		[anItem setTitle:[NSString stringWithFormat:@"Remove as Default for \"%@\"", [[self matchedString] uppercaseString]]];
		return YES;
	}
	if ([anItem action] == @selector(clearMnemonics:) ) {
		return [self impliedMnemonicDefined];
	}
    
	return YES;
}

- (IBAction)newFile:(id)sender {
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	NSView *content = [savePanel contentView];
	// NSLog(@"sub %@", [content subviews]);
	if (![content isKindOfClass:[QSBackgroundView class]]) {
		NSView *newBackground = [[QSBackgroundView alloc] init];
		[savePanel setContentView:newBackground];
		[newBackground addSubview:content];
	}
    
	[savePanel setNameFieldLabel:@"Create Item:"];
	[savePanel setCanCreateDirectories:YES];
	NSString *oldFile = [[self objectValue] singleFilePath];
  
	id QSIC = [(QSController *)[NSApp delegate] interfaceController];
	[QSIC setHiding:YES];
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:oldFile]];
	[savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result)
     {
         if (result == NSFileHandlingPanelOKButton) {
             [self setObjectValue:[QSObject fileObjectWithFileURL:[savePanel URL]]];

         }
     }];
	[QSIC setHiding:NO];
}

- (IBAction)openFile:(id)sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:YES];
	NSView *content = [openPanel contentView];
	// NSLog(@"sub %@", [content subviews]);
	if (![content isKindOfClass:[QSBackgroundView class]]) {
		NSView *newBackground = [[QSBackgroundView alloc] init];
		[openPanel setContentView:newBackground];
		[newBackground addSubview:content];
	}
	NSString *oldFile = [[self objectValue] singleFilePath];
    
	id QSIC = [(QSController *)[NSApp delegate] interfaceController];
	[QSIC setHiding:YES];
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:oldFile]];
	[openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result)
     {
         if (result == NSFileHandlingPanelOKButton) {
             [self setObjectValue:[QSObject fileObjectWithFileURL:[openPanel URL]]];
         }
     }];
	[QSIC setHiding:NO];
}

#pragma mark -
#pragma mark Result View
- (IBAction)toggleResultView:(id)sender {
	if ([[resultController window] isVisible])
		[self hideResultView:sender];
	else
		[self showResultView:sender];
}

- (IBAction)showResultView:(id)sender {
	if ([[self window] firstResponder] != self) return;
	if ([[resultController window] isVisible]) return; //[resultController->resultTable reloadData];
    
	NSRect resultWindowRect = [[resultController window] frame];
	NSRect screenRect = [[[self window] screen] frame];
    NSRect sovRect = [[self window] convertRectToScreen:[self frame]];
    NSRect interfaceRect = [[self window] frame];

	if (preferredEdge == NSMaxXEdge) {
		if (interfaceRect.origin.x + NSWidth(interfaceRect) + NSWidth(resultWindowRect) <NSMaxX(screenRect)) {
            // results view on the RHS of the interface
			if (hFlip) {
                [[resultController searchStringField] setAlignment:NSLeftTextAlignment];

				[[[resultController window] contentView] flipSubviewsOnAxis:NO];
				hFlip = NO;
			}
            resultWindowRect.origin.x = interfaceRect.origin.x + interfaceRect.size.width + 1;
		} else {
            // results view on the LHS of the interface
			if (!hFlip) {
                [[resultController searchStringField] setAlignment:NSRightTextAlignment];
				[[[resultController window] contentView] flipSubviewsOnAxis:NO];
				hFlip = YES;
			}
            resultWindowRect.origin.x = interfaceRect.origin.x - resultWindowRect.size.width -1;
		}
        resultWindowRect.origin.y = sovRect.origin.y + sovRect.size.height;

		[[resultController window] setFrameTopLeftPoint:resultWindowRect.origin];
        
	} else {
		NSPoint resultPoint = [[self window] convertBaseToScreen:[self frame] .origin];
		//resultPoint.x;
		CGFloat extraHeight = resultWindowRect.size.height-(resultPoint.y-screenRect.origin.y);
        
		//resultPoint.y += 2;
		resultWindowRect.origin.x = resultPoint.x;
		if (extraHeight>0) {
			resultWindowRect.origin.y = screenRect.origin.y;
			resultWindowRect.size.height -= extraHeight;
		} else {
			//		NSLog(@"pad %f", resultsPadding);
			resultWindowRect.origin.y = resultPoint.y-resultWindowRect.size.height-resultsPadding;
		}
        
		resultWindowRect = NSIntersectionRect(resultWindowRect, screenRect);
		[[resultController window] setFrame:resultWindowRect display:NO];
	}
	[self updateResultView:sender];
    
	if ([[self controller] respondsToSelector:@selector(searchView:resultsVisible:)])
		[(id)[self controller] searchView:self resultsVisible:YES];
    
	if ([[self window] isVisible]) {
		[[resultController window] orderFront:nil];
		// Show the results window
		[[self window] addChildWindow:[resultController window] ordered:NSWindowAbove];
	}
}

- (void)reloadResultTable {
	//[resultController->resultTable reloadData];
	[resultController arrayChanged:nil];
}

- (IBAction)hideResultView:(id)sender {
	[[self window] removeChildWindow:[resultController window]];
	[resultController setResultIconLoader:nil];
	[[resultController window] orderOut:self];
	if (browsing) {
		browsing = NO;
		[self setSearchMode:QSSearchModeAll];
	}
	if ([[self controller] respondsToSelector:@selector(searchView:resultsVisible:)])
		[(id)[self controller] searchView:self resultsVisible:NO];
}

- (IBAction)updateResultView:(id)sender {
	//[resultController->searchModePopUp selectItemAtIndex:[resultController->searchModePopUp indexOfItemWithTag:searchMode]];
	[self reloadResultTable];
	if (selection > NSNotFound - 1) selection = 0;
	[resultController.resultTable selectRowIndexes:[NSIndexSet indexSetWithIndex:(selection ? selection : 0)] byExtendingSelection:NO];
	[resultController updateSelectionInfo];
}

#pragma mark -
#pragma mark Object Value
- (void)selectObjectValue:(id)newObject {
    QSObject *currentObject = [self objectValue];
    
    // resolve the current and new objects in order to compare them
    if ([newObject isKindOfClass:[QSRankedObject class]]) {
        newObject = [(QSRankedObject *)newObject object];
    }
    if ([currentObject isKindOfClass:[QSRankedObject class]]) {
        currentObject = [(QSRankedObject *)currentObject object];
    }
    // if the two objects are not the same, send an 'object chagned' notif
	if (newObject != currentObject) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:QSObjectIconModified object:currentObject];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(objectIconModified:) name:QSObjectIconModified object:newObject];
		[super setObjectValue:newObject];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SearchObjectChanged" object:self];
	}
}

- (void)setObjectValue:(QSBasicObject *)newObject {
	if (newObject == [self objectValue]) {
		return;
	}
    [self hideResultView:self];
    [self clearSearch];
    [parentStack removeAllObjects];
    [self setResultArray:[NSMutableArray arrayWithObjects:newObject, nil]];
    [self selectObjectValue:newObject];
}

- (void)clearObjectValue {
	[self setObjectValue:nil];
	selection--;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SearchObjectChanged" object:self];
}

- (void)redisplayObjectValue:(QSObject *)newObject
{
	[self selectObjectValue:newObject];
}

- (void)clearAll {
    [self clearObjectValue];
	[self clearHistory];
	[self setSourceArray:nil];
	[self setSearchArray:nil];
	[self setResultArray:nil];
	[parentStack removeAllObjects];
	[childStack removeAllObjects];
}

- (void)selectIndex:(NSInteger)index {
	// NSLog(@"selectindex %d %d", self, index);
    
	if (index < 0)
		selection = [self.resultArray count] - 1;
	else if (index >= (NSInteger)[self.resultArray count])
		selection = 0;
	else
		selection = index;
    
	if ([self.resultArray count]) {
		QSObject *object = [self.resultArray objectAtIndex:selection];
        
		[self selectObjectValue:object];
		[resultController.resultTable scrollRowToVisible:selection];
		//[resultController->resultTable centerRowInView:selection];
		[resultController.resultTable selectRowIndexes:[NSIndexSet indexSetWithIndex:(selection ? selection : 0)] byExtendingSelection:NO];
	} else
		[self selectObjectValue:nil];
    
	if ([[resultController window] isVisible])
		[resultController updateSelectionInfo];
}

- (void)selectObject:(QSBasicObject *)obj {
	NSInteger index = 0;
	if (obj) {
		index = (NSInteger)[self.resultArray indexOfObject:obj];
		//NSLog(@"index %d %@", index, obj);
		if (index == NSNotFound) {
			//if (VERBOSE) NSLog(@"Unable To Select Object : %@ in \r %@", [obj identifier] , resultArray);
			return;
		}
	} else {
		[self selectObjectValue:nil];
		return;
	}
	[self selectIndex:index];
}

- (void)objectIconModified:(NSNotification *)notif {
    // icon changed - update it in the pane
    [self setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark Utilities
- (id)externalSelection {
		return [[QSGlobalSelectionProvider sharedInstance] currentSelection];
}

- (void)dropObject:(QSBasicObject *)newSelection {
	NSString *action = [[self objectValue] actionForDragOperation:NSDragOperationEvery withObject:newSelection];
	//NSLog(@"action %@", action);
	QSAction *actionObject = [QSExec actionForIdentifier:action];
    
	if (!action) {
		NSBeep();
		return;
	}
	if ([[self controller] isKindOfClass:[QSInterfaceController class]]) {
		[[self controller] setCommandWithArray:[NSArray arrayWithObjects:newSelection, actionObject, [self objectValue], nil]];
	} else {
		[actionObject performOnDirectObject:(QSObject *)newSelection indirectObject:[self objectValue]];
	}
}

- (void)clearSearch {
	[resetTimer invalidate];
	[resultTimer invalidate];
	[self resetString];
	[partialString setString:@""];
    
	[self setVisibleString:@""];
	[self setMatchedString:nil];
	[self setShouldResetSearchString:YES];
    if([self isEqual:[self actionSelector]]) {
        [self setAlternateActionCounterpart:nil];
    }
}

- (void)pageScroll:(NSInteger)direction {
	if (![[resultController window] isVisible]) [self showResultView:self];
    
	NSInteger movement = direction * (NSHeight([[resultController.resultTable enclosingScrollView] frame]) /[resultController.resultTable rowHeight]);
	//NSLog(@"%d", movement);
	[self moveSelectionBy:movement];
}

- (void)moveSelectionBy:(NSInteger)d {
	[self selectIndex:selection+d];
}

- (void)selectHome:(id)sender {
	NSLog(@"act %@", allowNonActions ? @"YES" : @"NO");
	//	if (allowNonActions)
	//		[self setObjectValue:[QSObject fileObjectWithPath:NSHomeDirectory()]];
}

// Action that selects the root location in dObject/iObject views
- (void)selectRoot:(id)sender {
	if (allowNonActions)
		[self setObjectValue:[QSObject fileObjectWithPath:@"/"]];
}

- (void)scrollToBeginningOfDocument:(id)sender {
	[self selectIndex:0];
}

- (void)scrollToEndOfDocument:(id)sender {
	[self selectIndex:[self.resultArray count] -1];
}

- (BOOL)executeText:(NSEvent *)theEvent {
	[self clearSearch];
	[self insertText:[theEvent charactersIgnoringModifiers]];
    if ([[self objectValue] argumentCount] == 2) {
        [[self window] makeFirstResponder:[self indirectSelector]];
        // Invalidate the actionsUpdateTimer, otherwise it will fire and cause the default action to display (instead of that typed). actionsUpdateTimer gets set when the dObject loses 1st responder
        [[(QSInterfaceController *)[[self window] windowController] actionsUpdateTimer] invalidate];
    } else {
        [self insertNewline:self];
    }
	return YES;
}

#ifdef DEBUG
- (IBAction)logObjectDictionary:(id)sender {
	NSLog(@"Printing Object\r%@", [(QSObject *)[self objectValue] name]);
	NSLog(@"Dictionary\r%@", [[self objectValue] dictionaryRepresentation]);
	NSLog(@"Icon\r%@", [[self objectValue] icon]);    
}
#endif

- (void)transmogrifyWithText:(NSString *)string {
	if (![self allowText]) {
        NSBeep();
        return;
    }
	if ([self currentEditor]) {
		[[self window] makeFirstResponder: self];
	} else {
		if (string) {
			[[self textModeEditor] setString:string];
			[[self textModeEditor] setSelectedRange:NSMakeRange([string length], 0)];
		} else if ([partialString length] && ([resetTimer isValid] || ![[NSUserDefaults standardUserDefaults] floatForKey:kResetDelay]) ) {
            NSString *text;
            NSUInteger currentEventMask = NSEventMaskFromType([[NSApp currentEvent] type]);
            // getting characters raises an exception if this wasn't a key event
            if (currentEventMask & (NSKeyUpMask | NSKeyDownMask | NSFlagsChangedMask)) {
                text = [partialString stringByAppendingString:[[NSApp currentEvent] charactersIgnoringModifiers]];
            } else {
                text = partialString;
            }
			[[self textModeEditor] setString:text];
			[[self textModeEditor] setSelectedRange:NSMakeRange([text length], 0)];
		} else {
			NSString *stringValue = [[self objectValue] stringValue];
			if (stringValue) { 
                [[self textModeEditor] setString:stringValue];
                [[self textModeEditor] setSelectedRange:NSMakeRange(0, [stringValue length])];
            }
		}
		// Set the underlying object of the pane to be a text object
		[self setObjectValue:[QSObject objectWithString:[[[self textModeEditor] string] copy]]];
		
		NSRect titleFrame = [self frame];
		NSRect editorFrame = NSInsetRect(titleFrame, NSHeight(titleFrame) /16, NSHeight(titleFrame)/16);
		editorFrame.origin = NSMakePoint(NSHeight(titleFrame) /16, NSHeight(titleFrame)/16);
        editorFrame = NSIntegralRect(editorFrame);

        [[self textModeEditor] setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
        [[self textModeEditor] setFocusRingType:NSFocusRingTypeNone];        
        [[self textModeEditor] setDelegate: self];
        [[self textModeEditor] setAllowsUndo:YES];
        [[self textModeEditor] setHorizontallyResizable: YES];
        [[self textModeEditor] setVerticallyResizable: YES];
        [[self textModeEditor] setDrawsBackground: NO];
        [[self textModeEditor] setEditable:YES];
        [[self textModeEditor] setSelectable:YES];

        
		NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:editorFrame];
		[scrollView setBorderType:NSNoBorder];
		[scrollView setHasVerticalScroller:NO];
		[scrollView setAutohidesScrollers:YES];
		[scrollView setDrawsBackground:NO];
        
        NSSize contentSize = [scrollView contentSize];
        [[self textModeEditor] setMinSize:NSMakeSize(0, contentSize.height)];        
        [[self textModeEditor] setFont:textCellFont];
        
		[[self textModeEditor] setFieldEditor:YES];
        
        [scrollView setDocumentView:[self textModeEditor]];
		[self addSubview:scrollView];
        
        // Don't show the text being entered in the background, just the icon
        [[self cell] setImagePosition:NSImageOnly];
		[[self window] makeFirstResponder:[self textModeEditor]];
		[self setCurrentEditor:[self textModeEditor]];
	}
}

- (void)performSearch:(NSTimer *)timer {
	//NSLog(@"perform search, %d", self);
	if (validSearch) {
		[resultController.searchStringField setTextColor:[NSColor blackColor]];
		[resultController.searchStringField display];
		[self performSearchFor:partialString from:timer];
		[resultController.searchStringField display];
	}
	// NSLog(@"search performed");
}

	
- (void)performSearchFor:(NSString *)string from:(id)sender {
#ifdef DEBUG
	NSDate *date = [NSDate date];
#endif
	
    // ***Quicksilver's search algorithm is case insensitive
    string = [string lowercaseString];
    
	//	NSData *scores;
	NSMutableArray *newResultArray = [[QSLibrarian sharedInstance] scoredArrayForString:string inSet:self.searchArray];
	//t NSLog(@"scores %@", scores);
	
#ifdef DEBUG
    if (DEBUG_RANKING) NSLog(@"Searched for \"%@\" in %3fms (%lu items) ", string, 1000 * -[date timeIntervalSinceNow] , (unsigned long)[newResultArray count]);
#endif
	
    // NSLog (@"search for %@", string);
	//NSLog(@"%d valid", validSearch);
	if (validSearch = [newResultArray count] >0) {
		[self setMatchedString:string];
		//		[self setScoreData:scores];
		validMnemonic = YES;
		if ([self searchMode] == QSSearchModeAll || [self searchMode] == QSSearchModeFilter) {
			[self setResultArray:newResultArray];
            [self setSearchArray:newResultArray];
        }
		if ([self searchMode] == QSSearchModeAll) {
			// ! Don't search the entire catalog if we're in the aSelector (actions)
			if (![[self class] isEqual:[QSSearchObjectView class]]) {
			[parentStack removeAllObjects];
			}
		}
        
		if ([self searchMode] == QSSearchModeSnap) {
			[self selectObject:[newResultArray objectAtIndex:0]];
            
            [self reloadResultTable];
		} else if (0) { //if should retain the selection
            // [self selectObject:[newResultArray objectAtIndex:0]];
		} else {
			[self selectIndex:0];
		}
        
		NSInteger resultBehavior = [[NSUserDefaults standardUserDefaults] integerForKey:kResultWindowBehavior];
        
		if ([self.resultArray count] > 1) {
			if (resultBehavior == 0)
				[self showResultView:self];
			else if (resultBehavior == 1) {
				if ([resultTimer isValid]) {
					[resultTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:[[NSUserDefaults standardUserDefaults] floatForKey:kResetDelay]]];
				} else {
					resultTimer = [NSTimer scheduledTimerWithTimeInterval:[[NSUserDefaults standardUserDefaults] floatForKey:kResetDelay] target:self selector:@selector(showResultView:) userInfo:nil repeats:NO];
				}
			}
		}
	} else {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"QSTransformBadSearchToText"] && [self searchMode] == QSSearchModeAll) {
            // activate text mode if the prefs setting is set and QS is in the 'Search Catalog' mode
			[self transmogrifyWithText:partialString];
		} else { 
			NSBeep();
        }
        
		validMnemonic = NO;
		[resultController.searchStringField setTextColor:[NSColor redColor]];
	}
    
	// Extend Timers
	if ([searchTimer isValid]) {
		// NSLog(@"extend");
		[searchTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:[[NSUserDefaults standardUserDefaults] floatForKey:kSearchDelay]]];
        
	}
    
	if ([resetTimer isValid]) {
		CGFloat resetDelay = [[NSUserDefaults standardUserDefaults] floatForKey:kResetDelay];
		if (resetDelay) [resetTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:resetDelay]];
	}
    
}

- (void)resetString {
    QSGCDMainSync(^{
        [resultController.searchStringField setTextColor:[[resultController.searchStringField textColor] colorWithAlphaComponent:0.5]];
        [resultController.searchStringField display];
    });
}

- (void)partialStringChanged {
	[self setSearchString:[partialString copy]];
    
	double searchDelay = [[NSUserDefaults standardUserDefaults] floatForKey:kSearchDelay];
        
	if (![searchTimer isValid]) {
		searchTimer = [NSTimer scheduledTimerWithTimeInterval:searchDelay target:self selector:@selector(performSearch:) userInfo:nil repeats:NO];
	}
	[searchTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:searchDelay]];
	
	if ([self searchMode] != QSSearchModeAll) [searchTimer fire];
	if (validSearch) {
		[resultController.searchStringField setTextColor:[NSColor blueColor]];
	}
    
	[self setVisibleString:[partialString uppercaseString]];
    
	CGFloat resetDelay = [[NSUserDefaults standardUserDefaults] floatForKey:kResetDelay];
	if (resetDelay) {
		if ([resetTimer isValid]) {
			[resetTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:resetDelay]];
		} else {
			resetTimer = [NSTimer scheduledTimerWithTimeInterval:resetDelay target:self selector:@selector(resetString) userInfo:nil repeats:NO];
		}
	}
}

- (void)executeCommand:(id)sender {
	[resultTimer invalidate];
	if ([searchTimer isValid]) {
		[searchTimer invalidate];
		[self performSearchFor:partialString from:self];
		[self display];
	}
	[resetTimer fire];
	[[self controller] executeCommand:self];
}

- (NSFont *)textCellFont
{
    return textCellFont;
}

- (void)setTextCellFont:(NSFont *)newCellFont
{
    textCellFont = newCellFont;
}

- (NSColor *)textCellFontColor
{
    return textCellFontColor;
}

- (void)setTextCellFontColor:(NSColor *)newCellColor
{
    textCellFontColor = newCellColor;
}

#pragma mark -
#pragma mark NSResponder
- (BOOL)acceptsFirstResponder {
    if (self != [self directSelector] && [[self directSelector] objectValue] == nil) {
        // Don't let the aSelctor or iSelector gain focus if the dSelector is empty
        return NO;
    }
    return YES;
}

- (BOOL)becomeFirstResponder {
	if ([[[self objectValue] primaryType] isEqual:QSTextProxyType]) {
		NSString *defaultValue = [[self objectValue] objectForType:QSTextProxyType];
		[self transmogrify:self];
		//  NSLog(@"%@", [[self objectValue] dataDictionary]);
		if (defaultValue) {
			[self setObjectValue:[QSObject objectWithString:defaultValue]];
			[[self currentEditor] setString:defaultValue];
			if([[[[self actionSelector] objectValue] identifier] isEqualToString:@"FileRenameAction"]) {
				NSString *fileName = [defaultValue stringByDeletingPathExtension];
				[[self currentEditor] setSelectedRange:NSMakeRange(0, fileName.length)];
			} else {
			   [[self currentEditor] selectAll:self];
			}
		}
	}
	return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder {  
	[resultTimer invalidate];
	[self hideResultView:self];
	[self setShouldResetSearchString:YES];
	[self resetString];
	[self setNeedsDisplay:YES];
	return YES;
}

- (void)flagsChanged:(NSEvent *)theEvent {
    QSSearchObjectView *aSelector = [self actionSelector];
    [aSelector setUpdatesSilently:YES];
    NSUInteger flags = [theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
    // if only the command key is pressed
	if (flags == NSCommandKeyMask || flags == (NSCommandKeyMask | NSAlphaShiftKeyMask)) {
		// change the image
		QSAction *theAction = [aSelector objectValue];
		if (theAction && [theAction alternate]) {
            NSMutableArray *currentResultArray = [aSelector resultArray];
            if ([currentResultArray containsObject:[theAction alternate]]) {
                [aSelector selectObject:[theAction alternate]];
            } else {
                NSUInteger currentResultIndex = [currentResultArray indexOfObject:theAction];
                [currentResultArray removeObjectAtIndex:currentResultIndex];
                [currentResultArray insertObject:[theAction alternate] atIndex:currentResultIndex];
                [aSelector selectObject:[theAction alternate]];
                [[aSelector resultController] arrayChanged:nil];
            }
            [aSelector setNeedsDisplay:YES];
			[aSelector setAlternateActionCounterpart:theAction];
		}
	}
	else if ([aSelector alternateActionCounterpart]) {
        QSAction *theAction = [aSelector objectValue];
        NSMutableArray *currentResultArray = [aSelector resultArray];
        if ([currentResultArray containsObject:[aSelector alternateActionCounterpart]]) {
            [aSelector selectObject:[aSelector alternateActionCounterpart]];
        } else {
            NSUInteger currentResultIndex = [currentResultArray indexOfObject:theAction];
            [currentResultArray removeObjectAtIndex:currentResultIndex];
            [currentResultArray insertObject:[aSelector alternateActionCounterpart] atIndex:currentResultIndex];
            
            [[aSelector resultController] arrayChanged:nil];
            [aSelector selectObject:[aSelector alternateActionCounterpart]];
        }
        [aSelector setNeedsDisplay:YES];
        [aSelector setAlternateActionCounterpart:nil];
	}
    [aSelector setUpdatesSilently:NO];
}

// This method deals with all keydowns. Some very interesting things could be done by manipulating this method
- (void)keyDown:(NSEvent *)theEvent {
   
    [NSThread setThreadPriority:1.0];
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
	NSTimeInterval delay = [theEvent timestamp] -lastTime;
	//if (VERBOSE) NSLog(@"KeyD: %@\r%@", [theEvent characters] , theEvent);
	lastTime = [theEvent timestamp];
	lastProc = now;
	CGFloat resetDelay = [[NSUserDefaults standardUserDefaults] floatForKey:kResetDelay];
	if ((resetDelay && delay > resetDelay) || [self shouldResetSearchString]) {
		[partialString setString:@""];
		validSearch = YES;
		if ([self searchMode] == QSSearchModeAll) {
			[self setSourceArray:nil];
		}
		[self setShouldResetSearchString:NO];
	}
    
	// ***warning  * have downshift move to indirect object
	if ([[theEvent charactersIgnoringModifiers] isEqualToString:@"/"] && [self handleSlashEvent:theEvent])
        return;
	if (([[theEvent characters] isEqualToString:@"~"] || [[theEvent characters] isEqualToString:@"`"]) && [self handleTildeEvent:theEvent])
        return;
	if ([self handleBoundKey:theEvent])
        return;
    
	if ([[theEvent charactersIgnoringModifiers] isEqualToString:@" "]) {
        if ([theEvent type] == NSKeyDown) {
            [self insertSpace:nil];
        }
		return;
	}
    
	// ***warning  * have downshift move to indirect object
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"Shift Actions"]
        && [theEvent modifierFlags] &NSShiftKeyMask
        && ([[theEvent characters] length] >= 1)
        && [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[[theEvent characters] characterAtIndex:0]]
        && self == [self directSelector]) {
        // Don't try and change the action using shift keys if the dObject is empty
        if (![[self directSelector] objectValue]) {
            NSBeep();
            return;
        }
		[self handleShiftedKeyEvent:theEvent];
		return;
	}
	
    // check if the event is a keyboard shortcut to change the search mode 
	if ([self handleChangeSearchModeEvent:theEvent]) {
        return;
    }  
         
	if ([theEvent isARepeat] && !([theEvent modifierFlags] &NSFunctionKeyMask) )
        if ([self handleRepeaterEvent:theEvent]) return;
    
    
	//if (VERBOSE) NSLog(@"interpret");
	[self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
	return;
}

// Change the search mode if ⌘→ or ⌘← is pressed
- (BOOL)handleChangeSearchModeEvent:(NSEvent *)theEvent {
  
    if ([theEvent modifierFlags] &NSCommandKeyMask) {
        QSSearchMode aNewSearchMode;
        unichar aChar = [[theEvent characters] characterAtIndex:0];
        BOOL changeSearchModeRight;
        if (aChar == NSRightArrowFunctionKey) {
            changeSearchModeRight = YES;
        }
        else if (aChar == NSLeftArrowFunctionKey) {
            changeSearchModeRight = NO;
        }
        else {
            return NO;
        }
        
        // Set the new search mode depending on the direction:
        // Filter All → Filter → Snap to Best (left gives reverse direction)
        switch (searchMode) {
            case QSSearchModeAll:
                aNewSearchMode = changeSearchModeRight ? QSSearchModeFilter : QSSearchModeSnap;
                break;
            case QSSearchModeFilter:
                aNewSearchMode = changeSearchModeRight ? QSSearchModeSnap : QSSearchModeAll;
                break;
            case QSSearchModeSnap:
                aNewSearchMode = changeSearchModeRight ? QSSearchModeAll : QSSearchModeFilter;
                break;
        }
        [self setSearchMode:aNewSearchMode];
        return YES;
    }
    
    return NO;
}

- (BOOL)handleShiftedKeyEvent:(NSEvent *)theEvent {
	if ([[resultController window] isVisible]) {
		[self hideResultView:self];
		[self setShouldResetSearchString:YES];
	} else {
		[resultTimer invalidate];
	}
    
    [[self actionSelector] setShouldResetSearchString:NO];
    [[self window] makeFirstResponder:[self actionSelector]];
	// ***warning  * toggle first responder on key up
    
	[[self controller] fireActionUpdateTimer];
    NSString *text = [theEvent charactersIgnoringModifiers];
    if ([text isEqualToString:@" "]) {
        NSInteger behavior = [[NSUserDefaults standardUserDefaults] integerForKey:@"QSSearchSpaceBarBehavior"];
        // only attempting to insert a space into the aSelector makes sense when using shifted keys.
        // If anything but this is set as the default, then beep and say that the event *was* handled succesfully (eventhough it failed)
        if (behavior != 1) {
            NSBeep();
            return YES;
        }
    }
    [[self actionSelector] insertText:text];
	return YES;
}

// Deals with the forward slash ('/') being used to drill down and also direct to root
// Called when the key is either pressed or depressed
- (BOOL)handleSlashEvent:(NSEvent *)theEvent {
	if ([theEvent isARepeat]) return YES;
	if (!allowNonActions) return YES;
	
	NSEvent *upEvent = [NSApp nextEventMatchingMask:NSKeyUpMask untilDate:[NSDate dateWithTimeIntervalSinceNow:0.5] inMode:NSDefaultRunLoopMode dequeue:YES];
	
	if (upEvent) {
		[self moveRight:self];
	// If '/' is still held down (i.e. no key up in the 0.5s passed), go to root
	} else {
		[self setObjectValue:[QSObject fileObjectWithPath:@"/"]];
	}
    
	return YES;
}

- (BOOL)handleTildeEvent:(NSEvent *)theEvent {
	if ([theEvent isARepeat]) return YES;
	if (!allowNonActions) return YES;
	[self setObjectValue:[QSObject fileObjectWithPath:NSHomeDirectory()]];
    
	NSEvent *upEvent = [NSApp nextEventMatchingMask:NSKeyUpMask untilDate:[NSDate dateWithTimeIntervalSinceNow:0.25] inMode:NSDefaultRunLoopMode dequeue:YES];
	if (!upEvent)
		[self moveRight:self];
	return YES;
}

- (BOOL)handleRepeaterEvent:(NSEvent *)theEvent {
	//if (VERBOSE) NSLog(@"repeater");
	[resultTimer invalidate];
    
	NSDictionary *mnemonics = [[QSMnemonics sharedInstance] objectMnemonicsForID:[[self objectValue] identifier]];
	if (![mnemonics objectForKey:partialString]) {
		//qu	NSLog(@"delaying before execution %@ %@", mnemonics, partialString);
        
		NSEvent *keyUp = [NSApp nextEventMatchingMask:NSKeyUpMask untilDate:[NSDate dateWithTimeIntervalSinceNow:2.0] inMode:NSDefaultRunLoopMode dequeue:YES];
		if (keyUp) {
			[NSApp discardEventsMatchingMask:NSKeyDownMask beforeEvent:keyUp];
			return YES;
		}
	}
    
	[[self window] makeFirstResponder:[self window]];
    
	[self insertNewline:self];
    
	NSEvent *nextEvent;
	NSDate *absorbDate = [NSDate dateWithTimeIntervalSinceNow:0.5];
    
    
	if (nextEvent = [NSApp nextEventMatchingMask:NSKeyUpMask untilDate:absorbDate inMode:NSDefaultRunLoopMode dequeue:NO]) {
#ifdef DEBUG
		if (VERBOSE) 	NSLog(@"discarding events till %@", nextEvent);
#endif
		[NSApp discardEventsMatchingMask:NSAnyEventMask beforeEvent:nextEvent];
        
	}
	return YES;
}

- (BOOL)handleBoundKey:(NSEvent *)theEvent {
    NSString *theEventString = [[NDKeyboardLayout keyboardLayout] stringForKeyCode:[theEvent keyCode] modifierFlags:[theEvent modifierFlags]];
	NSString *selectorString = [bindingsDict objectForKey:theEventString];
    
	if (selectorString) {
		SEL selector = NSSelectorFromString(selectorString);
		[self doCommandBySelector:selector];
		return YES;
	}
	return NO;
}

- (void)mouseDown:(NSEvent *)theEvent {
	if ([theEvent clickCount] > 1) {
		[(QSInterfaceController *)[[self window] windowController] executeCommand:self];
	} else {
		[super mouseDown:theEvent];
	}
}

/*- (void)mouseDown:(NSEvent *)theEvent {
    BOOL keepOn = YES;
    BOOL isInside = YES;
    NSPoint mouseLoc;
    
    theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask |
                NSLeftMouseDraggedMask];
    mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    isInside = [self mouse:mouseLoc inRect:[self bounds]];
    
    switch ([theEvent type]) {
        case NSLeftMouseDragged:
            
            [self hideResultView:self];
            [super mouseDragged:theEvent];
            break;
        case NSLeftMouseUp:
            //if (isInside)
            NSLog(@"mouseUp");
            [self toggleResultView:self];
            = NO;
            break;
        default:
            
            break;
    }
    
    
    return;
}*/

- (void)scrollWheel:(NSEvent *)theEvent {
	// ***warning  * this still goes to the wrong view if over another search view
    if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible]) {
        return;
    }
	if (![[resultController window] isVisible]) {
		[self showResultView:self];
	}
    
	if (NSMouseInRect([NSEvent mouseLocation] , NSInsetRect([[resultController window] frame] , 0, 0), NO) ) {
		// FIXME: This stack-smashes because AppKit tries to forward through the responder chain
//		[resultController scrollWheel:theEvent];
		return;
	}
	CGFloat delta = [theEvent deltaY];
    
	// This is really really awful.
	UnsignedWide currentTime;
	double currentTimeDouble = 0;
	Microseconds(&currentTime);
	currentTimeDouble = (((double) currentTime.hi) * 4294967296.0) + currentTime.lo;
    
	//If the scroll event is really delayed (Nonactivating panels cause this) then ignore
	if (currentTimeDouble/1000000-[theEvent timestamp] >0.25) return;
    
	while (theEvent = [NSApp nextEventMatchingMask: NSScrollWheelMask untilDate:[NSDate date] inMode:NSDefaultRunLoopMode dequeue:YES]) {
		delta += [theEvent deltaY];
	}
    
	[self moveSelectionBy:-(NSInteger) delta];
	// [resultController->resultTable scrollWheel:theEvent];
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent {
    if (![[self directSelector] objectValue]) {
        return NO;
    }
	if ([[theEvent charactersIgnoringModifiers] isEqualToString:@"\r"] && ([theEvent modifierFlags] & NSCommandKeyMask) > 0) {
		[self insertNewline:nil];
		return YES;
	}
	BOOL higher = [[self controller] performKeyEquivalent:theEvent];
	if ([[self window] firstResponder] == self && !higher) {
		if ([self handleBoundKey:theEvent]) return YES;
	}
	return higher;
}

#pragma mark -
#pragma mark QSSearchObjectView Key Bindings
- (IBAction)conditionalTransmogrify:(id)sender {
	if (![partialString length]) [self transmogrify:sender];
}

- (IBAction)calculate:(id)sender {
	[self transmogrify:self];
	[[self currentEditor] setString:@"="];
}

- (IBAction)shortCircuit:(id)sender {
	[self updateHistory];
	[self saveMnemonic];
	[[self controller] shortCircuit:self];
	[resultTimer invalidate];
}

- (void)insertSpace:(id)sender
{
	NSInteger behavior = [[NSUserDefaults standardUserDefaults] integerForKey:@"QSSearchSpaceBarBehavior"];

    QSObject *newSelectedObject = [[super objectValue] resolvedObject];
    QSAction *action = [[self actionSelector] objectValue];
    if (behavior == 7) {
        // override smart defaults with type-specific behavior (if defined)
        NSNumber *typeBehavior = [[[QSReg tableNamed:@"QSTypeDefinitions"] objectForKey:[newSelectedObject primaryType]] objectForKey:kQSSmartSpace];
        if (typeBehavior) {
            behavior = [typeBehavior integerValue];
        }
    }

	switch(behavior) {
		case 1: //Normal
			[self insertText:@" "];
			break;
		case 2: //Select next result
			if ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask)
				[self moveUp:sender];
			else
				[self moveDown:sender];
			break;
		case 3: //Jump to Indirect
			[self shortCircuit:sender];
			break;
		case 4: //Switch to text
			[self transmogrify:sender];
			break;
		case 5: //Show child contents/
			if ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask)
				[self moveLeft:sender];
			else
				[self moveRight:sender];
            break;
        case 6: // Show Quicklook window
            [self togglePreviewPanel:nil];
			break;

        case 7: // Smart Context Specific behavior based on object

            // if we are in the second pane, trigger first action that involves third pane and go there
            if (self == [self actionSelector])
            {
                [self shortCircuit:sender];
            }
            // go to parent if one exists
            else if ([[NSApp currentEvent] modifierFlags] & NSShiftKeyMask)
            {
                [self moveLeft:sender];
            }
            // Show child contents but only if object isn't a URL or text file
            else if ([newSelectedObject hasChildren] &&
                    !QSTypeConformsTo([newSelectedObject fileUTI], (__bridge NSString *)kUTTypePlainText))
            {
                [self moveRight:sender];
            }
            // If we aren't in the third pane then jump to Indirect if action requires more then one argument (ie. search URL)
            else if (self != [self indirectSelector] &&
                    (action &&
                    [action respondsToSelector:@selector(argumentCount)] &&
                    [action argumentCount] == 2))
            {
                [self shortCircuit:sender];
            }
            // Show Quicklook window
            else if ([self canQuicklookCurrentObject])
            {
                [self togglePreviewPanel:nil];
            }
            // Switch to text
            else
            {
                [self transmogrify:sender];
            }

            break;
	}
}

- (IBAction)transmogrify:(id)sender {
	[self transmogrifyWithText:nil];
}

- (IBAction)changeSearchOrder:(id)sender {
	switch ([sender tag]) {
		case QSSearchOrderByName:
			[(NSMutableArray *)[self resultArray] sortUsingSelector:@selector(nameCompare:)];
			break;

		default:
		case QSSearchOrderByScore:
			[(NSMutableArray *)[self resultArray] sortUsingSelector:@selector(scoreCompare:)];
			break;

		case QSSearchOrderByModDate:
			[(NSMutableArray *)[self resultArray] sortUsingSelector:@selector(modDateCompare:)];
			break;
	}
	[self reloadResultTable];
}

- (IBAction)grabSelection:(id)sender {
	if (!allowNonActions) return;
	QSObject *newSelection = [self externalSelection];
    
	[self redisplayObjectValue:newSelection];
}

- (IBAction)dropSelection:(id)sender {
	if (!allowNonActions) return;
	QSObject *newSelection = [self externalSelection];
	[self dropObject:newSelection];
}

- (IBAction)dropClipboard:(id)sender {
	if (!allowNonActions) return;
	QSObject *newSelection = [QSObject objectWithPasteboard:[NSPasteboard generalPasteboard]];
	[self dropObject:newSelection];
}

#pragma mark -
#pragma mark NSResponder Key Bindings
- (void)deleteBackward:(id)sender {
    if(defaultBool(kDoubleDeleteClearsObject) && [self matchedString] == nil) {
		historyIndex = -1;
        [super delete:sender];
    } else {
        [self clearSearch];
    }
}

- (void)pageUp:(id)sender {[self pageScroll:-1];}
- (void)pageDown:(id)sender {[self pageScroll:1];}
- (void)scrollPageUp:(id)sender {[self pageScroll:-1];}
- (void)scrollPageDown:(id)sender {[self pageScroll:1];}

- (void)moveDown:(id)sender {
	if (![[resultController window] isVisible]) [self showResultView:self];
	[self moveSelectionBy:1];
}

- (void)moveUp:(id)sender {
	if (![[resultController window] isVisible]) [self showResultView:self];
	[self moveSelectionBy:-1];
}

- (void)complete:(id)sender {
	[self cancelOperation:sender];
}

- (void)performClose:(id)sender {
	[self cancelOperation:sender];
}

- (void)reset:(id)sender {
	if ([[resultController window] isVisible]) {
		[self hideResultView:self];
	}
	if (browsing) {
		browsing = NO;
		[self setSearchMode:QSSearchModeAll];
	}
	[self setShouldResetSearchString:YES];
	[resultTimer invalidate];
}

- (void)cancelOperation:(id)sender {
	if ([self currentEditor]) {
		[[self window] makeFirstResponder:self];
		return;
	} else if ([[resultController window] isVisible]) {
		[self hideResultView:self];
		[self setShouldResetSearchString:YES];
	} else {
		[resultTimer invalidate];
		[[[self window] windowController] hideMainWindowFromCancel:self];
	}
	return;
}

- (void)selectAll:(id)sender {
	[self redisplayObjectValue:[QSObject objectByMergingObjects:self.resultArray]];
}

- (void)insertTab:(id)sender {
	[resultTimer invalidate];
	[[self window] selectNextKeyView:self];
}

- (void)insertBacktab:(id)sender {
	[resultTimer invalidate];
	[[self window] selectPreviousKeyView:self];
}

- (void)insertNewlineIgnoringFieldEditor:(id)sender {
	[self insertNewline:sender];
}

- (void)insertNewline:(id)sender {
	[self executeCommand:sender];
}

#pragma mark -
#pragma mark NSTextView Delegate
- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
	if (commandSelector == @selector(insertTab:) ) {
		[[self window] selectKeyViewFollowingView:self];
		return YES;
	}
	if (commandSelector == @selector(insertBacktab:) ) {
		[[self window] selectKeyViewPrecedingView:self];
		return YES;
	}
	if (commandSelector == @selector(insertNewline:) ) {
		[[self window] makeFirstResponder:self];
		[[[self window] windowController] executeCommand:self];
		return YES;
	}
	if (commandSelector == @selector(complete:) ) {
		[[self window] makeFirstResponder:self];
		return YES;
	}
	return NO;
}

- (void)textDidChange:(NSNotification *)aNotification {
    NSString *string = [[aNotification object] string];
	if ([string isEqualToString:@" "]) {
        [self shortCircuit:self];
		return;
	}
	[self setObjectValue:[QSObject objectWithString:string]];
	[self setMatchedString:nil];
}

- (void)textDidEndEditing:(NSNotification *)aNotification {
    NSString *string = [[[aNotification object] string] copy];
    if (![string isEqualToString:@" "]) {
        // only set the object value if it's not a 'short circuit'
        [self setObjectValue:[QSObject objectWithString:string]];
    }
	[self setMatchedString:nil];
	[[[self currentEditor] enclosingScrollView] removeFromSuperview];
    [[self cell] setImagePosition:-1];
	[self setCurrentEditor:nil];
}

#pragma mark -
#pragma mark NSTextInput Protocol
- (void)insertText:(id)aString {
    [self insertText:aString replacementRange:NSMakeRange(0,0)];
}
- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange {
	if (![partialString length]) {
		historyIndex = -1;
		[self setSearchArray:self.sourceArray];
	}
	[partialString appendString:aString];
	[self partialStringChanged];
}

- (void)doCommandBySelector:(SEL)aSelector {
#ifdef DEBUG
	if (VERBOSE && ![self respondsToSelector:aSelector])
		NSLog(@"Unhandled Command: %@", NSStringFromSelector(aSelector) );
#endif
	[super doCommandBySelector:aSelector];
}

- (void)setMarkedText:(id)aString selectedRange:(NSRange)selRange {
    [self setMarkedText:aString selectedRange:selRange replacementRange:NSMakeRange(0, 0)];
}

- (void)setMarkedText:(id)aString selectedRange:(NSRange)selectedRange replacementRange:(NSRange)replacementRange {}

- (void)unmarkText {}
- (BOOL)hasMarkedText { return NO; }
- (NSInteger)conversationIdentifier { return (long)self; }

- (NSAttributedString *)attributedSubstringFromRange:(NSRange)theRange {
	return [self attributedSubstringForProposedRange:theRange actualRange:NULL];
}

- (NSAttributedString *)attributedSubstringForProposedRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange {
    return nil;
}

- (NSRange)markedRange { return NSMakeRange([partialString length] -1, 1); }
- (NSRange)selectedRange { return NSMakeRange(NSNotFound, 0); }

- (NSRect)firstRectForCharacterRange:(NSRange)theRange {
    return [self firstRectForCharacterRange:theRange actualRange:NULL];
}

- (NSRect)firstRectForCharacterRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange { return NSZeroRect; }

- (NSUInteger)characterIndexForPoint:(NSPoint)thePoint { return 0; }

- (NSArray *)validAttributesForMarkedText {
	return [NSArray array];
}

#pragma mark Drag and Drop

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
{
	[self updateHistory];
	[self saveMnemonic];
	[super draggedImage:anImage endedAt:aPoint operation:operation];
}
@end

#pragma mark History
@implementation QSSearchObjectView (History)
- (void)showHistoryObjects {
	NSMutableArray *array = [historyArray valueForKey:@"selection"];
	[[self controller] showArray:array];
}

- (NSDictionary *)historyState {
	QSObject *currentValue = [self objectValue];
	if (!currentValue) return nil;
	NSMutableDictionary *state = [NSMutableDictionary dictionary];
	[state setObject:currentValue forKey:@"selection"];
	if (self.resultArray) [state setObject:self.resultArray forKey:@"resultArray"];
	if (self.sourceArray) [state setObject:self.sourceArray forKey:@"sourceArray"];
	if (visibleString) [state setObject:visibleString forKey:@"visibleString"];
	return state;
}

- (void)setHistoryState:(NSDictionary *)state {
	[self setSourceArray:[state objectForKey:@"sourceArray"]];
	[self setResultArray:[state objectForKey:@"resultArray"]];
	[self setVisibleString:[state objectForKey:@"visibleString"]];
	[self setMatchedString:[state objectForKey:@"visibleString"]];
	[self redisplayObjectValue:[state objectForKey:@"selection"]];
}


//- (id)nextHistoryState {
//	NSLog(@"select in history %d %@", historyIndex, [historyArray valueForKeyPath:@"selection.displayName"]);
//	if ([historyArray count])
//		return [historyArray objectAtIndex:0];
//	return nil;
//}
- (void)switchToHistoryState:(NSInteger)i {
#ifdef DEBUG
	if (VERBOSE) NSLog(@"select in history %ld %@", (long)i, [historyArray valueForKeyPath:@"selection.displayName"]);
#endif
	if (i<(NSInteger)[(NSArray *)historyArray count])
		[self setHistoryState:[historyArray objectAtIndex:i]];
}
- (void)clearHistory {
	[historyArray removeAllObjects];
	historyIndex = 0;
}

- (void)updateHistory {
	if (!self.recordsHistory) return;
	
    id objectValue = [self objectValue];
	// add synonyms to recent objects untouched, split/resolve everything else
	QSObject *lastObjectValue = [objectValue isProxyObject] && [objectValue objectForMeta:@"target"] ? objectValue : [[objectValue splitObjects] lastObject];
	if (lastObjectValue) {
       [QSHist addObject:lastObjectValue];
    }
	
    NSDictionary *state = [self historyState];

    historyIndex = 0;
	if (state) {
		// if object is already in history, make it most recent
		NSIndexSet *present = [historyArray indexesOfObjectsPassingTest:^BOOL(NSDictionary *historyObject, NSUInteger idx, BOOL *stop) {
			return ([objectValue isEqual:[historyObject objectForKey:@"selection"]]);
		}];
		[historyArray removeObjectsAtIndexes:present];
		[historyArray insertObject:state atIndex:0];
	}

	if ([historyArray count] >MAX_HISTORY_COUNT) [historyArray removeLastObject];
//	if (VERBOSE) NSLog(@"history %d items", [historyArray count]);
}

- (void)goForward:(id)sender {
#ifdef DEBUG
	if (VERBOSE) NSLog(@"goForward");
#endif
	if (historyIndex>0) {
		[self switchToHistoryState:--historyIndex];
	} else {
		[resultController bump:(4)];
	}
}
- (void)goBackward:(id)sender {
#ifdef DEBUG
	if (VERBOSE) NSLog(@"goBackward");
#endif
    
	if (historyIndex+1<(NSInteger)[historyArray count]) {
		[self switchToHistoryState:++historyIndex];
	} else {
		[resultController bump:(-4)];
	}
}

- (BOOL)objectIsInCollection:(QSObject *)thisObject {
	return NO;
}

- (void)explodeCombinedObject
{
	return;
}

@end


@implementation QSSearchObjectView (Browsing)
- (void)moveWordRight:(id)sender {
	[self browse:1];

}
- (void)moveWordLeft:(id)sender {
	[self browse:-1];

}
- (void)moveRight:(id)sender {
	[self updateHistory];
	[self saveMnemonic];
	[self browse:1];
}
- (void)moveLeft:(id)sender {
	[self browse:-1];
}

- (void)browse:(NSInteger)direction {
    NSArray *newObjects = nil;
	QSObject * newSelectedObject = [super objectValue];
    QSObject * parent = nil;

    BOOL alt = ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) > 0;


    if (direction>0 && ([newSelectedObject hasChildren] || alt)) {
        //Should show childrenLevel
        newObjects = (alt ? [newSelectedObject altChildren] : [newSelectedObject children]);
        if ([newObjects count] && !alt) {
            // filter the results to only contain types as defined in the indirectTypes .plist array.
            // If the user is holding alt, don't filter
            if (self == [self indirectSelector] && [[[self actionSelector] objectValue] indirectTypes]) {
                NSArray *indirectTypes = [[[self actionSelector] objectValue] indirectTypes];
                NSIndexSet *filteredIndexes = [newObjects indexesOfObjectsPassingTest:^BOOL(QSObject *individual, NSUInteger idx, BOOL *stop) {
                    // check the UTI for files
                    if (![individual singleFilePath]) {
                        return NO;
                    }
                    // resolve alias objects
                    individual = [individual resolvedAliasObject];
                    NSString *type = [individual fileUTI];
                    for (NSString *indirectType in indirectTypes) {
                        // if the file type is a folder (Always show them) or it conforms to a set indirectType
                        if ([type isEqualToString:(NSString *)kUTTypeFolder] || UTTypeConformsTo((__bridge CFStringRef)type, (__bridge CFStringRef)indirectType)) {
                            return YES;
                        }
                        // for QSTypes set in the indirectType
                        if ([[individual types] containsObject:indirectType]) {
                            return YES;
                        }
                    }

                    return NO;
                }];
                newObjects = [newObjects objectsAtIndexes:filteredIndexes];
            }
        }
        if ([newObjects count]) {
            [parentStack addObject:newSelectedObject];
        }
        newSelectedObject = nil;
    } else if (direction < 0 ) {
        if ([parentStack count] && !alt) {
            browsing = YES;
            parent = [parentStack lastObject];
            [parentStack removeLastObject];
        } else {
            parent = [newSelectedObject parent];
        }
                
        // should show parent's level
        newSelectedObject = parent;
        if (newSelectedObject) {
            if ((NSInteger)[historyArray count] > historyIndex + 1) {
                if ([[[historyArray objectAtIndex:historyIndex+1] valueForKey:@"selection"] isEqual:parent]) {
                    [historyArray removeObjectAtIndex:historyIndex+1];
                }
#ifdef DEBUG
                if (VERBOSE) NSLog(@"Parent Missing, No History, %@", [[historyArray objectAtIndex:0] valueForKey:@"selection"]);
#endif
            }
            
            if (!newObjects)
                newObjects = (alt ? [newSelectedObject altSiblings] : [newSelectedObject siblings]);
            if (![newObjects containsObject:newSelectedObject])
                newObjects = [newSelectedObject altSiblings];
            
            if (!newObjects && [parentStack count]) {
                parent = [parentStack lastObject];
                newObjects = [parent children];
            }
            
            if (!newObjects && [historyArray count]) {
                if ([[[historyArray objectAtIndex:0] valueForKey:@"selection"] isEqual:parent]) {
#ifdef DEBUG
                    if (VERBOSE) NSLog(@"Parent Missing, Using History");
#endif
                    
                    [self goBackward:self];
                    return;
                }
#ifdef DEBUG
                if (VERBOSE) NSLog(@"Parent Missing, No History");
#endif
                
            }
        }
    }
    
    if ([newObjects count]) {
        browsing = YES;
        
        [self clearSearch];
		historyIndex = -1;
        NSInteger defaultMode = [[NSUserDefaults standardUserDefaults] integerForKey:kBrowseMode];
        [self setSearchMode:(defaultMode ? defaultMode : QSSearchModeFilter)];
        [self setResultArray:[newObjects mutableCopy]];
        [self setSourceArray:newObjects];
        
        if (!newSelectedObject)
            [self selectIndex:0];
        else
            [self selectObject:newSelectedObject];
        
        [self setVisibleString:@"Browsing"];
        
        [self showResultView:self];
        return;
        
    }
    
    if (![[NSApp currentEvent] isARepeat]) {
        
        [self showResultView:self];
        if ([[resultController window] isVisible])
            [resultController bump:(direction*4)];
        else
            NSBeep();
    }
}


@end

#pragma mark Quicklook support

@implementation QSSearchObjectView (Quicklook)


- (BOOL)canQuicklookCurrentObject {
    id object = [self objectValue];
    // resolve ranked objects
    if ([object isKindOfClass:[QSRankedObject class]]) {
        object = [(QSRankedObject *)object object];
    }
    // resolve proxy objects
    object = [object resolvedObject];
    
    if ([object validPaths] || [[object primaryType] isEqualToString:QSURLType]) {
        quicklookObject = object;
        savedSearchMode = searchMode;
        return YES;
    }
    return NO;
}

- (void)closePreviewPanel {
    [[QLPreviewPanel sharedPreviewPanel] orderOut:nil];
    quicklookObject = nil;
    searchMode = savedSearchMode;
}


- (IBAction)togglePreviewPanel:(id)previewPanel {
    if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible]) {
        [self closePreviewPanel];
    } else {
       if ([self canQuicklookCurrentObject]) {
            [NSApp activateIgnoringOtherApps:YES];
            // makeKeyAndOrderFront closes the QS interface. This way, the interface stays open behind the preview panel
            [[QLPreviewPanel sharedPreviewPanel] orderFront:nil];
            [[QLPreviewPanel sharedPreviewPanel] makeKeyWindow];
            [self updateHistory];
            [self saveMnemonic];
        }
        else {
            NSBeep();
        }
    }
}

- (IBAction)togglePreviewPanelFullScreen:(id)previewPanel {
    if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isInFullScreenMode]) {
        [self closePreviewPanel];
    } else {
        if ([self canQuicklookCurrentObject]) {
            [NSApp activateIgnoringOtherApps:YES];
            [[QLPreviewPanel sharedPreviewPanel] enterFullScreenMode:nil withOptions:nil];
        }
        else {
            NSBeep();
        }
    }
}


#pragma mark QLPReviewPanel delegate methods


- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel {
    return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel {
    // This document is now responsible of the preview panel
    // It is allowed to set the delegate, data source and refresh panel.
    previewPanel = panel;
    [panel setDelegate:self];
    [panel setDataSource:self];
    // Put the panel just above Quicksilver's window
    [previewPanel setLevel:([[self window] level] + 2)];
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel {
    // This document loses its responsisibility on the preview panel
    // Until the next call to -beginPreviewPanelControl: it must not
    // change the panel's delegate, data source or refresh it.
    previewPanel = nil;
}

// Quick Look panel data source

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel {
    if (quicklookObject) {
        return [quicklookObject count];
    }
    return 0;
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index {
    if (quicklookObject) {
        return [[quicklookObject splitObjects] objectAtIndex:index];
    }
    return nil;
}

// Quick Look panel delegate

- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event {
    if ([event type]  != NSKeyDown) {
        return NO;
    }
    NSString *key = [event charactersIgnoringModifiers];
    NSUInteger eventModifierFlags = [event modifierFlags];
       if ([key isEqual:@"y"] && eventModifierFlags & NSCommandKeyMask) {
        if (eventModifierFlags & NSAlternateKeyMask) {
            // Cmd + Optn + Y shortcut (full screen)
            [self togglePreviewPanelFullScreen:nil];
        } else {
            // Cmd + Y shortcut (small quicklook panel)
            [self togglePreviewPanel:nil];
        }
        return YES;
    }
    // Allow the default action to be executed (if CMD+ENTR or ENTR is pressed)
    if ([key isEqualToString:@"\r"] && (eventModifierFlags & NSCommandKeyMask || ((eventModifierFlags & NSDeviceIndependentModifierFlagsMask) == 0))) {
        // close the preview panel first to avoid any quirkiness
        [[QLPreviewPanel sharedPreviewPanel] close];
        [self closePreviewPanel];
        if (eventModifierFlags & NSCommandKeyMask) {
            [self insertNewline:nil];
        } else {
            [self interpretKeyEvents:[NSArray arrayWithObject:event]];
        }
        return YES;
    }
    
    // trap the 'delete' key from being pressed
    if ([key length] && [key characterAtIndex:0] == NSDeleteCharacter ) {
        return YES;
    }
    return NO;
}

// defines the image which is used during the zoom process
- (NSImage *)previewPanel:(QLPreviewPanel *)panel transitionImageForPreviewItem:(id <QLPreviewItem>)item contentRect:(NSRect *)contentRect {
    NSImage *iconImage = [(QSObject *)item icon];
    return iconImage;
}

// This delegate method provides the rect on screen from which the panel will zoom.
- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item {
    
    // get the location of the icon in the interface. This is a tricky process since all interfaces are different.
    // Basic method: get the 1st pane/3rd pane rect, from within this rect, get the image rect where the image is placed
    // then get the image size, and offset the based on the image size (typically smaller than the image rect, but not always the case - Primer)
    NSRect rect = [self bounds];
    rect = [[self cell] drawingRectForBounds:rect];
	rect = NSIntegralRect(fitRectInRect(NSMakeRect(0, 0, 1, 1), [[self cell] imageRectForBounds:rect] , NO) );
    rect.origin.y += self.frame.origin.y;
    rect.origin.x += self.frame.origin.x;
    return [[self window] convertRectToScreen:rect];
;
}

@end
