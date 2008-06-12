

#define MAX_VISIBLE_COLUMNS 4
#define COLUMNID_TYPE		@"TypeColumn"
#define COLUMNID_NAME		@"NameColumn"
#define COLUMNID_RANK	 	@"RankColumn"
#define COLUMNID_HASCHILDREN	@"hasChildren"
#define COLUMNID_EQUIV	 	@"EquivColumn"

#define IconLoadNotification @"IconsLoaded"


@interface NSTableView (SingleRowDisplay)
- (void)_setNeedsDisplayInRow:(int)fp8;
@end 

@interface QSResultController (PrivateUtilities)
- (NSString*)fsPathToColumn:(int)column;
- (NSDictionary*)normalFontAttributes;
- (NSDictionary*)boldFontAttributes;
@end


#import "QSTextProxy.h"

NSMutableDictionary *kindDescriptions=nil;


@implementation QSResultController
+(void)initialize{
	kindDescriptions=[[NSMutableDictionary alloc]initWithContentsOfFile:
		[[NSBundle mainBundle]pathForResource:@"QSKindDescriptions" ofType:@"plist"]];
	
	//QSLog(@"%@",kindDescriptions);
}


+ (id)sharedInstance{
    static id _sharedInstance;
    if (!_sharedInstance) _sharedInstance = [[[self class] allocWithZone:[self zone]] init];
    return _sharedInstance;
}

- (id)init {
    self = [self initWithWindowNibName:@"ResultWindow"];
  [self windowNibPath];
    if (self) {
        focus=nil;
        loadingIcons=NO;
        loadingChildIcons=NO;
        iconTimer=nil;
        childrenLoadTimer=nil;
        selectedItem=nil;
		loadingRange=NSMakeRange(0,0);
		scrollViewTrackingRect=0;
		//[self setSplitLocation];
    }
    return self;
}

- (id)initWithFocus:(id)myFocus {
    self = [self init];
    if (self) {
        focus=myFocus;
    }
    return self;
}


- (NSTextField *)searchStringField {
  return [[searchStringField retain] autorelease];
}

- (NSTableView *)resultTable {
  return [[resultTable retain] autorelease];
}



- (void)reloadColors{
	NSData *data=[[NSUserDefaultsController sharedUserDefaultsController]
valueForKeyPath:@"values.QSAppearance3B"];
	NSColor *color=[NSUnarchiver unarchiveObjectWithData:data];
	[[self window] setOpaque:[color alphaComponent]==1.0f];	
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	[self reloadColors];
}

- (void)windowDidLoad{
    [(QSWindow *)[self window] setHideOffset:NSMakePoint(32,0)];
    [(QSWindow *)[self window] setShowOffset:NSMakePoint(16,0)];
    [self setupResultTable];
    //  [[[self window]contentView] flipSubviewsOnAxis:1];
	
	if (![[NSUserDefaults standardUserDefaults]boolForKey:@"QSResultsShowChildren"]){
		NSView *tableView=[resultTable enclosingScrollView];
		[[tableView retain]autorelease];
		[tableView removeFromSuperview];
		[tableView setFrame:[splitView frame]];
		[tableView setAutoresizingMask:[splitView autoresizingMask]];
		
		[[splitView superview]addSubview:tableView];		
		resultChildTable=nil;
		[splitView removeFromSuperview];
		
	}
	
	
	[[[resultTable tableColumnWithIdentifier:@"NameColumn"] dataCell] bind:@"textColor"
																  toObject:[NSUserDefaultsController sharedUserDefaultsController]
															   withKeyPath:@"values.QSAppearance3T"
																   options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:@"NSValueTransformerName"]];
	

	[[NSUserDefaultsController sharedUserDefaultsController]addObserver:self
															 forKeyPath:@"values.QSAppearance3B"
																options:0
																context:nil];

	[resultTable bind:@"backgroundColor"
			 toObject:[NSUserDefaultsController sharedUserDefaultsController]
		  withKeyPath:@"values.QSAppearance3B"
			  options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName
												  forKey:@"NSValueTransformerName"]];
	
	[self reloadColors];
	
	[resultTable bind:@"highlightColor"
			 toObject:[NSUserDefaultsController sharedUserDefaultsController]
		  withKeyPath:@"values.QSAppearance3A"
			  options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName
												  forKey:@"NSValueTransformerName"]];
	
	
	
	if ([[NSUserDefaults standardUserDefaults]boolForKey:@"QSResultsShowChildren"]){
		
		[[[resultChildTable tableColumnWithIdentifier:@"NameColumn"] dataCell] bind:@"textColor"
																		   toObject:[NSUserDefaultsController sharedUserDefaultsController]
																		withKeyPath:@"values.QSAppearance3T"
																			options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:@"NSValueTransformerName"]];
		
		
		[resultChildTable bind:@"backgroundColor"
					  toObject:[NSUserDefaultsController sharedUserDefaultsController]
				   withKeyPath:@"values.QSAppearance3B"
					   options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName
														   forKey:@"NSValueTransformerName"]];
		
		
		
		
	}		
	
	
	
	//	[[resultTable cornerView]setCell:[[[QSTableHeaderCell alloc]init]autorelease]];
	
	
    [[self window] setLevel:NSFloatingWindowLevel+1];
	
	//[[resultTable enclosingScrollView]setHasVerticalScroller:NO];
}

