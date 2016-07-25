

#import "QSPreferenceKeys.h"
#import "QSAction.h"
#import "QSObject.h"
#import "QSResultController.h"
#import "QSSearchObjectView.h"

#import "QSInterfaceController.h"
#import "QSIconLoader.h"
#import "QSLibrarian.h"
#import "QSWindow.h"

#import "AppKitPrivate.h"
#import "QSImageAndTextCell.h"
#import "QSRankCell.h"
#import "QSObjectCell.h"

#import "QSObject_Menus.h"

#define MAX_VISIBLE_COLUMNS 4
#define COLUMNID_TYPE		@"TypeColumn"
#define COLUMNID_NAME		@"NameColumn"
#define COLUMNID_RANK	 	@"RankColumn"
#define COLUMNID_HASCHILDREN	@"hasChildren"
#define COLUMNID_EQUIV	 	@"EquivColumn"

#define IconLoadNotification @"IconsLoaded"

#import "QSTextProxy.h"

NSMutableDictionary *kindDescriptions = nil;

@interface QSResultController () <NSTableViewDataSource, NSWindowDelegate> {
@private

    NSInteger _selectedResult;
    QSObject *_selectedItem;

    BOOL _shouldSaveWindowSize;
    NSArray *_currentResults;
    NSInteger _scrollViewTrackingRect;
    NSUInteger _windowHeight;

    QSIconLoader *_resultIconLoader;
    QSIconLoader *_resultChildIconLoader;

    NSTimer *_childrenLoadTimer;

    QSSearchOrder _searchOrder;
    QSSearchMode _searchMode;
}

@end

@implementation QSResultController

+ (void)initialize {
    if (!kindDescriptions)
        kindDescriptions = [[NSMutableDictionary alloc] initWithContentsOfFile:
                            [[NSBundle mainBundle] pathForResource:@"QSKindDescriptions" ofType:@"plist"]];
}

+ (id)sharedInstance {
	static id _sharedInstance;
	if (!_sharedInstance) _sharedInstance = [[[self class] allocWithZone:nil] init];
	return _sharedInstance;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"rowHeight"]) {
        if ([change objectForKey:NSKeyValueChangeNewKey]) {
            QSObjectCell *nameCell = (QSObjectCell *)[[_resultTable tableColumnWithIdentifier: COLUMNID_NAME] dataCell];
            BOOL shouldShowDetails = ([[change objectForKey:NSKeyValueChangeNewKey] doubleValue] >= 34.0);
            [nameCell setShowDetails:shouldShowDetails];
            return;
        }
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark -
#pragma mark Lifetime
- (id)init {
	self = [self initWithWindowNibName:@"ResultWindow"];
    if (!self) return nil;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(objectIconModified:) name:QSObjectIconModified object:nil];

	return self;
}

- (id)initWithObjectView:(QSSearchObjectView *)objectView {
    NSParameterAssert(objectView != nil);

    self = [self init];
    if (!self) return nil;

    _objectView = objectView;

    return self;
}

