//
//  QSSearchController.m
//  QSCubeInterfaceElement
//
//  Created by Nicholas Jitkoff on 6/25/07.
//  Copyright 2007 Google Inc. All rights reserved.
//

#import "QSSearchController.h"
#import "QSCatalogSearchProvider.h"
#import "QSSpotlightSearchProvider.h"

@implementation QSSearchController
@synthesize searchText, resultArray, sourceArray, searchType, matchedString, objectValue;

- (void)awakeFromNib {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sourceArrayChanged:) name:@"QSSourceArrayUpdated" object:nil];

  qsSearch = [[QSCatalogSearchProvider alloc] init];
  spotSearch = [[QSSpotlightSearchProvider alloc] init];
//  [self bind:@"objectValue"
//    toObject:resultArrayController
// withKeyPath:@"selectedObjects" options:nil];
//  
  [resultArrayController addObserver:self 
                          forKeyPath:@"selection"
                             options:0
                             context:nil];
  

}
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  [self setObjectValue:[[resultArrayController selectedObjects] lastObject]];
}


//- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
//  NSLog(@"begin %@", fieldEditor);
//  return YES;
//}
//- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
//  NSLog(@"end %@", fieldEditor);
//  return YES;
//}
- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector {
  
  [self willChangeValueForKey:@"test"];
  [self didChangeValueForKey:@"test"];
//  return YES;
  BOOL retval = NO;
  if ([self respondsToSelector:commandSelector]) {
    [self performSelector:commandSelector withObject:nil];
    retval = YES;
  }
  return retval;
}

- (IBAction)selectSearchType:(id)sender {
  self.searchType = [sender title];
}
- (void)setSearchType:(NSString *)aSearchType {
  
  NSImage *icon = [[NSImage imageNamed:aSearchType] duplicateOfSize:QSSize16];
  [[[searchField cell] searchButtonCell] setImage:icon];
  if (searchType != aSearchType) {
      [searchType release];
      searchType = [aSearchType retain];
      }
}


- (void)controlTextDidChange:(NSNotification *)aNotification {
  self.searchText =  [[aNotification object] stringValue];
  
  if ([self.searchType isEqualToString:@"Spotlight"]) {
    spotSearch.searchText = self.searchText;
    [spotSearch startSearch];
    self.resultArray = spotSearch.resultArray;
    NSLog(@"spotsearch");
  } else if ([self.searchType isEqualToString:@"Refine"]) {
    qsSearch.sourceArray = self.sourceArray.copy;
    [qsSearch performSearchFor:self.searchText from:nil];
    [resultArrayController setSelectedObjects:nil];
    
    self.resultArray = qsSearch.resultArray;
  } else {
    [qsSearch performSearchFor:self.searchText from:nil];
    [resultArrayController setSelectedObjects:nil];
    
    self.resultArray = qsSearch.resultArray;
  }

}


//- (id)objectValue {
//  return [[resultArrayController selectedObjects] lastObject]; 
//}
//

//#define pUserKeyBindingsPath QSApplicationSupportSubPath(@"KeyBindings.qskeys", NO)
//#define MAX_HISTORY_COUNT 20
//
//NSMutableDictionary *bindingsDict = nil;
//
//@implementation QSSearchObjectView
//+(void)initialize {
//	bindingsDict = [[[NSMutableDictionary alloc] initWithContentsOfFile:
//                   [[NSBundle bundleForClass:[QSSearchObjectView class]]pathForResource:@"DefaultBindings" ofType:@"qskeys"]]objectForKey:@"QSSearchObjectView"];
//	
//	NSDictionary *mods = [[NSDictionary dictionaryWithContentsOfFile:pUserKeyBindingsPath] objectForKey:@"QSSearchObjectView"];
//	[bindingsDict addEntriesFromDictionary:mods];
//	
//}
//- (void)awakeFromNib {
//	[super awakeFromNib];
//	resetTimer = nil;
//	searchTimer = nil;
//	resultTimer = nil;
//	preferredEdge = NSMaxXEdge;
//	partialString = [[NSMutableString alloc] initWithCapacity:1];
//	[partialString setString:@""];
//	
//	matchedString = nil;
//	
//	sourceArray = nil;
//	searchArray = nil;
//	resultArray = nil;
//	recordsHistory = YES;
//	shouldResetSearchArray = YES;
//	allowNonActions = YES;
//	allowText = YES;
//	resultController = [[QSResultController alloc] initWithFocus:self];
//	
//	searchMode = SearchFilterAll;
//	moreComing = NO;
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideResultView:) name:@"NSWindowDidResignKeyNotification" object:[self window]];
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearAll) name:QSReleaseAllNotification object:nil];
//	
//	
//	defaults = [[NSUserDefaults standardUserDefaults] retain];
//	resultsPadding = 0;
//	historyArray = [[NSMutableArray alloc] initWithCapacity:10];
//	parentStack = [[NSMutableArray alloc] initWithCapacity:10];
//	
//	validSearch = YES;
//	
//	[resultController window];  
//	[[resultController window] setFrameUsingName:@"results" force:YES];
//	[self setVisibleString:@""];
//	
//	[[self cell] bind:@"highlightColor"
//           toObject:[NSUserDefaultsController sharedUserDefaultsController]
//        withKeyPath:@"values.QSAppearance2A"
//            options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:@"NSValueTransformerName"]];
//	//resultArrayController = [[NSArrayController alloc] init];
//	//[resultArrayController bind:@"contentArray" toObject:self withKeyPath:@"resultArray" options:nil];
//}
//
//- (void)dealloc {
//	[self unbind:@"highlightColor"];
//	[historyArray release];
//	[parentStack release];
//	[partialString release];
//	[matchedString release];
//	[resetTimer release];
//	[searchTimer release];
//	[resultTimer release];
//	[resultController release];
//	[defaults release];
//	[editor release];
//	[searchArray release];
//	[resultArray release];
//	[scoreData release];
//	
//	historyArray = nil;
//	parentStack = nil;
//	partialString = nil;
//	matchedString = nil;
//	resetTimer = nil;
//	searchTimer = nil;
//	resultTimer = nil;
//	resultController = nil;
//	defaults = nil;
//	editor = nil;
//	searchArray = nil;
//	resultArray = nil;
//	scoreData = nil;
//	
//	[super dealloc];
//}
//
//- (BOOL)acceptsFirstResponder {return YES;}
//
//- (IBAction)assignMnemonic:(id)sender {
//}
//
- (IBAction)defineMnemonicImmediately:(id)sender {
	if ([self matchedString])
		[[QSMnemonics sharedInstance] addAbbrevMnemonic:[self matchedString] forID:[[self objectValue] identifier] immediately:YES];
	[self rescoreSelectedItem];
}

- (IBAction)promoteAction:(id)sender {
	[QSExec orderActions:[NSArray arrayWithObject:[self objectValue]] aboveActions:[self resultArray]]; 	
	[self rescoreSelectedItem];
}