- (void) dealloc {
	[[[resultTable tableColumnWithIdentifier:@"NameColumn"] dataCell] unbind:@"textColor"];
	[resultTable unbind:@"backgroundColor"];
	[resultTable unbind:@"highlightColor"];
	[resultChildTable unbind:@"backgroundColor"];
	
	[super dealloc];
}

-(void)updateScrollViewTrackingRect{
	NSView *view=[[self window]contentView];
	if (scrollViewTrackingRect)[view removeTrackingRect:scrollViewTrackingRect];
    scrollViewTrackingRect=[view addTrackingRect:[view frame] owner:self userData:nil assumeInside:NO];
	
	
}
- (void)scrollWheel:(NSEvent *)theEvent{
	[resultTable scrollWheel:theEvent];
}
/*
- (void)mouseEntered:(NSEvent *)theEvent{
	[[resultTable enclosingScrollView]setHasVerticalScroller:YES];
}
- (void)mouseExited:(NSEvent *)theEvent{
	[[resultTable enclosingScrollView]setHasVerticalScroller:NO];
}
*/
- (IBAction)setSearchMode:(id)sender{
    [focus setSearchMode:[sender tag]];
}

- (void)bump:(int)i{
    NSRect frame=[[self window]frame];
    int j;
    for (j=1;j<=8;j++)
        [[self window]setFrameOrigin:NSOffsetRect(frame,i*j/8,0).origin];
    for (;j>=0;j--)
        [[self window]setFrameOrigin:NSOffsetRect(frame,i*j/8,0).origin];
    
}
- (void)keyDown:(NSEvent *)theEvent{
    NSString *characters;
    unichar c;
    unsigned int characterIndex, characterCount;
    
    // There could be multiple characters in the event.
    characters = [theEvent charactersIgnoringModifiers];
    
    characterCount = [characters length];
    for (characterIndex = 0; characterIndex < characterCount;
         characterIndex++)
    {
        c = [characters characterAtIndex: characterIndex];
        switch(c)
        {
            
            case '\r': //Return
                       //[self sendAction:[self action] to:[self target]];
                [(QSInterfaceController *)[[focus window]windowController] executeCommand:self];
                break;
            case '\t': //Tab
            case 25: //Back Tab
            case 27: //Escape
                [[self window]orderOut:self];
                [focus keyDown:theEvent];
                return;
        }
    }
    
}