- (void)windowDidLoad {
	[(QSWindow *)[self window] setHideOffset:NSMakePoint(32, 0)];
	[(QSWindow *)[self window] setShowOffset:NSMakePoint(16, 0)];
    _windowHeight = [[self window] frame].size.height;
	[self setupResultTable];

	[_splitView setAutosaveName:@"QSResultWindowSplitView"];
    
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"QSResultsShowChildren"]) {
		NSView *tableView = [_resultTable enclosingScrollView];
		[tableView removeFromSuperview];
		[tableView setFrame:[_splitView frame]];
		[tableView setAutoresizingMask:[_splitView autoresizingMask]];

		[[_splitView superview] addSubview:tableView];
		_resultChildTable = nil;
		[_splitView removeFromSuperview];
	}
    NSUserDefaultsController *sucd = [NSUserDefaultsController sharedUserDefaultsController];
    [sucd addObserver:self
           forKeyPath:@"values.QSAppearance3B"
              options:0
              context:nil];
    [[self window] bind:@"backgroundColor" toObject:sucd withKeyPath:@"values.QSAppearance2B" options:@{NSValueTransformerNameBindingOption : NSUnarchiveFromDataTransformerName}];
    
    for (NSView *view in @[_searchModeField, _searchStringField, _selectionView]) {
        [view bind:@"textColor" toObject:sucd withKeyPath:@"values.QSAppearance2T" options:@{NSValueTransformerNameBindingOption : NSUnarchiveFromDataTransformerName}];
    }
    
    void (^b)(QSTableView *) = ^(QSTableView * t){
        [@{
           @"backgroundColor" : @"values.QSAppearance3B",
           @"highlightColor" : @"values.QSAppearance3A",
           } enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
               [t bind:key toObject:sucd withKeyPath:obj options:@{NSValueTransformerNameBindingOption : NSUnarchiveFromDataTransformerName}];
           }];
        
        [[[t tableColumnWithIdentifier:@"NameColumn"] dataCell] bind:@"textColor"
                                                            toObject:sucd
                                                         withKeyPath:@"values.QSAppearance3T"
                                                             options:@{NSValueTransformerNameBindingOption : NSUnarchiveFromDataTransformerName}];
        [t addObserver:self
            forKeyPath:@"rowHeight"
               options:NSKeyValueObservingOptionNew
               context:nil];
        
        [t setOpaque:NO];
    };
    b(_resultTable);
    b(_resultChildTable);
}