- (IBAction)defineMnemonic:(id)sender {
	if ([self matchedString])
		[[QSMnemonics sharedInstance] addAbbrevMnemonic:[self matchedString] forID:[[self objectValue] identifier]];
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
- (void)rescoreSelectedItem {
	if (![self objectValue]) return;
	//[QSLib scoredArrayForString:[self matchedString] inSet:[NSArray arrayWithObject:[self objectValue]] mnemonicsOnly:![self matchedString]];
	[QSLib scoredArrayForString:[self matchedString] inSet:[NSArray arrayWithObject:[self objectValue]]];
	if ([[resultController window] isVisible])
		[resultController->resultTable reloadData];
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
  
  //		
	//	if (VERBOSE) QSLog(@"Added Mnemonic: %@", [self matchedString]);
	[[QSMnemonics sharedInstance] addObjectMnemonic:mnemonicKey forID:[[self objectValue] identifier]];
	if (![self sourceArray]) //don't add abbreviation if in a subsearch
		[[QSMnemonics sharedInstance] addAbbrevMnemonic:mnemonicKey forID:[[self objectValue] identifier] relativeToID:nil immediately:NO];
	//else
	//	QSLog(@"subsearch in %d", [[self sourceArray] count]);
	
	[[self objectValue] updateMnemonics];
	[self rescoreSelectedItem];
	//   QSLog(@"mnem: %@", [self searchString]);
}
//
///*
// - (void)selectionChange:(NSNotification*)notif {
// //QSLog(@"selection changed to %d", [resultTable selectedRow]);
// 
// if (!browsing) {
// if (selectedResult == [resultTable selectedRow]) return;
// 
// selectedResult = [resultTable selectedRow];
// 
// id selection = [resultArray objectAtIndex:selectedResult];
// if (selection != primaryResult) {
// [self setPrimaryResult:selection];
// }
// 
// [resultView setObjectValue:selection];
// if (searchString)
// [(QSObjectView *)focus setSearchString:searchString];
// 
// [resultCountField setStringValue:[NSString stringWithFormat:@"%d of %d", selectedResult+1, [resultArray count]]];
// if (!loadingIcons) [NSThread detachNewThreadSelector:@selector(loadIcons) toTarget:self withObject:nil];
// else iconLoadInvalid = YES;
// 
// } else {
// QSObject *selection = [QSObject fileObjectWithPath:[resultBrowser path]];
// [selection loadImage];
// [self setPrimaryResult:selection];
// [(QSObjectView *)focus setSearchString:nil];
// 
// [resultView setObjectValue:selection];
// }
// }
// */
//
//
//
//
//
////Events
//- (void)keyDown:(NSEvent *)theEvent {
//	[NSThread setThreadPriority:1.0];
//	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
//	NSTimeInterval delay = [theEvent timestamp] -lastTime;
//	//if (VERBOSE) QSLog(@"KeyD: %@\r%@", [theEvent characters] , theEvent);
//	lastTime = [theEvent timestamp];
//	lastProc = now;
//	
//	// ***warning   * should check for additional keydowns up to now so the search isn't done too often.
//	float resetDelay = [defaults floatForKey:kResetDelay];
//	if ((resetDelay && delay>resetDelay) || [self shouldResetSearchString]) {
//		
//		//if (VERBOSE) QSLog(@"resetting: %f", delay);
//		[partialString setString:@""];
//		validSearch = YES;
//		if ([self searchMode] == SearchFilterAll) {  
//			
//			[self setSourceArray:nil];
//		}
//		[self setShouldResetSearchString:NO];
//	} //else if (now-lastProc > resetDelay) {
//  //QSLog(@"event wast delayed");
//  //}
//  //if (fALPHA) moreComing = nil != [NSApp nextEventMatchingMask:NSKeyDownMask untilDate:[NSDate date] inMode:NSDefaultRunLoopMode dequeue:NO];
//  //if (VERBOSE && moreComing) QSLog(@"moreComing");
//  
//  
//  
//  
//	// ***warning   * have downshift move to indirect object
//  
//	if ([[theEvent charactersIgnoringModifiers] isEqualToString:@"/"] && [self handleSlashEvent:theEvent])
//    return;
//	if (([[theEvent characters] isEqualToString:@"~"] || [[theEvent characters] isEqualToString:@"`"]) && [self handleTildeEvent:theEvent])
//    return;
//	if ([self handleBoundKey:theEvent])
//    return;
//  
//	if ([[theEvent charactersIgnoringModifiers] isEqualToString:@" "]) {
//		[self insertSpace:nil];
//		return;
//	}
//	// ***warning   * have downshift move to indirect object
//  
//	if ([defaults boolForKey:@"Shift Actions"]
//      && [theEvent modifierFlags] &NSShiftKeyMask
//      && ([[theEvent characters] length] >= 1)
//      && [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[[theEvent characters] characterAtIndex:0]]
//      && self == [self directSelector]) {
//		[self handleShiftedKeyEvent:theEvent];
//		return;
//	}
//  
//	if ([theEvent isARepeat] && !([theEvent modifierFlags] &NSFunctionKeyMask) )
//    if ([self handleRepeaterEvent:theEvent]) return;
//  
//  
//	//if (VERBOSE) QSLog(@"interpret");
//	[self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
//	return;
//}
//
//- (BOOL)handleShiftedKeyEvent:(NSEvent *)theEvent {
//	if ([[resultController window] isVisible]) {
//		[self hideResultView:self];
//		[self setShouldResetSearchString:YES];
//	} else {
//		[resultTimer invalidate];
//	}
//	[[self window] makeFirstResponder:[self actionSelector]];
//	// ***warning   * toggle first responder on key up
//	
//	[(QSInterfaceController *)[[self window] windowController] fireActionUpdateTimer];
//	[[self actionSelector] keyDown:theEvent];
//	return YES;
//}
//- (BOOL)handleSlashEvent:(NSEvent *)theEvent {
//	if ([theEvent isARepeat]) return YES;
//	
//	if (!allowNonActions) return YES;
//	NSEvent *upEvent = [NSApp nextEventMatchingMask:NSKeyUpMask untilDate:[NSDate dateWithTimeIntervalSinceNow:0.25] inMode:NSDefaultRunLoopMode dequeue:YES];
//	
//	if ([[upEvent charactersIgnoringModifiers] isEqualToString:@"/"]) {
//		[self moveRight:self];
//	} else {
//		[self setObjectValue:[QSObject fileObjectWithPath:@"/"]];
//		upEvent = [NSApp nextEventMatchingMask:NSKeyUpMask untilDate:[NSDate dateWithTimeIntervalSinceNow:0.25] inMode:NSDefaultRunLoopMode dequeue:YES];
//		if (fBETA && !upEvent)
//			[self moveRight:self];
//	}
//	
//	return YES;
//}
//
//- (BOOL)handleTildeEvent:(NSEvent *)theEvent {
//	if ([theEvent isARepeat]) return YES;
//	if (!allowNonActions) return YES;
//	[self setObjectValue:[QSObject fileObjectWithPath:NSHomeDirectory()]];
//	
//	NSEvent *upEvent = [NSApp nextEventMatchingMask:NSKeyUpMask untilDate:[NSDate dateWithTimeIntervalSinceNow:0.25] inMode:NSDefaultRunLoopMode dequeue:YES];
//	if (!upEvent)
//		[self moveRight:self];
//	return YES;
//}
//
//
//- (BOOL)handleRepeaterEvent:(NSEvent *)theEvent {
//	//if (VERBOSE) QSLog(@"repeater");
//	[resultTimer invalidate];
//	
//	NSDictionary *mnemonics = [[QSMnemonics sharedInstance] objectMnemonicsForID:[[self objectValue] identifier]];
//	if (![mnemonics objectForKey:partialString]) {
//		//qu	QSLog(@"delaying before execution %@ %@", mnemonics, partialString);
//		
//		NSEvent *keyUp = [NSApp nextEventMatchingMask:NSKeyUpMask untilDate:[NSDate dateWithTimeIntervalSinceNow:2.0] inMode:NSDefaultRunLoopMode dequeue:YES];
//		if (keyUp) {
//			[NSApp discardEventsMatchingMask:NSKeyDownMask beforeEvent:keyUp];
//			return YES;
//		}
//	}
//	
//	[[self window] makeFirstResponder:[self window]];
//	
//	
//	if (1) {
//		[self insertNewline:self];  
//		
//		NSEvent *nextEvent;
//		NSDate *absorbDate = [NSDate dateWithTimeIntervalSinceNow:0.5];
//		
//		
//		if (nextEvent = [NSApp nextEventMatchingMask:NSKeyUpMask untilDate:absorbDate inMode:NSDefaultRunLoopMode dequeue:NO]) {
//			
//			if (VERBOSE)    QSLog(@"discarding events till  %@", nextEvent);  
//        [NSApp discardEventsMatchingMask:NSAnyEventMask beforeEvent:nextEvent];
//			
//		}
//		return YES;
//	} else {
//		while(1) {
//			NSEvent *nextEvent = [NSApp nextEventMatchingMask:NSKeyUpMask | NSKeyDownMask untilDate:[NSDate distantFuture] inMode:NSDefaultRunLoopMode dequeue:YES];
//			if ([nextEvent isARepeat] && [[nextEvent charactersIgnoringModifiers] isEqualToString:[theEvent charactersIgnoringModifiers]]) continue;
//			
//			if ([nextEvent type] == NSKeyUp && [[nextEvent charactersIgnoringModifiers] isEqualToString:[theEvent charactersIgnoringModifiers]]) {
//				////QSLog(@"exec");
//				[NSApp discardEventsMatchingMask:NSAnyEventMask beforeEvent:nextEvent];
//				[self insertNewline:self];
//				return NO;
//			} else if ([nextEvent keyCode] == 53) { //Escape key
//        //if (VERBOSE) QSLog(@"Escape chord");
//				[[self window] makeFirstResponder:self];
//				break;
//			} else if ([nextEvent type] == NSKeyDown) {
//				// QSLog(@"otherchar %@", [theEvent charactersIgnoringModifiers]);
//				
//				[[self window] makeFirstResponder:[self actionSelector]];
//				// ***warning   * toggle first responder on key up
//				[[self actionSelector] keyDown:nextEvent];
//				
//				[NSApp discardEventsMatchingMask:NSAnyEventMask beforeEvent:nextEvent];
//				[[self window] makeFirstResponder:[self actionSelector]];
//				return NO;
//				//[self insertNewline:self];
//				// return;
//			} else {
//				//QSLog(@"event %@", nextEvent);  
//			}
//			
//			
//		}
//	}
//	
//	return NO;
//}
//
//
//
//
//
//
//
//
//
//
//
//
//
//- (void)drawRect:(NSRect)rect {
//	if ([self currentEditor]) {
//		//QSLog(@"editor draw");
//		[super drawRect:rect];
//		rect = [self frame];
//		
//		if (NSWidth(rect) >128 && NSHeight(rect) >128) {
//			CGContextRef context = (CGContextRef) ([[NSGraphicsContext currentContext] graphicsPort]);
//			CGContextSetAlpha(context, 0.92);
//		}
//		[[NSColor colorWithDeviceWhite:1.0 alpha:0.92] set];
//		NSBezierPath *roundRect = [NSBezierPath bezierPath];
//		rect = [self frame];
//		rect.origin = NSZeroPoint;
//		[roundRect appendBezierPathWithRoundedRectangle:NSInsetRect(rect, 3, 3) withRadius:NSHeight(rect) /16];
//		[roundRect fill];  
//		
//		[[NSColor alternateSelectedControlColor] set];
//		[roundRect stroke];
//		
//		
//	} else {
//		[super drawRect:rect];
//	}
//}
//
//
//- (BOOL)shortCircuit:(id)sender {
//	[(QSInterfaceController *)[[self window] windowController] shortCircuit:self];
//	[resultTimer invalidate];
//	
//	return YES;
//}
//
//
//- (void)insertSpace:(id)sender {
//	int behavior = [defaults integerForKey:@"QSSearchSpaceBarBehavior"];
//	
//	switch(behavior) {
//		case 1: //Normal
//			[self insertText:@" "];
//			break;
//		case 2: //Select next result
//			if ([[NSApp currentEvent] modifierFlags] &NSShiftKeyMask)
//				[self moveUp:sender];
//			else
//				[self moveDown:sender];
//			break;
//		case 3: //Jump to Indirect
//			[self shortCircuit:sender];
//			break;
//		case 4: //Switch to text
//			[self transmogrify:sender];
//			break;
//		case 5: //Select next result
//			if ([[NSApp currentEvent] modifierFlags] &NSShiftKeyMask)
//				[self moveLeft:sender];
//			else
//				[self moveRight:sender];
//			break;
//	}
//}
//
//
//
//- (BOOL)becomeFirstResponder {
//	if ([[[self objectValue] primaryType] isEqual:QSTextProxyType]) {
//		NSString *defaultValue = [[self objectValue] objectForType:QSTextProxyType];
//		[self transmogrify:self];
//		//   QSLog(@"%@", [[self objectValue] dataDictionary]);
//		if (defaultValue) {
//			
//			[self setObjectValue:[QSObject objectWithString:defaultValue]];
//			[[self currentEditor] setString:defaultValue];
//			[[self currentEditor] selectAll:self];
//		}
//	}
//	
//	return  [super becomeFirstResponder];
//}
//
//
//- (IBAction)conditionalTransmogrify:(id)sender {
//	if (![partialString length]) [self transmogrify:sender];  
//    }
//
///*
// - (IBAction)webTransmogrify:(id)sender {
// if (![partialString length]) [self transmogrify:sender];  
// }
// */
//- (IBAction)calculate:(id)sender {
//	[self transmogrify:self];
//	[[self currentEditor] setString:@" = "];
//}
//
//
//
//
//
//- (void)transmogrifyWithText:(NSString *)string {
//	if (![self allowText]) return;
//	if ([self currentEditor]) {
//		[[self window] makeFirstResponder: self];
//	} else {
//		//QSLog(@"%p trans", sender);
//		//  [self setObjectValue:[QSObject objectWithString:@""]];
//		editor = [[self window] fieldEditor: YES forObject: self];
//		// QSLog(@"%@ %@", editor, [editor superview]);
//		
//		if (string) {
//			[editor setString:string];
//			[editor setSelectedRange:NSMakeRange([[editor string] length] , 0)];
//			
//		} else if ([partialString length] && ([resetTimer isValid] || ![defaults floatForKey:kResetDelay]) ) {
//			[editor setString:[partialString stringByAppendingString:[[NSApp currentEvent] charactersIgnoringModifiers]]];
//			[editor setSelectedRange:NSMakeRange([[editor string] length] , 0)];
//		} else {
//			NSString *stringValue = [[self objectValue]  stringValue];
//			if (stringValue) [editor setString:stringValue];
//			[editor setSelectedRange:NSMakeRange(0, [[editor string] length])];
//		}
//		
//		
//		NSRect titleFrame = [self frame];
//		NSRect editorFrame = NSInsetRect(titleFrame, NSHeight(titleFrame) /16, NSHeight(titleFrame) /16);
//		editorFrame.origin = NSMakePoint(NSHeight(titleFrame) /16, NSHeight(titleFrame) /16);
//		
//		//logRect(editorFrame);
//		
//		
//		//  [editor setTarget: self];
//		// [editor setMaxSize: NSMakeSize(256, 256)];
//		[editor setHorizontallyResizable: YES];
//		[editor setVerticallyResizable: YES];
//		[editor setDrawsBackground: NO];
//		[editor setDelegate: self];
//		//[editor setFrame:NSZeroRect];
//		[editor setMinSize: editorFrame.size];
//		[editor setFont:[NSFont systemFontOfSize:12.0]];
//		[editor setTextColor:[NSColor blackColor]];
//		[editor setContinuousSpellCheckingEnabled:YES];
//    [editor setEditable:YES];
//    [editor setSelectable:YES];
//		[editor setTextContainerInset:NSZeroSize];
//		
//		
//		NSScrollView *scrollView = [[[NSScrollView alloc] initWithFrame:editorFrame] autorelease];
//		[scrollView setBorderType:NSNoBorder];
//    [scrollView setHasVerticalScroller:NO];
//		// [scrollView setHasHorizontalScroller:YES];
//		[scrollView setAutohidesScrollers:YES];
//		[scrollView setDrawsBackground:NO];
//		
//    
//		NSSize contentSize = [scrollView contentSize];
//    [editor setMinSize:NSMakeSize(0, contentSize.height)];
//    [editor setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
//		
//    [editor setVerticallyResizable:YES];
//    [editor setHorizontallyResizable:YES];
//    
//		//[[editor textContainer] setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)];
//		//     [[editor textContainer] setWidthTracksTextView:YES];
//		//	[[editor textContainer] setHeightTracksTextView:YES];
//		
//		[editor setFieldEditor: YES];
//		[scrollView setDocumentView:editor];
//		//[scrollView addSubview:editor];
//		[self addSubview: scrollView];
//		
//		//QSLog(@"iseditor %d", [editor isFieldEditor]);
//		[[self window] makeFirstResponder: editor];
//		[self setCurrentEditor:editor];  
//		
//		
//	}
//} 
//- (IBAction)transmogrify:(id)sender {
//	[self transmogrifyWithText:nil];
//}
//
///*
// NSTextStorage *textStorage = [[self controller] textStorage];
// NSView *aspectView = [self aspectView];
// NSRect frame;
// NSTextContainer *textContainer;
// NSTextView *textView;
// NSScrollView *scrollView;
// 
// [super didLoadNib];
// 
// // Create NSScrollView
// frame = NSInsetRect([aspectView bounds] , 8.0, 8.0);
// scrollView = [[NSScrollView allocWithZone:[self zone]] initWithFrame:frame];
// [scrollView setBorderType:NSBezelBorder];
// [scrollView setHasVerticalScroller:YES];
// [scrollView setHasHorizontalScroller:YES];
// [scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
// [[scrollView contentView] setAutoresizesSubviews:YES];
// [aspectView addSubview:scrollView];
// [scrollView release];
// 
// // Set frame for content area of scroll view
// frame.origin = NSMakePoint(0.0, 0.0);
// frame.size = [scrollView contentSize];
// 
// // Create NSSLayoutManager
// _layoutManager = [[NSLayoutManager allocWithZone:[self zone]] init];
// [textStorage addLayoutManager:_layoutManager];
// 
// // Create and configure NSTextView
// textView = [[NSTextView allocWithZone:[self zone]] initWithFrame:frame textContainer:textContainer];
// [textView setMinSize:frame.size];
// [textView setMaxSize:NSMakeSize(LargeNumberForText, LargeNumberForText)];
// [textView setHorizontallyResizable:YES];
// [textView setVerticallyResizable:YES];
// [textView setAutoresizingMask:NSViewNotSizable];
// [textView setSelectable:YES];
// [textView setEditable:YES];
// [textView setRichText:YES];
// [textView setImportsGraphics:YES];
// [textView setUsesFontPanel:YES];
// [textView setUsesRuler:YES];
// [scrollView setDocumentView:textView];
// [textView release];
// }
// */
//
//
//- (void)setFrame:(NSRect)frameRect {
//	[super setFrame:frameRect];
//	
//	if ([self currentEditor]) {
//		NSRect editorFrame = [self frame];
//		
//		editorFrame.origin = NSZeroPoint;
//		editorFrame = NSInsetRect(editorFrame, 3, 3);
//		[[[self currentEditor] enclosingScrollView] setFrame: editorFrame];
//		[[self currentEditor] setMinSize:editorFrame.size];
//	}
//}
//
//
//- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
//	// QSLog(@"%@", NSStringFromSelector(commandSelector) );
//	if (commandSelector == @selector(insertTab:) ) {
//		[[self window] selectKeyViewFollowingView:self];
//		return YES;
//	}
//	if (commandSelector == @selector(insertBacktab:) ) {
//		[[self window] selectKeyViewPrecedingView:self];
//		return YES;
//	}
//	if (commandSelector == @selector(insertNewline:) ) {
//		[[self window] makeFirstResponder:self];
//		[[[self window] windowController] executeCommand:self];
//		if ([[self window] isVisible])
//			[[self window] selectKeyViewFollowingView:self];
//		return YES;
//	}
//	if (commandSelector == @selector(complete:) ) {
//		[[self window] makeFirstResponder:self];
//		return YES;
//	}
//	return NO;
//}
//- (void)textDidChange:(NSNotification *)aNotification {
//	NSString *string = [[[[aNotification object] string] copy] autorelease];
//	if ([[[aNotification object] string] isEqualToString:@" "]) {
//		[(QSInterfaceController *)[[self window] windowController] shortCircuit:self];
//		return;
//	}
//	[self setObjectValue:[QSObject objectWithString:string]];
//	[self setMatchedString:nil];
//}
//
//- (void)textDidEndEditing:(NSNotification *)aNotification {
//	NSString *string = [[[[aNotification object] string] copy] autorelease];
//	[self setObjectValue:[QSObject objectWithString:string]];
//	[self setMatchedString:nil];
//	//[[self window] makeFirstResponder: self];
//	[self setCurrentEditor:nil];  
//	[[editor enclosingScrollView] removeFromSuperview];
//}
//
//
//
//
//
//
//
//- (void)deleteBackward:(id)sender {
//	[self clearSearch];
//	//	NSText *fieldEditor = [[self window] fieldEditor:YES forObject:self];
//	//[[self cell] editWithFrame:[self frame] inView:self editor:fieldEditor delegate:self event:nil];
//}
//- (NSMutableString *)partialString { return partialString;}
//
- (void)clearSearch {
  [searchField setStringValue:@""];
	//QSLog(@"clear");
//	[resetTimer invalidate];
//	[resultTimer invalidate];
//	[self resetString];
//	[partialString setString:@""];
//	
//	[self setVisibleString:@""];
//	[self setMatchedString:nil];
//	[self setShouldResetSearchString:YES];
}
//
//
//- (NSString *)visibleString {
//  return [[visibleString retain] autorelease];  
//}
//- (void)setVisibleString:(NSString *)newVisibleString {
//  if (visibleString != newVisibleString) {
//    [visibleString release];
//    visibleString = [newVisibleString copy];
//		
//		[resultController->searchStringField setStringValue:visibleString];
//		if ([[self controller] respondsToSelector:@selector(searchView:changedString:)])
//			[(id)[self controller] searchView:self changedString:visibleString];
//		
//  }
//}
//
//
//- (void)scrollWheel:(NSEvent *)theEvent {
//	// ***warning   * this still goes to the wrong view if over another search view
//	if (![[resultController window] isVisible]) {
//		[self showResultView:self];
//		
//	}
//	
//	
//	
//	if (NSMouseInRect([NSEvent mouseLocation] , NSInsetRect([[resultController window] frame] , 0, 0), NO) ) { 
//		[resultController scrollWheel:theEvent];
//		return;
//	}
//	float delta = [theEvent deltaY];
//	
//	// This is really really awful.
//  UnsignedWide currentTime; 	
//  double currentTimeDouble = 0;
//  Microseconds(&currentTime);
//  currentTimeDouble = (((double) currentTime.hi) * 4294967296.0) + currentTime.lo;
//	
//	//If the scroll event is really delayed (Nonactivating panels cause this) then ignore
//	if (currentTimeDouble/1000000-[theEvent timestamp] >0.25) return;
//	
//	
//	while (theEvent = [NSApp nextEventMatchingMask: NSScrollWheelMask untilDate:[NSDate date] inMode:NSDefaultRunLoopMode dequeue:YES]) {
//		delta += [theEvent deltaY];
//	}
//	
//	[self moveSelectionBy:-(int) delta];
//	
//	// [resultController->resultTable scrollWheel:theEvent];
//}
//
//
- (void)selectHome:(id)sender {
	QSLog(@"act%d", allowNonActions);
	//	if (allowNonActions)
	//		[self setObjectValue:[QSObject fileObjectWithPath:NSHomeDirectory()]];
}
- (void)selectRoot:(id)sender {
	if (allowNonActions)
		[self setObjectValue:[QSObject fileObjectWithPath:@"/"]];
}
//
//
//- (void)doCommandBySelector:(SEL)aSelector {
//	if (VERBOSE && ![self respondsToSelector:aSelector])
//		QSLog(@"Unhandled Command: %@", NSStringFromSelector(aSelector) );
//	[super doCommandBySelector:aSelector];
//}
//- (void)scrollToBeginningOfDocument:(id)sender {
//	[self selectIndex:0];
//}
//
//- (void)scrollToEndOfDocument:(id)sender {
//	[self selectIndex:[resultArray count] -1];
//  
//}
//
//- (void)pageUp:(id)sender {[self pageScroll:-1];}
//- (void)pageDown:(id)sender {[self pageScroll:1];}
//- (void)scrollPageUp:(id)sender {[self pageScroll:-1];}
//- (void)scrollPageDown:(id)sender {[self pageScroll:1];}
//
//- (void)pageScroll:(int)direction {
//	if (![[resultController window] isVisible]) [self showResultView:self];
//	
//	int movement = direction * (NSHeight([[resultController->resultTable enclosingScrollView] frame]) /[resultController->resultTable rowHeight]);
//	//QSLog(@"%d", movement);
//	[self moveSelectionBy:movement];
//}
//
//
- (void)moveDown:(id)sender {	[self moveSelectionBy:1];}
- (void)moveUp:(id)sender {	[self moveSelectionBy:-1];}
- (void)moveSelectionBy:(int)d {
	// QSLog(@"newselect %d", selection+d);  
	[self selectIndex:[resultArrayController selectionIndex]+d];
}

//- (void)complete:(id)sender {
//	[self cancelOperation:sender];
//}
//- (void)performClose:(id)sender {
//	[self cancelOperation:sender];
//}
//
//- (void)reset:(id)sender {
//	if ([[resultController window] isVisible]) {
//		[self hideResultView:self];
//	}     
//	if (browsing) {
//		browsing = NO;
//		[self setSearchMode:SearchFilterAll];
//	}
//	[self setShouldResetSearchString:YES];
//	[resultTimer invalidate];
//}
//
//- (void)cancelOperation:(id)sender {
//	if ([self currentEditor]) {
//		[[self window] makeFirstResponder:self];
//		return;
//	} else if ([[resultController window] isVisible]) {
//		[self hideResultView:self];
//		[self setShouldResetSearchString:YES];
//	} else {
//		[resultTimer invalidate];
//		[[[self window] windowController] hideMainWindowFromCancel:self];
//	}
//	return;  
//}
//- (void)selectAll:(id)sender {
//	[self setObjectValue:[QSObject objectByMergingObjects:resultArray]] ;
//	
//}
//
//
- (void)insertTab:(id)sender {
	[resultTimer invalidate];
	[[searchField window] selectNextKeyView:searchField];
}
- (void)insertBacktab:(id)sender {
	[resultTimer invalidate];
	[[searchField window] selectPreviousKeyView:searchField];
}
//- (void)insertNewlineIgnoringFieldEditor:(id)sender {
//	[self insertNewline:sender];  
//}
//- (void)encapsulateCommand:(id)sender {
//	[(QSInterfaceController *)[[self window] windowController] encapsulateCommand:self]; 	
//}
//- (void)executeCommandAndContinue:(id)sender {
//	[(QSInterfaceController *)[[self window] windowController] executeCommandAndContinue:self]; 	
//}
//- (void)executeCommand:(id)sender {
//	[resultTimer invalidate];
//	if ([searchTimer isValid]) {
//		[searchTimer invalidate];
//		[self performSearchFor:partialString from:self];
//		[self display];
//	} 	
//	[resetTimer fire];
//	[(QSInterfaceController *)[[self window] windowController] executeCommand:self]; 	
//}
//- (void)insertNewline:(id)sender {
//	[self executeCommand:sender];
//}
//- (void)mouseDown:(NSEvent *)theEvent {
//	//NSPoint p = [self convertPoint: [theEvent locationInWindow] fromView: nil];
//	/*	
//   if (editor != nil) {
//   [self setNeedsDisplayInRect: [self frame]];
//   [[self window] makeFirstResponder: nil];
//   [editor removeFromSuperview];
//   editor = nil;
//   }
//	 */
//	if ([theEvent clickCount] > 1) {
//		[(QSInterfaceController *)[[self window] windowController] executeCommand:self];
//	}
//	else {
//		[super mouseDown:theEvent];  
//	}
//}
///*
// - (void)mouseDown:(NSEvent *)theEvent {
// BOOL keepOn = YES;
// BOOL isInside = YES;
// NSPoint mouseLoc;
// 
// theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask |
// NSLeftMouseDraggedMask];
// mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
// isInside = [self mouse:mouseLoc inRect:[self bounds]];
// 
// switch ([theEvent type]) {
// case NSLeftMouseDragged:
// 
// [self hideResultView:self];
// [super mouseDragged:theEvent];
// break;
// case NSLeftMouseUp:
// //if (isInside)
// QSLog(@"mouseUp");
// [self toggleResultView:self];
// = NO;
// break;
// default:
// 
// break;
// }
// 
// 
// return;
// }
// */
//- (BOOL)handleBoundKey:(NSEvent *)theEvent {
//	NSString *selectorString = [bindingsDict objectForKey:[self stringForEvent:theEvent]];
//	
//	if (selectorString) {
//		SEL selector = NSSelectorFromString(selectorString);
//		[self doCommandBySelector:selector];
//		return YES;
//	}
//	return NO;
//}
//
//
//- (BOOL)performKeyEquivalent:(NSEvent *)theEvent {	
//	
//	if ([[theEvent charactersIgnoringModifiers] isEqualToString:@"\r"]) {
//		[self insertNewline:nil];
//		return YES;
//	}
//	BOOL higher = [[[self window] delegate] performKeyEquivalent:(NSEvent *)theEvent]; 	
//	if ([[self window] firstResponder] == self && !higher) {
//		if ([self handleBoundKey:theEvent]) return YES;
//	}
//	return higher;
//}
//
//- (NSString *)stringForEvent:(NSEvent *)theEvent {
//	int flags = [theEvent modifierFlags];
//	NSString *string = [NSString stringWithFormat:@"%@%@%@%@%@%@",
//                      flags&NSShiftKeyMask?@"$":@"",
//                      flags&NSControlKeyMask?@"^":@"",
//                      flags&NSAlternateKeyMask?@"~":@"",
//                      flags&NSCommandKeyMask?@"@":@"",
//                      flags&NSFunctionKeyMask?@"#":@"",
//                      [theEvent charactersIgnoringModifiers]];
//	return string;
//	//	return [[[self window] delegate] performKeyEquivalent:(NSEvent *)theEvent];
//}
//
//
//- (BOOL)executeText:(NSEvent *)theEvent {
//	
//	[self clearSearch];
//	[self insertText:[theEvent charactersIgnoringModifiers]];
//	[self insertNewline:self];
//	return YES;
//}
//
//- (IBAction)logObjectDictionary:(id)sender {
//	
//	QSLog(@"Printing Object\r%@", [[self objectValue] name]);
//	QSLog(@"Dictionary\r%@", [[self objectValue] archiveDictionary]);
//	QSLog(@"Icon\r%@", [[self objectValue] icon]);
//	
//}
//- (IBAction)newFile:(id)sender {
//	NSSavePanel *savePanel = [NSSavePanel savePanel];
//	NSView *content = [savePanel contentView];
//	// QSLog(@"sub %@", [content subviews]);
//	if  (![content isKindOfClass:[QSBackgroundView class]]) {
//		NSView *newBackground = [[[QSBackgroundView alloc] init] autorelease];
//		[savePanel setContentView:newBackground];
//		[newBackground addSubview:content];
//	}
//	
//	[savePanel setNameFieldLabel:@"Create Item:"];
//	[savePanel setCanCreateDirectories:YES];
//	NSString *oldFile = [[self objectValue] singleFilePath];
//	
//	//if (![openPanel runModalForDirectory:oldFile file:nil types:nil]) return;
//	//  beginSheetForDirectory:file:types:modalForWindow:modalDelegate:didEndSelector:contextInfo:
//	
//	[savePanel beginSheetForDirectory:oldFile
//                               file:nil
//                     modalForWindow:[self window]
//                      modalDelegate:self
//                     didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
//                        contextInfo:sender];
//}
//- (void)savePanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
//	[self setObjectValue:[QSObject fileObjectWithPath:[sheet filename]]];
//}
//
//- (IBAction)openFile:(id)sender {
//	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
//	[openPanel setCanChooseDirectories:YES];
//	NSView *content = [openPanel contentView];
//	// QSLog(@"sub %@", [content subviews]);
//	if  (![content isKindOfClass:[QSBackgroundView class]]) {
//		NSView *newBackground = [[[QSBackgroundView alloc] init] autorelease];
//		[openPanel setContentView:newBackground];
//		[newBackground addSubview:content];
//	}
//	NSString *oldFile = [[self objectValue] singleFilePath];
//	
//	//if (![openPanel runModalForDirectory:oldFile file:nil types:nil]) return;
//	//  beginSheetForDirectory:file:types:modalForWindow:modalDelegate:didEndSelector:contextInfo:
//	
//	
//	[openPanel beginSheetForDirectory:oldFile
//                               file:nil
//                              types:nil
//                     modalForWindow:[self window]
//                      modalDelegate:self
//                     didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
//                        contextInfo:sender];
//}
//
//- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
//	[self setObjectValue:[QSObject fileObjectWithPath:[sheet filename]]];
//}
//
//- (IBAction)sortByScore:(id)sender {
//	[(NSMutableArray *)[self resultArray] sortUsingSelector:@selector(scoreCompare:)];
//	[self reloadResultTable];
//	
//}
//- (IBAction)sortByName:(id)sender {
//	[(NSMutableArray *)[self resultArray] sortUsingSelector:@selector(nameCompare:)];
//	[self reloadResultTable];
//	
//}
//
//- (void)performSearch:(NSTimer *)timer {
//	
//	//QSLog(@"perform search, %d", self);  
//	if (validSearch) {
//		[resultController->searchStringField setTextColor:[NSColor blackColor]];
//		[resultController->searchStringField display];
//		[self performSearchFor:partialString from:timer];
//		[resultController->searchStringField display];
//	}
//	//  QSLog(@"search performed");
//}
//
//
//- (void)performSearchFor:(NSString *)string from:(id)sender {
//  //	NSDate *date = [NSDate date];
//	
//	//    NSData *scores;
//	NSMutableArray *newResultArray = [[QSLibrarian sharedInstance] scoredArrayForString:string inSet:searchArray];
//	
//	//if ([newResultArray count] >10) [newResultArray insertObject:[QSSeparatorObject separatorWithName:@"Other Matches"] atIndex:10];
//	
//	//t QSLog(@"scores %@", scores);
//	//if (DEBUG_RANKING)
//	// QSLog(@"Searched for \"%@\" in %3fms (%d items) ", string, 1000 * -[date timeIntervalSinceNow] , [newResultArray count]);
//  // QSLog (@"search for %@", string);
//	//QSLog(@"%d valid", validSearch);
//	if (validSearch = [newResultArray count] >0) {
//		[self setMatchedString:string];
//		//        [self setScoreData:scores];
//		validMnemonic = YES;
//		if ([self searchMode] == SearchFilterAll || [self searchMode] == SearchFilter)
//			[self setResultArray:newResultArray];
//		if ([self searchMode] == SearchFilterAll) {
//			[self setSearchArray:newResultArray];
//			[parentStack removeAllObjects];
//		}
//		
//		if ([self searchMode] == SearchSnap) {
//			[self selectObject:[newResultArray objectAtIndex:0]];
//			
//      [self reloadResultTable];
//		} else if (0) { //if should retain the selection
//      // [self selectObject:[newResultArray objectAtIndex:0]];
//		} else {
//			[self selectIndex:0];
//		}
//		
//		int resultBehavior = [defaults integerForKey:kResultWindowBehavior];
//		
//		if ([resultArray count] >1) {
//			if (resultBehavior == 0)
//				[self showResultView:self];
//			else if (resultBehavior == 1) {
//				
//				if ([resultTimer isValid]) {
//					[resultTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:[defaults floatForKey:kResetDelay]]];
//				} else {
//					[resultTimer release];
//					resultTimer = [[NSTimer scheduledTimerWithTimeInterval:[defaults floatForKey:kResetDelay] target:self selector:@selector(showResultView:) userInfo:nil repeats:NO] retain];
//				}
//			}
//		}
//		
//		
//	} else {
//		if ([defaults boolForKey:@"QSTransformBadSearchToText"])
//			[self transmogrifyWithText:partialString];
//		else
//			NSBeep();
//		
//		
//		validMnemonic = NO;
//		[resultController->searchStringField setTextColor:[NSColor redColor]];
//	}
//	
//	
//	// Extend Timers
//	if ([searchTimer isValid]) {
//		// QSLog(@"extend");
//		[searchTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:[defaults floatForKey:kSearchDelay]]];
//		
//	}
//	
//	
//	if ([resetTimer isValid]) {
//		float resetDelay = [defaults floatForKey:kResetDelay];
//		if (resetDelay) [resetTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:resetDelay]];
//	}
//	
//}
//
//
//
//
//
//
//
//- (void)resetString {
//	// QSLog(@"resetting");
//	[resultController->searchStringField setTextColor:[[resultController->searchStringField textColor] colorWithAlphaComponent:0.5]];
//	[resultController->searchStringField display];
//	
//}
//
//
//- (IBAction)toggleResultView:sender {
//	if ([[resultController window] isVisible])
//		[self hideResultView:sender];
//	else
//		[self showResultView:sender];
//}
//
//
- (IBAction)showResultView:sender {
  NSLog(@"show result view");
  
}//	if ([[self window] firstResponder] != self) [[self window] makeFirstResponder:self];
//	if ([[resultController window] isVisible]) return; //[resultController->resultTable reloadData];
//	
//	[[resultController window] setLevel:[[self window] level] +1];
//	[[resultController window] setFrameUsingName:@"results" force:YES];
//	//   if (fALPHA) [resultController setSplitLocation];
//	
//	NSRect windowRect = [[resultController window] frame];
//	NSRect screenRect = [[[resultController window] screen] frame];
//	if (preferredEdge == NSMaxXEdge) {
//		
//		NSPoint resultPoint = [self convertPoint:NSZeroPoint toView:nil];
//		
//		resultPoint = [[self window] convertBaseToScreen:resultPoint];
//		
//		if (resultPoint.x+NSWidth([self frame]) +NSWidth(windowRect) <NSMaxX(screenRect)) {
//			if (hFlip) {
//				[[[resultController window] contentView] flipSubviewsOnAxis:NO];
//				hFlip = NO;
//			}
//			
//			resultPoint.x += NSWidth([self frame]);
//			resultPoint.y += NSHeight([self frame]) +1;
//		} else {
//			if (!hFlip) {
//				[[[resultController window] contentView] flipSubviewsOnAxis:NO];
//				hFlip = YES;
//			}
//			resultPoint.x -= NSWidth(windowRect);
//			resultPoint.y += NSHeight([self frame]) +1;
//		}
//		
//		[[resultController window] setFrameTopLeftPoint:resultPoint];
//		
//	} else {
//		NSPoint resultPoint = [[self window] convertBaseToScreen:[self frame] .origin];
//		//resultPoint.x;
//		float extraHeight = windowRect.size.height-(resultPoint.y-screenRect.origin.y);
//		
//		//resultPoint.y += 2;
//		windowRect.origin.x = resultPoint.x;
//		if (extraHeight>0) {
//			windowRect.origin.y = screenRect.origin.y;
//			windowRect.size.height -= extraHeight;
//		} else {
//			//		QSLog(@"pad %f", resultsPadding);
//			windowRect.origin.y = resultPoint.y-windowRect.size.height-resultsPadding;
//		}
//		
//		windowRect = NSIntersectionRect(windowRect, screenRect);
//		[[resultController window] setFrame:windowRect display:NO];
//	}
//	
//	
//	
//	
//	[self updateResultView:sender];
//	
//	if ([[self controller] respondsToSelector:@selector(searchView:resultsVisible:)])
//		[(id)[self controller] searchView:self resultsVisible:YES];
//	
//	if ([[self window] isVisible]) {
//		
//		[[resultController window] orderFront:nil];
//		[[self window] addChildWindow:[resultController window] ordered:NSWindowAbove];
//	}
//	
//}
//
//
//
//
//- (IBAction)updateResultView:sender {
//	//[resultController->searchModePopUp selectItemAtIndex:[resultController->searchModePopUp indexOfItemWithTag:searchMode]];
//	[self reloadResultTable];
//	[resultController->resultTable selectRow:selection byExtendingSelection:NO];
//	[resultController updateSelectionInfo];  
//}
//
//
//- (void)clearAll {
//	[super setObjectValue:nil];
//	[self clearHistory];
//	[self setSourceArray:nil];
//	[self setSearchArray:nil];
//	[self setResultArray:nil];
//	[parentStack removeAllObjects];
//	[childStack removeAllObjects];
//}
//
//
- (void)clearObjectValue {
	[self updateHistory];
//	[super setObjectValue:nil];
	//selection--;
	//	[[NSNotificationCenter defaultCenter] postNotificationNamse:@"SearchObjectChanged" object:self];
}
//
- (void)selectObjectValue:( QSObject *)newObject {
	if ( newObject != [self objectValue]) {
		[self updateHistory];
		// if (newObject) QSLog(@"%p set value %@", self, newObject);
		// [newObject loadIcon];
		[self setObjectValue:newObject];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"SearchObjectChanged" object:self];
	}
}
//
//
//- (void)setObjectValue:(QSBasicObject *)newObject {
//	//if (newObject) QSLog(@"%p set value %@", self, newObject);
//	[self hideResultView:self];
//	
//	[self clearSearch];
//	[parentStack removeAllObjects];
//	[self setResultArray:[NSArray arrayWithObjects:newObject, nil]];  
//	[super setObjectValue:newObject];
//	
//	[[NSNotificationCenter defaultCenter] postNotificationName:@"SearchObjectChanged" object:self];
//}
//
//- (BOOL)resignFirstResponder {
//	//QSLog(@"resign first");
//	if ([self currentEditor]) {
//		
//		// QSLog(@"resign first with monkey %@", self);
//		// [[self currentEditor] endEditing];
//	}
//	[resultTimer invalidate];
//	[self hideResultView:self];
//	[self setShouldResetSearchString:YES];
//	[self resetString];
//	[self setNeedsDisplay:YES];
//	return YES;
//}
//- (IBAction)hideResultView:sender {
//  
//	[[self window] removeChildWindow:[resultController window]];
//	[resultController setResultIconLoader:nil];
//	[[resultController window] orderOut:self];
//	if (browsing) {
//		browsing = NO;
//		[self setSearchMode:SearchFilterAll];
//	}
//	if ([[self controller] respondsToSelector:@selector(searchView:resultsVisible:)])
//		[(id)[self controller] searchView:self resultsVisible:NO];
//}
//
////
////- (IBAction)getFinderSelection:sender {
////	if (!allowNonActions) return;
////	QSObject *entry = [QSObject fileObjectWithArray:[[QSReg getMediator:kQSFSBrowserMediators] selection]];
////	// [entry loadIcon];
////	[self setSearchString:nil];
////	[self setObjectValue:entry];
////}
//
//- (id)externalSelection {
//	if (defaultBool(@"QSUseGlobalSelectionForGrab") )
//		return [QSGlobalSelectionProvider currentSelection];
//	else
//		return [QSObject fileObjectWithArray:[[QSReg getMediator:kQSFSBrowserMediators] selection]];
//}
//- (IBAction)grabSelection:sender {
//	if (!allowNonActions) return;
//	QSObject *newSelection = [self externalSelection];
//	
//	//QSLog(@"type: %@", [[NSFileManager defaultManager] UTIOfFile:[newSelection singleFilePath]]);
//	[self setObjectValue:newSelection];
//}
//
//- (IBAction)dropSelection:sender { 
//	if (!allowNonActions) return;
//	QSObject *newSelection = [self externalSelection];
//	[self dropObject:newSelection];
//}
//- (IBAction)dropClipboard:sender { 
//	if (!allowNonActions) return;
//	QSObject *newSelection = [QSObject objectWithPasteboard:[NSPasteboard generalPasteboard]];
//	[self dropObject:newSelection];
//}
//- (void)dropObject:(QSBasicObject *)newSelection {        
//	NSString *action = [[self objectValue] actionForDragOperation:NSDragOperationEvery withObject:newSelection];
//	//QSLog(@"action %@", action);
//	QSAction *actionObject = [QSLib actionForIdentifier:action];
//	
//	if (!action) {
//		NSBeep();
//		return;
//	}
//	if ([[[self window] windowController] isKindOfClass:[QSInterfaceController class]]) {
//		[(QSInterfaceController *)[[self window] windowController] setCommandWithArray:[NSArray arrayWithObjects:newSelection, actionObject, [self objectValue] , nil]];
//	} else {
//		[actionObject performOnDirectObject:(QSObject *)newSelection indirectObject:[self objectValue]];
//	}
//}
//
//
//
//
//- (BOOL)validateMenuItem:(NSMenuItem*)anItem {
//	
//	if ([anItem action] == @selector(newFile:) ) {
//		return fDEV;
//	}
//	if ([anItem action] == @selector(goForward:) ) {
//		return historyIndex>0;
//	}
//	if ([anItem action] == @selector(goBackward:) ) {
//		return YES;
//	}
//	if ([anItem action] == @selector(defineMnemonicImmediately:) ) {
//		if (![self matchedString]) return NO;
//		[anItem setTitle:[NSString stringWithFormat:@"Set as Default for \"%@\"", [[self matchedString] uppercaseString]]];
//		return YES;
//	}
//	if ([anItem action] == @selector(removeMnemonic:) ) {
//		if (![self matchedString]) return NO;
//		[anItem setTitle:[NSString stringWithFormat:@"Remove as Default for \"%@\"", [[self matchedString] uppercaseString]]];
//		return YES;
//	}
//	
//	if ([anItem action] == @selector(clearMnemonics:) ) {
//		return  [self impliedMnemonicDefined];
//	}
//	
//	
//	return YES;
//}
//
//
//
//- (void)rowClicked:(int)index {
//	
//}
//
- (void)selectIndex:(int)index {
  if (index > [[resultArrayController arrangedObjects] count]) return;
  [resultArrayController setSelectionIndex:index];
  return;
//	// QSLog(@"selectindex %d %d", self, index);
//	
//	if (index<0)
//		selection = 0;
//	else if (index >= [resultArray count])
//		selection = [resultArray count] -1;
//	else
//		selection = index;
//	
//	if ([resultArray count]) {
//		QSObject *object = [resultArray objectAtIndex:selection];
//		
//		[self selectObjectValue:object];
//		[resultController->resultTable scrollRowToVisible:selection];
//		//[resultController->resultTable centerRowInView:selection];
//		[resultController->resultTable selectRow:selection byExtendingSelection:NO];
//	}
//	else
//		[self selectObjectValue:nil];
//	
//	if ([[resultController window] isVisible])
//		[resultController updateSelectionInfo];  
}
//
- (void)selectObject:(QSBasicObject *)obj {	
	int index = 0;
	//[self updateHistory];
	if (obj) {
		index = [resultArray indexOfObject:obj];
		//QSLog(@"index %d %@", index, obj);
		if (index == NSNotFound) {
			//if (VERBOSE) QSLog(@"Unable To Select Object : %@ in \r %@", [obj identifier] , resultArray);
			return;
		}
	} else {
		[self selectObjectValue:nil];
		return;
	}
	[self selectIndex:index];
}
//
//- (void)setResultArray:(NSMutableArray *)newResultArray {
//	[resultArray release];
//	resultArray = [newResultArray retain];
//	
//	if ([[resultController window] isVisible])
//		[self reloadResultTable];
//	
//	if ([[self controller] respondsToSelector:@selector(searchView:changedResults:)])
//		[(id)[self controller] searchView:self changedResults:newResultArray];
//}
//
- (void)sourceArrayChanged:(NSNotification *)notif {
	[resultArrayController rearrangeObjects];
//		QSLog(@"notif change %@", notif, [self sourceArray]); 	
//	if ([[self sourceArray] isEqual:[notif object]]) {
//		//QSLog(@"arraychanged");
//		
//		if ([[resultController window] isVisible]) {
//			[self reloadResultTable];
//			[resultController updateSelectionInfo];
//		}
//		if (![[self sourceArray] containsObject:[self selectedObject]]) {
//			[self clearObjectValue]; 	
//		}
//		if ([[self controller] respondsToSelector:@selector(searchView:changedResults:)])
//			[(id)[self controller] searchView:self changedResults:resultArray];
//	}
}
//
//
//- (void)reloadResultTable {
//	//[resultController->resultTable reloadData];
//	[resultController arrayChanged:nil];
//}
//
////-------------------------------------
//
//- (void)setResultsPadding:(float)aResultsPadding
//{
//	resultsPadding = aResultsPadding;
//}
//
//
//- (NSMutableArray *)resultArray { return [[resultArray retain] autorelease];  }
//
//
//- (NSArray *)searchArray { return [[searchArray retain] autorelease];  }
//
//- (void)setSearchArray:(NSArray *)newSearchArray {
//	// QSLog(@"searcharray:%d %d %d", self, newSearchArray, [newSearchArray count]);
//	
//	[searchArray autorelease];
//	// QSLog(@"searcharray:%d %d %d", self, newSearchArray, [newSearchArray count]);
//	searchArray = [newSearchArray retain];
//}
//
//- (NSMutableArray *)sourceArray {
//  return [[sourceArray retain] autorelease];  
//}
//- (void)setSourceArray:(NSMutableArray *)newSourceArray {
//  if (sourceArray != newSourceArray) {
//    [sourceArray release];
//    sourceArray = [newSourceArray retain];
//		[self setSearchArray:sourceArray];
//  }
//}
//
//- (BOOL)shouldResetSearchString { return shouldResetSearchString;  }
//- (void)setShouldResetSearchString:(BOOL)flag {
//	shouldResetSearchString = flag;
//}
//
//
//- (BOOL)shouldResetSearchArray { return shouldResetSearchArray;  }
//- (void)setShouldResetSearchArray:(BOOL)flag {
//	shouldResetSearchArray = flag;
//}
//
//- (NSRectEdge) preferredEdge { return preferredEdge;  }
//- (void)setPreferredEdge:(NSRectEdge)newPreferredEdge {
//	preferredEdge = newPreferredEdge;
//}
//
//
//- (NSString *)matchedString { return [[matchedString retain] autorelease];  }
//
//- (void)setMatchedString:(NSString *)newMatchedString {
//	[matchedString release];
//	matchedString = [newMatchedString copy];
//	[self setNeedsDisplay:YES];
//}
//
//
//- (NSData *)scoreData { return [[scoreData retain] autorelease];  }
//
//- (void)setScoreData:(NSData *)newScoreData {
//	[scoreData release];
//	scoreData = [newScoreData retain];
//}
//- (id)selectedObject { return selectedObject;  }
//
//- (void)setSelectedObject:(id)newSelectedObject {
//	[selectedObject release];
//	selectedObject = [newSelectedObject retain];
//}
//
//
//- (QSSearchMode) searchMode { return searchMode;  }
//- (void)setSearchMode:(QSSearchMode)newSearchMode {
//	searchMode = newSearchMode;
//	
//	if (searchMode != SearchFilterAll) {
//		//		[resultController->resultTable setBackgroundColor:[[NSColor selectedControlColor] blendedColorWithFraction:0.75 ofColor:[NSColor whiteColor]]];
//		//	[[self cell] setState:NSOnState];
//	} else {
//		//		[resultController->resultTable setBackgroundColor:[NSColor colorWithCalibratedHue:0.0 saturation:0.0 brightness:1.0 alpha:0.95]];
//		//	[[self cell] setState:NSOffState];
//	}
//	
//	[resultController->resultTable setNeedsDisplay:YES];
//	
//	if (browsing) [defaults setInteger:newSearchMode forKey:kBrowseMode];
//	
//	// ***warning   * set default browse mode
//	
//	//if ([[resultController window] isVisible])
//	//	[resultController->searchModeMenu selectItemAtIndex:[resultController->searchModePopUp indexOfItemWithTag:searchMode]];
//}
//
//- (NSText *)currentEditor {
//	if ([super currentEditor])
//		return [super currentEditor];
//	else
//		return [[currentEditor retain] autorelease];  
//}
//
//- (void)setCurrentEditor:(NSText *)aCurrentEditor
//{
//  if (currentEditor != aCurrentEditor) {
//    [currentEditor release];
//    currentEditor = [aCurrentEditor retain];
//  }
//}
//
//
//- (QSSearchObjectView *)directSelector {
//	return [[[self window] windowController] dSelector];
//}
//- (QSSearchObjectView *)actionSelector {
//	//QSLog(@"action");
//	return [[[self window] windowController] aSelector];
//}
//- (QSSearchObjectView *)indirectSelector {
//	return [[[self window] windowController] iSelector];
//}
//
//- (BOOL)allowText { return allowText;  }
//- (void)setAllowText:(BOOL)flag {
//	allowText = flag;
//}
//
//- (BOOL)allowNonActions { return allowNonActions;  }
//- (void)setAllowNonActions:(BOOL)flag {
//  allowNonActions = flag;
//	recordsHistory = flag;
//}
//
//
//- (void)insertText:(id)aString {
//	aString = [[aString purifiedString] lowercaseString];
//	if (![partialString length]) {
//		[self updateHistory];
//		[self setSearchArray:sourceArray];
//	}
//	[partialString appendString:aString];
//	[self partialStringChanged];
//}
//
//- (void)partialStringChanged {
//	[self setSearchString:[[partialString copy] autorelease]];
//	
//	float searchDelay = 0;
//	if (fALPHA)
//		searchDelay *= [[QSLibrarian sharedInstance] estimatedTimeForSearchInSet:searchArray] *0.9;
//	else
//		[defaults floatForKey:kSearchDelay];
//	
//	
//	if (0 && moreComing) {
//		if ([searchTimer isValid]) [searchTimer invalidate];
//	} else {
//		if (![searchTimer isValid]) {
//			[searchTimer release];
//			searchTimer = [[NSTimer scheduledTimerWithTimeInterval:searchDelay target:self selector:@selector(performSearch:) userInfo:nil repeats:NO] retain];
//		}
//		[searchTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:searchDelay]];
//		
//		if ([self searchMode] != SearchFilterAll) [searchTimer fire];
//		
//	}
//	if (validSearch) {
//		[resultController->searchStringField setTextColor:[NSColor blueColor]];
//	}
//	
//	[self setVisibleString:[partialString uppercaseString]];
//	
//	float resetDelay = [defaults floatForKey:kResetDelay];
//	if (resetDelay) {
//		if ([resetTimer isValid]) {
//			[resetTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:resetDelay]];
//		} else {
//			[resetTimer release];
//			resetTimer = [[NSTimer scheduledTimerWithTimeInterval:resetDelay target:self selector:@selector(resetString) userInfo:nil repeats:NO] retain];
//		}
//	}
//}
//
//
//
//- (NSAttributedString *)attributedSubstringFromRange:(NSRange)theRange {
//	QSLog(@"attributedSubstringFromRange");
//	return [[NSAttributedString alloc] initWithString:[partialString substringWithRange:theRange]];
//}
//- (unsigned int) characterIndexForPoint:(NSPoint) thePoint {
//	QSLog(@"index");
//	return 0;
//}
//- (long) conversationIdentifier {
//	//		QSLog(@"conv");
//	return (long) self;
//}
////- (void)doCommandBySelector:(SEL)aSelector {
////}
//- (NSRect) firstRectForCharacterRange:(NSRange) theRange {
//	//		QSLog(@"rect");
//	return NSZeroRect;
//}
//- (BOOL)hasMarkedText {
//	//			QSLog(@"marked?");
//	return NO;
//}
////- (void)insertText:(id)aString {
////}
//- (NSRange) markedRange {
//	//		QSLog(@"rang");
//	return NSMakeRange([partialString length] -1, 1);
//}
//- (NSRange) selectedRange {
//	//		QSLog(@"selectr");
//	return NSMakeRange(NSNotFound, 0);
//}
//- (void)setMarkedText:(id)aString selectedRange:(NSRange)selRange {
//	if ([(NSString *)aString length]) {
//		QSLog(@"setmark %@ %d, %d", [aString string] , selRange.location, selRange.length);
//		aString = [[[aString string] purifiedString] lowercaseString];
//		[partialString setString:aString];
//		[self partialStringChanged];
//	}
//}
//- (void)unmarkText {
//	//	QSLog(@"Unmark");
//}
//- (NSArray *)validAttributesForMarkedText {
//	return [NSArray array];
//}
//
//- (void)viewWillMoveToSuperview:(NSView *)newSuperview {
//	if (!newSuperview) {
//		
//		[self reset:self];
//	}
//}
//
//
//- (NSArrayController *)resultArrayController {
//  return [[resultArrayController retain] autorelease];  
//}
//@end