- (void)windowDidResize:(NSNotification *)aNotification{
    [[self window] saveFrameUsingName:@"results"];
	//    QSLog(@"win");;
    [[NSUserDefaults standardUserDefaults]synchronize];
    //   visibleRange=[resultTable rowsInRect:[resultTable visibleRect]];
    ///  visibleChildRange=[resultChildTable rowsInRect:[resultChildTable visibleRect]];
    
    if ([self numberOfRowsInTableView:resultTable] && [[NSUserDefaults standardUserDefaults] boolForKey:kShowIcons])
		[[self resultIconLoader]loadIconsInRange:[resultTable rowsInRect:[resultTable visibleRect]]];
    if (!NSEqualRects(NSZeroRect,[resultChildTable visibleRect]) &&[self numberOfRowsInTableView:resultChildTable])
        [[self resultChildIconLoader]loadIconsInRange:[resultChildTable rowsInRect:[resultChildTable visibleRect]]];
	
	[self updateScrollViewTrackingRect];
}



- (IBAction)defineMnemonic:(id)sender{
    //    QSLog(@"%d",[resultTable clickedRow]);
    if (![focus mnemonicDefined])
        [focus defineMnemonic:sender];
    else
        [focus removeMnemonic:sender];
}

- (IBAction)setScore:(id)sender{return;}

- (IBAction)clearMnemonics:(id)sender{
    [focus removeImpliedMnemonic:sender];
}

- (IBAction)omitItem:(id)sender{
	[QSLib setItem:[focus objectValue] isOmitted:YES];
}

- (IBAction)assignAbbreviation:(id)sender{
	[QSLib assignCustomAbbreviationForItem:[focus objectValue]];
}






- (void)viewChanged:(NSNotification*)notif{
    NSRange newRange=[resultTable rowsInRect:[resultTable visibleRect]];
	
	//   QSLog(@"%d-%d are visible %d",visibleRange.location, visibleRange.location+visibleRange.length,[self iconsAreLoading]);
	
	//[self iconsAreLoading];
	//	NSBeep();
	if ([self numberOfRowsInTableView:resultTable] && [[NSUserDefaults standardUserDefaults] boolForKey:kShowIcons])
		[[self resultIconLoader]loadIconsInRange:newRange];
	//	[self threadedIconLoad];
	
	// loadingRange=newRange;
}

- (void)childViewChanged:(NSNotification*)notif{
    //visibleRange=[resultTable rowsInRect:[resultTable visibleRect]];
    //s QSLog(@"%d-%d are visible",visibleRange.location, visibleRange.location+visibleRange.length);/
	//  [self threadedChildIconLoad];
}

- (void)arrayChanged:(NSNotification*)notif{
	[self setResultIconLoader:nil];
    [self setCurrentResults:[focus resultArray]];
	
    [resultTable reloadData];
	
	
    //visibleRange=[resultTable rowsInRect:[resultTable visibleRect]];
	//	QSLog(@"arraychanged %d",[[self currentResults] count]);
    //[self threadedIconLoad];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kShowIcons])
		[[self resultIconLoader]loadIconsInRange:[resultTable rowsInRect:[resultTable visibleRect]]];
}



- (void)updateSelectionInfo{
    selectedResult=[resultTable selectedRow];
    
    if (selectedResult<0 || ![[self currentResults] count]) return;
    QSObject *newSelectedItem=[[self currentResults] objectAtIndex:selectedResult];
    
	
	NSString *status=[NSString stringWithFormat:@"%d of %d",selectedResult+1,[[self currentResults] count]];
	NSString *details=[selectedItem details]?[selectedItem details]:@"";
	
	if ([resultTable rowHeight]<34 && details)
		status=[status stringByAppendingFormat:@" %C %@",0x25B8,details];
	
	[(NSTextField *)selectionView setStringValue:status];

	
    if (selectedItem!=newSelectedItem){
        [self setSelectedItem:newSelectedItem];
        
		
	  
		
		//        [[[resultTable tableColumnWithIdentifier: COLUMNID_NAME]headerCell]setStringValue:];
        
		//      [[resultTable headerView]setNeedsDisplay:YES];
        //   [resultTable _setNeedsDisplayForColumn:1 draggedDelta:0.0];
        
        hideChildren=YES;
        [resultChildTable noteNumberOfRowsChanged];
        
        if ([[NSApp currentEvent]modifierFlags]&NSFunctionKeyMask && [[NSApp currentEvent]isARepeat]){
            if ([childrenLoadTimer isValid]){
                [childrenLoadTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
            }else{ 
				// ***warning   * this should be triggered by the keyUp
                [childrenLoadTimer release];
                childrenLoadTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(loadChildren) userInfo:nil repeats:NO]retain];
            }
        }else{
            [self loadChildren];
        }
        
    }
}