- (void)dealloc {
	NSUserDefaultsController *sucd = [NSUserDefaultsController sharedUserDefaultsController];
	[sucd removeObserver:self forKeyPath:@"values.QSAppearance3B"];
    
    for (QSTableView *t in @[_resultTable, _resultChildTable]) {
        [[[t tableColumnWithIdentifier:@"NameColumn"] dataCell] unbind:@"textColor"];
        [t unbind:@"backgroundColor"];
        [t unbind:@"highlightColor"];
        [t removeObserver:self forKeyPath:@"rowHeight"];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}

#pragma mark -
#pragma mark Accessors, Utilities

- (void)updateScrollViewTrackingRect {
	NSView *view = [[self window] contentView];
	if (_scrollViewTrackingRect) [view removeTrackingRect:_scrollViewTrackingRect];
	_scrollViewTrackingRect = [view addTrackingRect:[view frame] owner:self userData:nil assumeInside:NO];
}

- (QSSearchMode)searchMode {
    return _searchMode;
}

- (void)setSearchMode:(QSSearchMode)searchMode {
    [self willChangeValueForKey:@"searchMode"];
    _searchMode = searchMode;
	switch (searchMode) {
		default:
			_searchMode = QSSearchModeAll;
        case QSSearchModeAll:
            [_filterCatalog setState:NSOnState];
            [_filterResults setState:NSOffState];
            [_snapToBest setState:NSOffState];
            [_searchModeField setStringValue:NSLocalizedString(@"Filter Catalog", @"")];
            break;

        case QSSearchModeFilter:
            [_filterResults setState:NSOnState];
            [_filterCatalog setState:NSOffState];
            [_snapToBest setState:NSOffState];
            [_searchModeField setStringValue:NSLocalizedString(@"Filter Results", @"")];
            break;

        case QSSearchModeSnap:
            [_snapToBest setState:NSOnState];
            [_filterResults setState:NSOffState];
            [_filterCatalog setState:NSOffState];
            [_searchModeField setStringValue:NSLocalizedString(@"Snap to Best", @"")];
            break;
    }
    [self didChangeValueForKey:@"searchMode"];
}

- (IBAction)changeSearchMode:(id)sender {
	self.searchMode = [sender tag];

	if ([[self nextResponder] respondsToSelector:@selector(changeSearchMode:)]) {
		[[self nextResponder] performSelector:@selector(changeSearchMode:) withObject:sender];
	}
}

- (QSSearchOrder)searchOrder {
    return _searchOrder;
}

- (void)setSearchOrder:(QSSearchOrder)searchOrder {
    [self willChangeValueForKey:@"searchOrder"];
    _searchOrder = searchOrder;
    switch (searchOrder) {
        case QSSearchOrderByName:
            [_sortByName setState:NSOnState];
            [_sortByScore setState:NSOffState];
			[_resultTable setSortDescriptors:[NSSortDescriptor descriptorArrayWithKey:@"name" ascending:YES selector:@selector(localizedCompare:)]];
            break;

        case QSSearchOrderByScore:
            [_sortByName setState:NSOffState];
            [_sortByScore setState:NSOnState];
			[_resultTable setSortDescriptors:[NSSortDescriptor descriptorArrayWithKey:@"score" ascending:NO]];
            break;

        default:
            _searchOrder = QSSearchOrderByScore;
            break;
    }
    [self willChangeValueForKey:@"searchOrder"];
}

- (IBAction)changeSearchOrder:(id)sender {
    self.searchOrder = [sender tag];
}

- (void)bump:(NSInteger)i {
	NSRect frame = [[self window] frame];
	NSInteger j;
	for (j = 1; j <= 8; j++)
		[[self window] setFrameOrigin:NSOffsetRect(frame, i*j/8, 0) .origin];
	for (; j >= 0; j--)
		[[self window] setFrameOrigin:NSOffsetRect(frame, i*j/8, 0) .origin];
}

- (void)loadChildren {
	if (NSEqualRects(NSZeroRect, [_resultChildTable visibleRect]) )
        return;
	[_resultChildTable reloadData];
}

/*- (void)setSplitLocation {
	NSNumber *resultWidth = [[NSUserDefaults standardUserDefaults] objectForKey:kResultTableSplit];
    
	if (resultWidth) {
		NSView *firstView = [[splitView subviews] objectAtIndex:0];
		NSRect frame = [firstView frame];
		frame.size.width = [resultWidth floatValue] *NSWidth([splitView frame]);
        
		NSLog(@"%f", frame.size.width);
        
		[firstView setFrame:frame];
        
		frame.origin.x += NSWidth(frame);
		frame.size.width = NSWidth([splitView frame]) - NSWidth(frame) - [splitView dividerThickness];
        
		[[[splitView subviews] lastObject] setFrame:frame];
        
		[splitView adjustSubviews];
		[splitView display];
	}
}*/

#pragma mark -
#pragma mark Icon Loading

- (void)iconLoader:(QSIconLoader *)loader loadedIndex:(NSInteger)m inArray:(NSArray *)array {
    QSGCDMainAsync(^{
        if (loader == _resultIconLoader) {
            [_resultTable setNeedsDisplayInRect:[_resultTable rectOfRow:m]];
        } else if (loader == _resultChildIconLoader) {
            [_resultChildTable setNeedsDisplayInRect:[_resultChildTable rectOfRow:m]];
        }
    });
}

- (BOOL)iconsAreLoading {
    return [_resultIconLoader isLoading] || [_resultChildIconLoader isLoading];
}

- (QSIconLoader *)resultIconLoader {
	if (!_resultIconLoader) {
		[self setResultIconLoader:[QSIconLoader loaderWithArray:[self currentResults]]];
		[_resultIconLoader setDelegate:self];
	}
	return _resultIconLoader;
}

- (void)setResultIconLoader:(QSIconLoader *)aResultIconLoader {
	//NSLog(@"setloader %@", aResultIconLoader);
	if (_resultIconLoader != aResultIconLoader) {
		[_resultIconLoader invalidate];
		_resultIconLoader = aResultIconLoader;
	}
}

- (QSIconLoader *)resultChildIconLoader {
    if (!_resultChildIconLoader) {
        [self setResultChildIconLoader:[QSIconLoader loaderWithArray:[_selectedItem children]]];
        [_resultChildIconLoader setDelegate:self];
    }
    return _resultChildIconLoader;
}

- (void)setResultChildIconLoader:(QSIconLoader *)aResultChildIconLoader {
	if (_resultChildIconLoader != aResultChildIconLoader) {
		[_resultChildIconLoader invalidate];
		_resultChildIconLoader = aResultChildIconLoader;
	}
}

- (void)objectIconModified:(NSNotification *)notif
{
    QSGCDMainAsync(^{
        // if results are showing, check for icons that need updating
        if ([[self window] isVisible]) {
            QSObject *object = [notif object];
            // if updated object is is in the results, update it in the list
            NSUInteger ind = [_currentResults indexOfObject:object];
            if (ind != NSNotFound) {
                [_resultTable setNeedsDisplayInRect:[_resultTable rectOfRow:ind]];
            }
            // if updated object is is in the child results, update it in the list
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"QSResultsShowChildren"]) {
                ind = [[[self selectedItem] children] indexOfObject:object];
                if (ind != NSNotFound) {
                    [_resultChildTable setNeedsDisplayInRect:[_resultChildTable rectOfRow:ind]];
                }
            }
        }
    });
}