@end




@implementation QSSearchController (History)
- (void)showHistoryObjects {
	NSMutableArray *array = [historyArray valueForKey:@"selection"];
	[self setSourceArray:array];
	[self setResultArray:array];
}

- (NSDictionary *)historyState {
	QSObject *currentValue = [self objectValue];
	if (!currentValue) return nil;
	NSMutableDictionary *state = [NSMutableDictionary dictionary];
	[state setObject:currentValue forKey:@"selection"];
//	if (resultArray) [state setObject:resultArray forKey:@"resultArray"];
//	if (sourceArray) [state setObject:sourceArray forKey:@"sourceArray"];
//	if (visibleString) [state setObject:visibleString forKey:@"visibleString"];
	return state;
}

- (void)setHistoryState:(NSDictionary *)state {	
	[self setSourceArray:[state objectForKey:@"sourceArray"]];
	[self setResultArray:[state objectForKey:@"resultArray"]];
	[self setVisibleString:[state objectForKey:@"visibleString"]];
	[self selectObject:[state objectForKey:@"selection"]];
}


//- (id)nextHistoryState {
//	QSLog(@"select in history %d %@", historyIndex, [historyArray valueForKeyPath:@"selection.displayName"]);
//	if ([historyArray count])
//		return [historyArray objectAtIndex:0]; 		
//	return nil;
//}
- (void)switchToHistoryState:(int)i {
	if (VERBOSE) QSLog(@"select in history %d %@", i, [historyArray valueForKeyPath:@"selection.displayName"]);
	//	
	if (i<[historyArray count])
		[self setHistoryState:[historyArray objectAtIndex:i]]; 	
}
- (void)clearHistory {
	[historyArray removeAllObjects];
	historyIndex = 0;
}
#define MAX_HISTORY_COUNT 10
- (void)updateHistory {
  
	if (!recordsHistory) return;
	// [NSDictionary dictionaryWithObjectsAndKeys:[self objectValue] , @"object", nil];
	//  
	
	if ( [self objectValue])
		[QSHist addObject:[self objectValue]];
	NSDictionary *state = [self historyState];
	//	if (!state)
	//		[history removeObject:currentValue];
	
	historyIndex = -1;
	if (state)
		[historyArray insertObject:state atIndex:0];
	if ([historyArray count] >  MAX_HISTORY_COUNT) [historyArray removeLastObject];
  //	if (VERBOSE) QSLog(@"history %d items", [historyArray count]);
}