- (QSObject *) selectedItem {
    return [[selectedItem retain] autorelease];
}

- (void)setSelectedItem:(QSObject *)newSelectedItem {
    if (selectedItem != newSelectedItem) {
        [selectedItem release];
        selectedItem = [newSelectedItem retain];
    }
}




/*
 -(void)threadedIconLoad{
	 if (!loadingIcons && [[NSUserDefaults standardUserDefaults] boolForKey:kShowIcons]){
		 loadingIcons=YES;
		 [NSThread detachNewThreadSelector:@selector(loadIconsInTable:) toTarget:self withObject:resultTable];
	 }
	 else iconLoadValid=NO;
 }
 -(void)threadedChildIconLoad{
	 
	 //QSLog(@"load child icons");
	 if (!loadingChildIcons && [[NSUserDefaults standardUserDefaults] boolForKey:kShowIcons]){
		 loadingChildIcons=YES;
		 [NSThread detachNewThreadSelector:@selector(loadIconsInTable:) toTarget:self withObject:resultChildTable];
	 }
	 else childIconLoadValid=NO;
 }
 */

-(void)loadChildren{
    if (NSEqualRects(NSZeroRect,[resultChildTable visibleRect])) return;
    [resultChildTable reloadData];
	// [self threadedChildIconLoad];   
    
}


-(BOOL)iconLoadValidForTable:(NSTableView *)table{
    if (table==resultTable && !iconLoadValid){
        iconLoadValid=YES;
        return NO;
    } else if (table==resultChildTable && !childIconLoadValid){
        childIconLoadValid=YES;
        return NO;
    }
    return YES;
}
/*
 -(void)iconLoader:(QSIconLoader *)loader finishedLoadingArray:sourceArray{
	 if (loader==resultIconLoader)
		 [self setResultIconLoader:nil];
	 else if (loader==resultChildIconLoader)		
		 [self setResultChildIconLoader:nil];
 }
 */
-(void)iconLoader:(QSIconLoader *)loader loadedIndex:(int)m inArray:(NSArray *)array{
	//	QSLog(@"loaded");
	NSTableView *table=nil;
	if (loader==resultIconLoader){
        table=resultTable;
		
		if (m==[resultTable selectedRow])[focus setNeedsDisplay:YES];
    }else if (loader==resultChildIconLoader){
        table=resultChildTable;
	}else{
		//QSLog(@"RogueLoader %d",m);	
	}
	[table performSelectorOnMainThread:@selector(redisplayRows:) withObject:[NSIndexSet indexSetWithIndex:m] waitUntilDone:NO];
}


- (float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)offset{
    //QSLog(@"constrainMax: %f,%d",proposedMax,offset);
    //  return proposedMax-36;
    return proposedMax; // - 165;
}

- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)offset{
    QSLog(@"constrainMin: %f,%d",proposedMin,offset);
    //  if (offset)
    
    return NSWidth([sender frame])/2;
    
    return proposedMin;
}

//- (float)splitView:(NSSplitView *)splitView constrainSplitPosition:(float)proposedPosition ofSubviewAt:(int)offset{
//QSLog(@"constrainSplit: %f,%d",proposedPosition,offset);
//return [splitView frame].size.height-160;
//}

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview{
    //QSLog(@"collapse");
    return subview!=[resultTable enclosingScrollView];
    // if (subview==infoBox) return YES;
    // else return NO;
}

- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize{
    float dividerThickness = [sender dividerThickness];
    id sv1 = [[sender subviews] objectAtIndex:0];
    id sv2 = [[sender subviews] objectAtIndex:1];
    NSRect leftFrame  = [sv1 frame];
    NSRect rightFrame = [sv2 frame];
    NSRect newFrame   = [sender frame];
    
    // if (sender != m_SourceItemSplitView) return;
    
    leftFrame.origin = NSMakePoint(0,0);
    leftFrame.size.height = newFrame.size.height;
    rightFrame.size.height = newFrame.size.height;
    
    rightFrame.size.width=MIN(rightFrame.size.width,newFrame.size.width/2);
    if (rightFrame.size.width<32) rightFrame.size.width=0;
    
    leftFrame.size.width = newFrame.size.width - rightFrame.size.width  - dividerThickness;
    
    rightFrame.origin = NSMakePoint(leftFrame.size.width + dividerThickness,0);
    
    [sv1 setFrame:leftFrame];
    [sv2 setFrame:rightFrame];
    
};

- (void)splitViewDidResizeSubviews:(NSNotification *)notification{
    // if ([[NSApp currentEvent]type]==NSLeftMouseDragged){
    //     QSLog(@"%f",NSWidth([[resultChildTable enclosingScrollView] frame])/NSWidth([splitView frame]));
	//    [[NSUserDefaults standardUserDefaults] setFloat:NSWidth([[resultChildTable enclosingScrollView] frame])/NSWidth([splitView frame])
	//												  forKey:kResultTableSplit];
	//    }
}


- (void) setSplitLocation{
	NSNumber *resultWidth=[[NSUserDefaults standardUserDefaults] objectForKey:kResultTableSplit];
	
	
	if (resultWidth){
		NSView *firstView=[[splitView subviews]objectAtIndex:0];
		NSRect frame=[firstView frame];
		frame.size.width=[resultWidth floatValue]*NSWidth([splitView frame]);
		
		QSLog(@"%f",frame.size.width);
		
		[firstView setFrame:frame];
		
		frame.origin.x+=NSWidth(frame);
		frame.size.width=NSWidth([splitView frame])-NSWidth(frame)-[splitView dividerThickness];
		
		[[[splitView subviews]lastObject] setFrame:frame];
		
		[splitView adjustSubviews];
		[splitView display];
	}
}


- (NSArray *)currentResults { return currentResults; }

- (void)setCurrentResults:(NSArray *)newCurrentResults {
    [currentResults release];
    currentResults = [newCurrentResults retain];
}

- (BOOL)iconsAreLoading{
	return [resultIconLoader isLoading];
}
- (QSIconLoader *)resultIconLoader {
	if (!resultIconLoader){
		[self setResultIconLoader:[QSIconLoader loaderWithArray:[self currentResults]]];
		[resultIconLoader setDelegate:self];
	}
	return [[resultIconLoader retain] autorelease];
}

- (void)setResultIconLoader:(QSIconLoader *)aResultIconLoader {
	//QSLog(@"setloader %@",aResultIconLoader);
    if (resultIconLoader != aResultIconLoader) {
		[resultIconLoader invalidate];
        [resultIconLoader release];
        resultIconLoader = [aResultIconLoader retain];
    }
}


- (QSIconLoader *)resultChildIconLoader { return [[resultChildIconLoader retain] autorelease]; }

- (void)setResultChildIconLoader:(QSIconLoader *)aResultChildIconLoader {
    if (resultChildIconLoader != aResultChildIconLoader) {
        [resultChildIconLoader release];
        resultChildIconLoader = [aResultChildIconLoader retain];
    }
}

@end






@implementation QSResultController (Table)

//Table Methods