#pragma mark -
#pragma mark Actions
- (IBAction)defineMnemonic:(id)sender {
	if (![self.objectView mnemonicDefined])
		[self.objectView defineMnemonic:sender];
	else
		[self.objectView removeMnemonic:sender];
}

- (IBAction)setScore:(id)sender {return;}

- (IBAction)clearMnemonics:(id)sender {
	[self.objectView removeImpliedMnemonic:sender];
}

- (IBAction)omitItem:(id)sender {
	[[QSLibrarian sharedInstance] setItem:[self.objectView objectValue] isOmitted:YES];
}

- (IBAction)assignAbbreviation:(id)sender {
	[[QSLibrarian sharedInstance] assignCustomAbbreviationForItem:[self.objectView objectValue]];
}

- (void)arrayChanged:(NSNotification*)notif {
    QSGCDMainSync(^{
        [self setResultIconLoader:nil];
        [self setCurrentResults:[self.objectView resultArray]];
        [self updateStatusString];
        
        [_resultTable reloadData];
        
        //visibleRange = [resultTable rowsInRect:[resultTable visibleRect]];
        //	NSLog(@"arraychanged %d", [[self currentResults] count]);
        //[self threadedIconLoad];
        [[self resultIconLoader] loadIconsInRange:[_resultTable rowsInRect:[_resultTable visibleRect]]];
    });
}

- (NSRect)windowFrame {
    NSRect windowFrame = [[self window] frame];
    NSUInteger resultCount = [_currentResults count];
    NSUInteger verticalSpacing = [_resultTable intercellSpacing].height;
    NSUInteger newWindowHeight =  (([_resultTable rowHeight] + verticalSpacing) * resultCount) + 31;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"QSResultsShowChildren"]) {
        // Be sure to chose the taller of the two: results list or results child list
        NSUInteger childResultHeight = (([_resultChildTable rowHeight] + [_resultChildTable intercellSpacing].height) * [_resultChildTable numberOfRows]) + 31;
        newWindowHeight = MAX(newWindowHeight, childResultHeight);
    }
    windowFrame.size.height =  newWindowHeight > _windowHeight || [_currentResults count] == 0 ? _windowHeight : newWindowHeight;
    if (windowFrame.size.height != [[self window] frame].size.height) {
        windowFrame.origin.y = windowFrame.origin.y - (windowFrame.size.height - [[self window] frame].size.height);
    }
    return windowFrame;
}

- (void)updateSelectionInfo {
	_selectedResult = [_resultTable selectedRow];
    
	if (_selectedResult < 0 || ![[self currentResults] count]) return;
	QSObject *newSelectedItem = [[self currentResults] objectAtIndex:_selectedResult];
    
	if (_selectedItem != newSelectedItem) {
		[self setSelectedItem:newSelectedItem];
		[_resultChildTable noteNumberOfRowsChanged];
        [self updateStatusString];

		NSEvent *event = [NSApp currentEvent];
		// Check the event can have isARepeat called on it safely. From the docs for -[NSEvent isARepeat]: "Raises an NSInternalInconsistencyException if sent to an NSFlagsChanged event or other non-key event."
		BOOL validKeyEvent = ([event type] == NSKeyDown) || ([event type] == NSKeyUp);
		if ([event modifierFlags] & NSFunctionKeyMask && validKeyEvent && [event isARepeat]) {
			if ([_childrenLoadTimer isValid]) {
				[_childrenLoadTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
			} else {
				// ***warning  * this should be triggered by the keyUp
                if (![NSApp nextEventMatchingMask:NSKeyUpMask untilDate:[NSDate dateWithTimeIntervalSinceNow:0.333] inMode:NSDefaultRunLoopMode dequeue:NO]) {
                    _childrenLoadTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(loadChildren) userInfo:nil repeats:NO];
                }
			}
		} else {
			[self loadChildren];
		}
	}

    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:kUseEffects] boolValue] && [QSInterfaceController firstResponder] == self.objectView) {
        NSRect windowFrame = [self windowFrame];
        _shouldSaveWindowSize = NO;
        [[self window] setFrame:windowFrame display:YES animate:YES];
        _shouldSaveWindowSize = YES;
    }
    
    /* Restart the icon loading for the children view */
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"QSResultsShowChildren"]) {
        [self setResultChildIconLoader:nil];
        [[self resultChildIconLoader] loadIconsInRange:[_resultChildTable rowsInRect:[_resultChildTable visibleRect]]];
    }
}