- (void)goForward:(id)sender {
	if (VERBOSE) QSLog(@"goForward");
	if (historyIndex>0) {
		[self switchToHistoryState:--historyIndex];
	} else {
		[resultController bump:(4)]; 	
	}
}
- (void)goBackward:(id)sender {
	if (VERBOSE) QSLog(@"goBackward");
  
	if (historyIndex == -1) {
		[self updateHistory];
		historyIndex = 0;
	}
	if (historyIndex+1<[historyArray count]) {
		[self switchToHistoryState:++historyIndex];
	} else {
		[resultController bump:(-4)]; 	
	}
}

- (BOOL)objectIsInCollection:(QSObject *)thisObject {
	return NO; 	
}


@end







@implementation QSSearchController (Browsing)
- (void)moveWordRight:(id)sender {
	[self browse:1];
	
}
- (void)moveWordLeft:(id)sender {
	[self browse:-1];
	
}
- (void)moveRight:(id)sender {
	[self browse:1];
	
}
- (void)moveLeft:(id)sender {
	[self browse:-1];
}

- (void)browse:(int)direction {
	NSArray *newObjects = nil;
	QSBasicObject * newSelectedObject = [[resultArrayController selectedObjects] lastObject];
	QSBasicObject * parent = nil;
	NSArray *siblings;
	//if (self == [self actionSelector]) {
	//}
	
	BOOL alt = ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) > 0;
  
	//   QSLog(@"child %d %d", [[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask, [[NSApp currentEvent] modifierFlags]);
	if (direction>0) {
		//Should show childrenLevel
		newObjects = (alt?[newSelectedObject altChildren] :[newSelectedObject children]);
		if ([newObjects count]) {
			[parentStack addObject:newSelectedObject];
			// if (VERBOSE) QSLog(@"addobject %@ %@", newSelectedObject, newObjects);
		}
		//		newSelectedObject = [[self nextHistoryState] objectForKey:@"selection"];
		//		if (![newObjects containsObject:newSelectedObject]) {
		//			QSLog(@"notsel %@", newSelectedObject);
		//		} else {
		//			QSLog(@"reselecting %@", newSelectedObject);
		//		}
		newSelectedObject = nil;
	} else {
		parent = [newSelectedObject parent];
		
		
		if (parent && [[NSApp currentEvent] modifierFlags] & NSControlKeyMask) {
			[parentStack removeAllObjects];
		} else if ([parentStack count]) {
			browsing = YES;
			
			parent = [parentStack lastObject];  
			// ***warning   * this should check for a valid parent
			[[parent retain] autorelease];
			[parentStack removeLastObject];
			
			//		if (VERBOSE) QSLog(@"Using parent from stack: %@ (%@) ", parent, [parentStack componentsJoinedByString:@", "]);
			//    if (
			// && ![[parent children] containsObject:newSelectedObject])
		}
		
		//[[parent children] containsObject:newSelectedObject]
		
		if (!browsing && [self searchMode] == SearchFilterAll && [[resultController window] isVisible]) {
			//Maintain selection, but show siblings 
			siblings = (alt?[parent altChildren] :[parent children]);
			newObjects = siblings;
			
		} else {
			//Should show parent's level
			
			newSelectedObject = parent;
			if (newSelectedObject) {
				if ([historyArray count] >historyIndex) {
          //	if (VERBOSE) QSLog(@"history %@", [historyArray valueForKeyPath:@"selection.displayName"]);
					if ([[[historyArray objectAtIndex:historyIndex+1] valueForKey:@"selection"] isEqual:parent]) {
						if (VERBOSE) QSLog(@"Parent Missing, Using History");
						[self goBackward:self];
						return;
					}
					if (VERBOSE) QSLog(@"Parent Missing, No History, %@", [[historyArray objectAtIndex:0] valueForKey:@"selection"]);
				}
				
				if (!newObjects)
					newObjects = (alt?[newSelectedObject altSiblings] :[newSelectedObject siblings]);
				if (![newObjects containsObject:newSelectedObject])
					newObjects = [newSelectedObject altSiblings];
				
				if (!newObjects && [parentStack count]) {
					parent = [parentStack lastObject];
					newObjects = [parent children];
				}
				
				if (!newObjects && [historyArray count]) {
					//					
					if ([[[historyArray objectAtIndex:0] valueForKey:@"selection"] isEqual:parent]) {
						if (VERBOSE) QSLog(@"Parent Missing, Using History");
						
						[self goBackward:self];
						return;
					}
					if (VERBOSE) QSLog(@"Parent Missing, No History");
					
				}
			}
		}
		
  }
  
  
  if ([newObjects count]) {
    browsing = YES;
    
    [self updateHistory];
    [self saveMnemonic];
    [self clearSearch];  
    //int defaultMode = [defaults integerForKey:kBrowseMode];
    //[self setSearchMode:defaultMode?defaultMode:SearchSnap];
    [self setResultArray:(NSMutableArray *)newObjects]; // !!!:nicholas:20040319 
    [self setSourceArray:(NSMutableArray *)newObjects];
    
    if (!newSelectedObject)
      [self selectIndex:0];
    else
      [self selectObject:newSelectedObject];
    
    
    [self setVisibleString:@"Browsing"];
    
    [self showResultView:self];  
  } else if (![[NSApp currentEvent] isARepeat]) {
    
    [self showResultView:self];  
    if ([[resultController window] isVisible])
      [resultController bump:(direction*4)];
    else
      NSBeep();
  }
  
  
}


@end