- (void)setupResultTable{

    NSTableColumn *tableColumn = nil;
	//   QSImageAndTextCell *imageAndTextCell = nil;
    //NSImageCell *imageCell = nil;
    
    [resultTable setTarget:self];
    
    [resultTable setAction:@selector(tableViewAction:)];
    [resultTable setDoubleAction:@selector(tableViewDoubleAction:)];
    [resultTable setVerticalMotionCanBeginDrag:NO];
    
    //    [resultTable setRowHeight:36];
	//  imageAndTextCell = [[[QSImageAndTextCell alloc] init] autorelease];
	//  [imageAndTextCell setEditable: YES];
	//   [imageAndTextCell setFont:[NSFont systemFontOfSize:11]];
	//   [imageAndTextCell setWraps:NO];
	//[imageAndTextCell setScrollable:YES];
    
    QSObjectCell *objectCell = [[[QSObjectCell alloc] init] autorelease];
    tableColumn= [resultTable tableColumnWithIdentifier: COLUMNID_NAME];
    [tableColumn setDataCell:objectCell];
    
    tableColumn= [resultChildTable tableColumnWithIdentifier: COLUMNID_NAME];
    [tableColumn setDataCell:objectCell];
	
	
    tableColumn= [resultTable tableColumnWithIdentifier: COLUMNID_RANK];
    
	//	[tableColumn setHeaderCell:[[[QSTableHeaderCell alloc] initTextCell:@"Name"]autorelease]];
    
	
    
    NSCell *rankCell = [[[QSRankCell alloc] init] autorelease];
    [tableColumn setDataCell:rankCell];
    
    
    //[searchModePopUp setEnabled:fALPHA];
    
    
    tableColumn= [resultTable tableColumnWithIdentifier: COLUMNID_EQUIV];
    [[tableColumn dataCell] setFont:[NSFont systemFontOfSize:9]];
    [[tableColumn dataCell] setTextColor:[NSColor darkGrayColor]];
    
    if (1 || !fDEV)
        [resultTable removeTableColumn:tableColumn];
    
    //tableColumn= [resultTable tableColumnWithIdentifier: COLUMNID_NAME];
    //[tableColumn setDataCell:[[[NSImageCell alloc]init]autorelease]];
    //Register for table notifications
    // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectionChange:) name:NSTableViewSelectionDidChangeNotification object:nil];
    //  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectionChange:) name:NSTableViewSelectionIsChangingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewChanged:) name:NSViewBoundsDidChangeNotification object:[[resultTable enclosingScrollView] contentView]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(childViewChanged:) name:NSViewBoundsDidChangeNotification object:[[resultChildTable enclosingScrollView] contentView]];
  
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView{
	
	//QSLog(@"rows?");
    if (tableView==resultChildTable){
        //if ([[NSApp currentEvent]isARepeat]) return 0;
        if (hideChildren){
            hideChildren=NO;
            return 0;
        }
        return[[selectedItem children]count];
    }
    else{
        // QSLog(@"%d results",[[self currentResults] count]);
        return [[self currentResults] count];
    }
}

- (BOOL)tableView:(NSTableView *)aTableView rowIsSeparator:(int)rowIndex{
	if (aTableView==resultTable){
		id object=[[self currentResults] objectAtIndex:rowIndex];
		return [object isKindOfClass:[QSSeparatorObject class]];
	}
	return NO;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldDrawRow:(int)rowIndex inClipRect:(NSRect)clipRect{
	clipRect=[aTableView rectOfRow:rowIndex];
	// clipRect.origin.y+=(int)(NSHeight(clipRect)/2);
	// clipRect.size.height=1.0;
    [[NSColor colorWithDeviceWhite:0.95 alpha:1.0]set];
	
    NSRectFill(clipRect);  
	
	id object=[[self currentResults] objectAtIndex:rowIndex];
	[[object name]drawInRect:clipRect withAttributes:nil];
	
	return NO;
}


- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    if (tableView==resultTable && [[self currentResults] count]>row){
        QSObject *thisObject=[[self currentResults] objectAtIndex:row];
    	
        if ([[tableColumn identifier]isEqualToString:COLUMNID_TYPE]){
			NSString *kind=[thisObject kind];
			NSString *desc=[kindDescriptions objectForKey:kind];
			
			return (desc?desc:kind);
		}
        if ([[tableColumn identifier]isEqualToString:COLUMNID_NAME]){
            return nil;//[[thisObject retain]autorelease];
        }
        if ([[tableColumn identifier] isEqualToString: COLUMNID_HASCHILDREN]) {
			
			return([thisObject hasChildren]?[NSImage imageNamed:@"ChildArrow"]:nil);
        } 

		
    }
    return nil;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
	if ([[aTableColumn identifier]isEqualToString:COLUMNID_NAME]){
		NSArray *array=[self currentResults]; 
		if (aTableView==resultChildTable) array=[selectedItem children];
		QSObject *thisObject=[array objectAtIndex:rowIndex];
		
        [aCell setRepresentedObject:thisObject];
        [aCell setState:[focus objectIsInCollection:thisObject]];
    }
	if ([[aTableColumn identifier] isEqualToString: COLUMNID_RANK]) {
		NSArray *array=[self currentResults]; 
		
		QSObject *thisObject=[array objectAtIndex:rowIndex];
		
		[(QSRankCell *)aCell setScore:(float)[thisObject score]]; 
		[(QSRankCell *)aCell setOrder:(int)[thisObject order]]; 
		//int order=[thisObject order];
		// QSLog(@"score %f %@",score,thisObject);
		//return [thisObject retain];//[NSNumber numberWithInt:(score*100)+order?1000:0];
	}
    return;
}
- (NSMenu *)tableView:(NSTableView*)tableView menuForTableColumn:(NSTableColumn *)column row:(int)row{
    [tableView selectRow:row byExtendingSelection:NO];
    
	NSArray *array=[self currentResults]; 
	QSObject *thisObject=[array objectAtIndex:row];
	
    return [thisObject rankMenuWithTarget:focus];
}

- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard{
    [[[self currentResults] objectAtIndex:[[rows objectAtIndex:0]intValue]]putOnPasteboard:pboard includeDataForTypes:nil];
    return YES;
}
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{
    
    if (aNotification && [aNotification object]!=resultTable) return;
    
    if (selectedResult!=-1 && selectedResult!=[resultTable selectedRow]){
        selectedResult=[resultTable selectedRow];
        [focus selectIndex:[resultTable selectedRow]];
        [self updateSelectionInfo];
    } 
}
- (void)tableViewSelectionIsChanging:(NSNotification *)aNotification{
    
    //  QSLog(@"ischanging");
}
/*
 - (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn{
     QSLog(@"clicx %@",tableColumn);
 }
 */
- (IBAction)tableViewAction:(id)sender{
	//QSLog(@"action %@ %d %d",sender,[sender clickedColumn],[sender clickedRow]);
    if ([sender clickedRow]==-1){
		
        
    }else if ([sender clickedColumn]==0){
        NSPoint origin=[sender rectOfRow:[sender clickedRow]].origin;
        origin.y+=[sender rowHeight];
        NSEvent *theEvent=[NSEvent mouseEventWithType:NSRightMouseDown location:[sender convertPoint:origin toView:nil]
                                        modifierFlags:0 timestamp:0 windowNumber:[[sender window]windowNumber] context:nil eventNumber:0 clickCount:1 pressure:0];
        
	//	[tableView selectRow:row byExtendingSelection:NO];
		
		NSArray *array=[self currentResults]; 
		QSObject *thisObject=[array objectAtIndex:[sender clickedRow]];
		

        [NSMenu popUpContextMenu:[thisObject rankMenuWithTarget:focus] withEvent:theEvent forView:sender];
        
    }
}

- (IBAction)sortByName:(id)sender{
	[focus sortByName:sender];
}
- (IBAction)sortByScore:(id)sender{
	[focus sortByScore:sender];
}


- (IBAction)tableViewDoubleAction:(id)sender{
    [(QSInterfaceController *)[[focus window] windowController] executeCommand:self];
}
@end