- (void)updateStatusString
{
    // HenningJ 20110419 there is no localized version of "%d of %d". Additionally, something goes wrong while trying to localize it.
    // NSString *fmt = NSLocalizedStringFromTableInBundle(@"%d of %d", nil, [NSBundle bundleForClass:[self class]], @"");
    NSString *status = [NSString stringWithFormat:@"%ld of %ld", (long)_selectedResult + 1, (long)[[self currentResults] count]];
    if ([_resultTable rowHeight] < 34 && [_selectedItem details]) {
        status = [status stringByAppendingFormat:@" %C %@", (unsigned short)0x25B8, [_selectedItem details]];
    }
    [(NSTextField *)_selectionView setStringValue:status];
}

#pragma mark -
#pragma mark NSResponder
//- (void)scrollWheel:(NSEvent *)theEvent {
//	[resultTable scrollWheel:theEvent];
//}

- (void)keyDown:(NSEvent *)theEvent {
	NSString *characters;
	unichar c;
	NSUInteger characterIndex, characterCount;

	// There could be multiple characters in the event.
	characters = [theEvent charactersIgnoringModifiers];

	characterCount = [characters length];
	for (characterIndex = 0; characterIndex < characterCount;
		 characterIndex++) {
		c = [characters characterAtIndex: characterIndex];
		switch(c) {

			case '\r': //Return
					  //[self sendAction:[self action] to:[self target]];
				[[self.objectView controller] executeCommand:self];
				break;
			case '\t': //Tab
			case 25: //Back Tab
			case 27: //Escape
				[[self window] orderOut:self];
				[self.objectView keyDown:theEvent];
				return;
		}
	}

}

#pragma mark -
#pragma mark NSWindow Delegate

// called twice when a user resized the results window
- (void)windowDidResize:(NSNotification *)aNotification {
    if (!_shouldSaveWindowSize) {
        return;
    }
    [[self resultIconLoader] loadIconsInRange:[_resultTable rowsInRect:[_resultTable visibleRect]]];
	if (!NSEqualRects(NSZeroRect, [_resultChildTable visibleRect]) && [self numberOfRowsInTableView:_resultChildTable])
		[[self resultChildIconLoader] loadIconsInRange:[_resultChildTable rowsInRect:[_resultChildTable visibleRect]]];

	[self updateScrollViewTrackingRect];
    
    // saves size for result window when it is resized
    [[self window] saveFrameUsingName:@"QSResultWindow"];
    _windowHeight = [self window].frame.size.height;
}

#pragma mark -
#pragma mark NSSplitView Delegate
- (CGFloat) splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset {
	//NSLog(@"constrainMax: %f, %d", proposedMax, offset);
	// return proposedMax-36;
	return proposedMax; // - 165;
}

- (CGFloat) splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset {
	//NSLog(@"constrainMin: %f, %d", proposedMin, offset);
	return NSWidth([sender frame]) / 2;
}

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview {
	//NSLog(@"collapse");
	return subview != [_resultTable enclosingScrollView];
	// if (subview == infoBox) return YES;
	// else return NO;
}

- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize {
	CGFloat dividerThickness = [sender dividerThickness];
	id sv1 = [[sender subviews] objectAtIndex:0];
	id sv2 = [[sender subviews] objectAtIndex:1];
	NSRect leftFrame = [sv1 frame];
	NSRect rightFrame = [sv2 frame];
	NSRect newFrame = [sender frame];

	// if (sender != m_SourceItemSplitView) return;

	leftFrame.origin = NSMakePoint(0, 0);
	leftFrame.size.height = newFrame.size.height;
	rightFrame.size.height = newFrame.size.height;

	rightFrame.size.width = MIN(rightFrame.size.width, newFrame.size.width/2);
	if (rightFrame.size.width < 32) rightFrame.size.width = 0;

	leftFrame.size.width = newFrame.size.width - rightFrame.size.width - dividerThickness;

	rightFrame.origin = NSMakePoint(leftFrame.size.width + dividerThickness, 0);

	[sv1 setFrame:leftFrame];
	[sv2 setFrame:rightFrame];
}

- (void)splitViewDidResizeSubviews:(NSNotification *)notification {
	if ([[NSApp currentEvent] type] == NSLeftMouseDragged) {
        CGFloat split = NSWidth([[_resultChildTable enclosingScrollView] frame]) / NSWidth([_splitView frame]);
        [[NSUserDefaults standardUserDefaults] setFloat:split
                                                 forKey:kResultTableSplit];
    }
}
@end

@implementation QSResultController (Table)

//Table Methods

- (void)setupResultTable {
	[_resultTable setTarget:self];

	[_resultTable setAction:@selector(tableViewAction:)];
	[_resultTable setDoubleAction:@selector(tableViewDoubleAction:)];
	[_resultTable setVerticalMotionCanBeginDrag:NO];

	QSObjectCell *objectCell = [[QSObjectCell alloc] init];
	NSTableColumn *tableColumn = [_resultTable tableColumnWithIdentifier:COLUMNID_NAME];
    if ([_resultTable rowHeight] < 34.0) {
        [objectCell setShowDetails:NO];
    }
	[tableColumn setDataCell:objectCell];

	tableColumn = [_resultChildTable tableColumnWithIdentifier:COLUMNID_NAME];
	[tableColumn setDataCell:objectCell];

	tableColumn = [_resultTable tableColumnWithIdentifier:COLUMNID_RANK];

	NSCell *rankCell = [[QSRankCell alloc] init];
	[tableColumn setDataCell:rankCell];

	//[searchModePopUp setEnabled:fALPHA];

	tableColumn = [_resultTable tableColumnWithIdentifier:COLUMNID_EQUIV];
	[[tableColumn dataCell] setFont:[NSFont systemFontOfSize:9]];
	[[tableColumn dataCell] setTextColor:[NSColor darkGrayColor]];

	[_resultTable removeTableColumn:tableColumn];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewChanged:) name:NSViewBoundsDidChangeNotification object:[[_resultTable enclosingScrollView] contentView]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(childViewChanged:) name:NSViewBoundsDidChangeNotification object:[[_resultChildTable enclosingScrollView] contentView]];
}

- (void)viewChanged:(NSNotification*)notif {
    [[self resultIconLoader] loadIconsInRange:[_resultTable rowsInRect:[_resultTable visibleRect]]];
}

- (void)childViewChanged:(NSNotification*)notif {
    [[self resultChildIconLoader] loadIconsInRange:[_resultChildTable rowsInRect:[_resultChildTable visibleRect]]];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	if (tableView == _resultChildTable) {
		return [[_selectedItem children] count];
	} else {
		return [[self currentResults] count];
	}
}

- (BOOL)tableView:(NSTableView *)aTableView rowIsSeparator:(NSInteger)rowIndex {
	return NO;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldDrawRow:(NSInteger)rowIndex inClipRect:(NSRect)clipRect {
	clipRect = [aTableView rectOfRow:rowIndex];
	// clipRect.origin.y += (int) (NSHeight(clipRect)/2);
	// clipRect.size.height = 1.0;
	[[NSColor colorWithDeviceWhite:0.95 alpha:1.0] set];

	NSRectFill(clipRect);

	QSObject *object = [[self currentResults] objectAtIndex:rowIndex];
	[[object name] drawInRect:clipRect withAttributes:nil];

	return NO;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if (tableView == _resultTable && [[self currentResults] count] > (NSUInteger)row) {
		QSObject *thisObject = [[self currentResults] objectAtIndex:row];

		if ([[tableColumn identifier] isEqualToString:COLUMNID_TYPE]) {
			NSString *kind = [thisObject kind];
			NSString *desc = [kindDescriptions objectForKey:kind];

			return (desc?desc:kind);
		}
		if ([[tableColumn identifier] isEqualToString:COLUMNID_NAME]) {
			return nil; //[[thisObject retain] autorelease];
		}
		if ([[tableColumn identifier] isEqualToString: COLUMNID_HASCHILDREN]) {

			return([thisObject hasChildren] ? [QSResourceManager imageNamed:@"ChildArrow"] :nil);
		}

	}
	return nil;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	if ([[aTableColumn identifier] isEqualToString:COLUMNID_NAME]) {
		NSArray *array = [self currentResults];
		if (aTableView == _resultChildTable) array = [_selectedItem children];
        
        // avoid attempting to access objects in a nonexistent array or an index out of bounds
        if (!array || rowIndex >= (NSInteger)[array count]) {
            return;
        }
		QSObject *thisObject = [array objectAtIndex:rowIndex];

		[aCell setRepresentedObject:thisObject];
        [aCell setState:[self.objectView objectIsInCollection:thisObject]];
	}
	if ([[aTableColumn identifier] isEqualToString:COLUMNID_RANK]) {
		NSArray *array = [self currentResults];

        if (!array || rowIndex >= (NSInteger)[array count]) {
            return;
        }
		QSRankedObject *thisObject = [array objectAtIndex:rowIndex];

		[(QSRankCell *)aCell setScore:[thisObject score]];
		[(QSRankCell *)aCell setOrder:[thisObject order]];
		//int order = [thisObject order];
		// NSLog(@"score %f %@", score, thisObject);
		//return [thisObject retain]; //[NSNumber numberWithInt:(score*100) +order?1000:0];
	}
	return;
}
- (NSMenu *)tableView:(NSTableView*)tableView menuForTableColumn:(NSTableColumn *)column row:(NSInteger)row {
	[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:(row ? row : 0)] byExtendingSelection:NO];

	NSArray *array = [self currentResults];
	QSObject *thisObject = [array objectAtIndex:row];

    return [thisObject rankMenuWithTarget:self.objectView];
}

- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard {
	[[[self currentResults] objectAtIndex:[[rows objectAtIndex:0] integerValue]]putOnPasteboard:pboard includeDataForTypes:nil];
	return YES;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	if (aNotification && [aNotification object] != _resultTable) return;

	if (_selectedResult != -1 && _selectedResult != [_resultTable selectedRow]) {
		_selectedResult = [_resultTable selectedRow];
        [self.objectView selectIndex:[_resultTable selectedRow]];
		[self updateSelectionInfo];
	}
}

- (IBAction)tableViewAction:(id)sender {
	//NSLog(@"action %@ %d %d", sender, [sender clickedColumn] , [sender clickedRow]);
	if ([sender clickedRow] == -1) {

	} else if ([sender clickedColumn] == 0) {
		NSPoint origin = [sender rectOfRow:[sender clickedRow]].origin;
		origin.y += [sender rowHeight];
		NSEvent *theEvent = [NSEvent mouseEventWithType:NSRightMouseDown location:[sender convertPoint:origin toView:nil]
										modifierFlags:0 timestamp:0 windowNumber:[[sender window] windowNumber] context:nil eventNumber:0 clickCount:1 pressure:0];

	//	[tableView selectRow:row byExtendingSelection:NO];

		NSArray *array = [self currentResults];
		QSObject *thisObject = [array objectAtIndex:[sender clickedRow]];
        [NSMenu popUpContextMenu:[thisObject rankMenuWithTarget:self.objectView] withEvent:theEvent forView:sender];

	}
}

- (IBAction)tableViewDoubleAction:(id)sender {
    [[self.objectView controller] executeCommand:self];
}

- (void)tableView:(NSTableView *)tv sortDescriptorsDidChange:(NSArray<NSSortDescriptor *> *)oldDescriptors
{
	[[self.objectView resultArray] sortUsingDescriptors:[tv sortDescriptors]];
	[self arrayChanged:nil];
	if ([[self.objectView resultArray] count]) {
		id firstObject = [[self.objectView resultArray] objectAtIndex:0];
		[self.objectView selectObjectValue:firstObject];
	}
}
@end
