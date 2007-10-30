/* =============================================================================
	FILE:		UKDistributedView.h
	PROJECT:	UKDistributedView

	PURPOSE:	An NSTableView-like class that allows arbitrary positioning
				of evenly-sized items. This is intended for things like the
				Finder's "icon view", and even lets you snap items to a grid
				in various ways, reorder them etc.
				
				Your data source must be able to provide a position for its
				list items, which are simply enumerated. An NSCell subclass
				can be used for actually displaying the data, e.g. as an
				NSImage or similar.

	AUTHOR:		M. Uli Kusterer (UK), (c) 2003, all rights reserved.

	REVISIONS:
		2003-06-24	UK	Created.
   ========================================================================== */

/* -----------------------------------------------------------------------------
	Headers:
   -------------------------------------------------------------------------- */

#import "UKDistributedView.h"
#import <limits.h>


/* -----------------------------------------------------------------------------
	Notifications:
   -------------------------------------------------------------------------- */

NSString*		UKDistributedViewSelectionDidChangeNotification = @"UKDistributedViewSelectionDidChange";


/* -----------------------------------------------------------------------------
	UKDistributedView:
   -------------------------------------------------------------------------- */

@implementation UKDistributedView

-(id)	initWithFrame: (NSRect)frame
{
    self = [super initWithFrame:frame];
    if( self )
	{
		lastPos = NSMakePoint(0,0);
		cellSize = NSMakeSize( 100.0,100.0 );
		gridSize.width = cellSize.width /2;
		gridSize.height = cellSize.height /2;
		contentInset = 8.0;
		forceToGrid = snapToGrid = NO;
		prototype = [[NSCell alloc] init];
		mouseItem = -1;
		dragDestItem = -1;
		dragMovesItems = NO;
		delegate = dataSource = nil;
		selectionSet = [[NSMutableSet alloc] init];
		useSelectionRect = allowsMultipleSelection = YES;
		allowsEmptySelection = YES;
		sizeToFit = YES;
		showSnapGuides = YES;
		drawSnappedRects = NO;
		drawsGrid = NO;
		gridColor = [[NSColor gridColor] retain];
		selectionRect = NSZeroRect;
		visibleItemRect = NSZeroRect;
		visibleItems = [[NSMutableArray alloc] init];
	}
    return self;
}

-(id)	init
{
    self = [super init];
    if( self )
	{
		lastPos = NSMakePoint(0,0);
		cellSize = NSMakeSize( 100.0,100.0 );
		gridSize.width = cellSize.width /2;
		gridSize.height = cellSize.height /2;
		contentInset = 8.0;
		forceToGrid = snapToGrid = NO;
		prototype = [[NSCell alloc] init];
		mouseItem = -1;
		dragDestItem = -1;
		dragMovesItems = NO;
		delegate = dataSource = nil;
		selectionSet = [[NSMutableSet alloc] init];
		useSelectionRect = allowsMultipleSelection = YES;
		allowsEmptySelection = YES;
		sizeToFit = YES;
		showSnapGuides = YES;
		drawSnappedRects = NO;
		drawsGrid = NO;
		gridColor = [[NSColor gridColor] retain];
		selectionRect = NSZeroRect;
		visibleItemRect = NSZeroRect;
		visibleItems = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)	dealloc
{
	[visibleItems release];
	[selectionSet release];
	[prototype release];
}


-(int)	selectedItem
{
	NSEnumerator*	enny = [selectionSet objectEnumerator];
	int				i = -1;
	NSNumber*		num;
	
	if( num = [enny nextObject] )
		i = [num intValue];
	
	return i;
}


-(NSEnumerator*)	selectedItemEnumerator
{
	return [selectionSet objectEnumerator];
}


-(int)				selectedItemCount
{
	return [selectionSet count];
}


-(void)	selectItem: (int)index byExtendingSelection: (BOOL)ext
{
	if( !ext )
		[selectionSet removeAllObjects];

	if( index != -1 && ![selectionSet containsObject:[NSNumber numberWithInt: index]] )
		[selectionSet addObject:[NSNumber numberWithInt: index]];
	
	[self itemNeedsDisplay: index];
}


-(void)	selectItemsInRect: (NSRect)aBox byExtendingSelection: (BOOL)ext
{
	int		x, count = [dataSource numberOfItemsInDistributedView:self];
	
	if( !ext )
	{
		[self selectionSetNeedsDisplay];	// Make sure items are redrawn unselected.
		[selectionSet removeAllObjects];
	}
	
	aBox = [self flipRectsYAxis: aBox];

	for( x = 0; x < count; x++ )
	{
		NSRect		box = [self rectForItemAtIndex:x];
		box = [self snapRectToGrid: box];

		if( NSIntersectsRect( aBox, box ) )
		{
			if( ![selectionSet containsObject:[NSNumber numberWithInt: x]] )
				[selectionSet addObject:[NSNumber numberWithInt: x]];
			[delegate distributedView:self didSelectItemIndex: x];
		}
	}
	
	[self selectionSetNeedsDisplay];	// Make sure newly selected items are drawn that way.
	
	[[NSNotificationCenter defaultCenter] postNotificationName: UKDistributedViewSelectionDidChangeNotification
											object: self];
}


-(IBAction)			selectAll: (id)sender
{
	int		count = [dataSource numberOfItemsInDistributedView:self];
	
	[selectionSet removeAllObjects];
	
	while( --count >= 0 )
	{
		[delegate distributedView:self didSelectItemIndex: count];
		[selectionSet addObject:[NSNumber numberWithInt: count]];
	}
	
	[self setNeedsDisplay:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName: UKDistributedViewSelectionDidChangeNotification
											object: self];
}


-(IBAction)			deselectAll: (id)sender
{
	if( allowsEmptySelection )
	{
		[selectionSet removeAllObjects];
		[self setNeedsDisplay:YES];
	
		[[NSNotificationCenter defaultCenter] postNotificationName: UKDistributedViewSelectionDidChangeNotification
												object: self];
	}
}


-(IBAction)			toggleDrawsGrid: (id)sender
{
	[self setDrawsGrid: !drawsGrid];
}


-(IBAction)			toggleSnapToGrid: (id)sender
{
	[self setSnapToGrid: !snapToGrid];
}


-(void)				setAllowsMultipleSelection: (BOOL)state
{
	allowsMultipleSelection = state;
	
	if( !state && [selectionSet count] > 1 )
	{
		[selectionSet autorelease];
		selectionSet = [NSMutableSet setWithObject: [selectionSet anyObject]];
	}
}


-(BOOL)				allowsMultipleSelection
{
	return allowsMultipleSelection;
}



-(void)				setAllowsEmptySelection: (BOOL)state
{
	allowsEmptySelection = state;
	
	if( !state && [selectionSet count] == 0 )
		[selectionSet addObject:[NSNumber numberWithInt: 0]];
}


-(BOOL)				allowsEmptySelection
{
	return allowsEmptySelection;
}


-(void)				setUseSelectionRect: (BOOL)state
{
	useSelectionRect = state;
	
	// Selection rect implicitly turns on allowsMultipleSelection:
	if( !allowsMultipleSelection )
		[self setAllowsMultipleSelection:YES];
}


-(BOOL)				useSelectionRect
{
	return useSelectionRect;
}


-(void)		setGridColor: (NSColor*)c
{
	[c retain];
	[gridColor release];
	gridColor = c;
}


-(NSColor*)	gridColor
{
	return gridColor;
}


/* The prototype is the "data cell" used for displaying items:
	Use this to change the cell type used for display. */
-(void)	setPrototype: (NSCell*)aCell
{
	[aCell retain];
	[prototype release];
	prototype = aCell;
	
	[prototype setTarget: self];
	[prototype setAction:@selector(cellClicked:)];
}


-(id)	prototype
{
	return prototype;
}


/* All items's positions will be nudged to lie on a grid coordinate:
	This will only modify the coordinates during display. This will
	*not* change any actual item positions, and this doesn't make sure
	that no items overlap. */
-(void)	setForceToGrid: (BOOL)state
{
	forceToGrid = state;
	[self setNeedsDisplay: YES];
}


-(BOOL) forceToGrid
{
	return forceToGrid;
}





-(void)	setDragMovesItems: (BOOL)state
{
	dragMovesItems = state;
}


/* Whenever an object moves, make this view resize to fit. */ 
-(void)	setSizeToFit: (BOOL)state
{
	sizeToFit = state;
}


-(BOOL) sizeToFit
{
	return sizeToFit;
}


/* If you need to positionItem: a number of items in a row,
	call this around these calls. That way, the view will keep track of the
	previous item's position and start looking for a position for the next
	one after that, instead of starting at the top again. */ 
-(void)	setMultiPositioningMode: (BOOL)state
{
	if( state )
		lastSuggestedItemPos = NSMakePoint(0,0);
	multiPositioningMode = state;
}


-(BOOL) multiPositioningMode
{
	return sizeToFit;
}


/* Always force newly positioned and moved items to lie on the grid. */ 
-(void)	setSnapToGrid: (BOOL)state
{
	snapToGrid = state;
}


-(BOOL) snapToGrid
{
	return snapToGrid;
}


-(BOOL) dragMovesItems
{
	return dragMovesItems;
}


-(void)		setShowSnapGuides: (BOOL)state
{
	showSnapGuides = state;
}


-(BOOL)		showSnapGuides
{
	return showSnapGuides;
}


-(void)		setDrawsGrid: (BOOL)state
{
	drawsGrid = state;
	[self setNeedsDisplay: YES];
}


-(BOOL)		drawsGrid
{
	return drawsGrid;
}


// The number of pixels of border to keep around the items:
-(void)	setContentInset: (float)inset
{
	contentInset = inset;
	if( forceToGrid )
		[self setNeedsDisplay: YES];
}


-(float) contentInset
{
	return contentInset;
}


// The cell size to use for our items:
-(void)	setCellSize: (NSSize)size
{
	cellSize = size;
	gridSize.width = cellSize.width /2;
	gridSize.height = cellSize.height /2;
	if( forceToGrid )
		[self setNeedsDisplay: YES];
}


-(NSSize) cellSize
{
	return cellSize;
}


// The size to use for our positioning grid:
-(void)	setGridSize: (NSSize)size
{
	gridSize = size;
	if( forceToGrid )
		[self setNeedsDisplay: YES];
}


-(NSSize) gridSize
{
	return gridSize;
}


-(id)	dataSource
{
	return dataSource;
}


-(void)	setDataSource: (id)d
{
	dataSource = d;
}


-(id)	delegate
{
	return delegate;
}


-(void)	setDelegate: (id)d
{
	delegate = d;
}


-(IBAction)	cellClicked: (id)sender
{
	[delegate distributedView:self cellClickedAtItemIndex: mouseItem];
}


/* Position all items in order on the grid:
	This changes all items' positions *permanently*. Note that this simply tries to
	fit the items as orderly rows in the given rect, wrapping at the right edge. */
-(IBAction)	positionAllItems: (id)sender
{
	NSRect			myFrame = [self frame];
	int				numCols,
					x,
					col = 0,
					row = 0,
					count = [dataSource numberOfItemsInDistributedView:self];
	
	// Calculate display rect:
	myFrame.origin.x += contentInset;
	myFrame.origin.y += contentInset;
	myFrame.size.width -= contentInset *2;
	myFrame.size.height -= contentInset *2;
	
	// Calculate # of items that fit in display area in an orderly fashion:
	numCols = truncf(myFrame.size.width / cellSize.width);
	
	// Now loop over all slots in the window where we would put something:
	for( x = 0; x < count; x++ )
	{
		if( col >= numCols )
		{
			col = 0;
			row++;
		}
		
		NSRect		testBox = NSMakeRect( (col * cellSize.width) +contentInset,
											(row * cellSize.height) +contentInset,
											cellSize.width, cellSize.height );
		
		[dataSource distributedView:self setPosition:testBox.origin forItemIndex:x];
		col++;
	}
	
	[self contentSizeChanged];
	[self setNeedsDisplay:YES];
}


/* Position all items on the closest grid location to their current location:
	This changes all items' positions *permanently*. */
-(IBAction)	snapAllItemsToGrid: (id)sender
{
	int				x,
					count = [dataSource numberOfItemsInDistributedView:self];
	
	// Now loop over all slots in the window where we would put something:
	for( x = 0; x < count; x++ )
	{
		NSRect		testBox = [self rectForItemAtIndex:x];
		testBox = [self forceRectToGrid:testBox];
		[dataSource distributedView:self setPosition:testBox.origin forItemIndex:x];
	}
	
	[self contentSizeChanged];
	[self setNeedsDisplay:YES];
}


/* Reposition the item at the specified index:
	Note that this will *always* move the current item. */
-(void)	positionItem: (int)itemIndex
{
	NSRect			myFrame = [self frame];
	int				numCols, numRows,
					col, row;
	
	// Calculate display rect:
	myFrame.origin.x += contentInset;
	myFrame.origin.y += contentInset;
	myFrame.size.width -= contentInset *2;
	myFrame.size.height -= contentInset *2;
	
	// Calculate # of grid locations where we can put items:
	numCols = myFrame.size.width / gridSize.width;
	//numRows = myFrame.size.height / gridSize.height;
	numRows = INT_MAX;
	int		startRow = 0, startCol = 0;
	
	if( multiPositioningMode )
		startRow = lastSuggestedItemPos.y;
	
	if( multiPositioningMode )
		startCol = lastSuggestedItemPos.x;
	
	// Now loop over all slots in the window where we would put something:
	for( row = startRow; row < numRows; row++ )
	{
		for( col = startCol; col < numCols; col++ )
		{
			NSRect		testBox = NSMakeRect( (col * gridSize.width) +contentInset,
												(row * cellSize.height) +contentInset,
												cellSize.width, cellSize.height );
			
			int foundIndex = [self getUncachedItemIndexInRect:testBox];
			if( foundIndex == -1 )	// No item in this rect?
			{
				[dataSource distributedView:self setPosition:testBox.origin forItemIndex:itemIndex];
				lastSuggestedItemPos.x = col;
				lastSuggestedItemPos.y = row;
				return;
			}
		}
		startCol = 0;   // Only first time round do we want to start in that row.
	}
}


/* Returns a position that is suggested for a new item: */
-(NSPoint)	suggestedPosition
{
	NSRect			myFrame = [self frame];
	int				numCols, numRows,
					col, row;
	
	// Calculate display rect:
	myFrame.origin.x += contentInset;
	myFrame.origin.y += contentInset;
	myFrame.size.width -= contentInset *2;
	myFrame.size.height -= contentInset *2;
	
	// Calculate # of grid slots where we could put this item:
	numCols = myFrame.size.width / gridSize.width;
	numRows = myFrame.size.height / gridSize.height;
	
	// Now loop over all slots in the window where we would put something:
	for( row = 0; row < (numRows *10); row++ )	// * 10 so we don't try infinitely.
	{
		for( col = 0; col < numCols; col++ )
		{
			NSRect		testBox = NSMakeRect( (col * gridSize.width) +contentInset,
												(row * gridSize.height) +contentInset,
												cellSize.width, cellSize.height );
			
			if( [self getItemIndexInRect:testBox] == -1 )	// No item in this rect?
				return testBox.origin;
		}
	}
	
	return NSMakePoint(contentInset,contentInset);
}


-(void)	drawGridForDrawRect: (NSRect)rect
{
	if( !drawsGrid )
		return;

	NSRect		box = [self frame];
	int			cols, rows, x, y;
	
	// Draw outline around margin:
	box.origin.x += contentInset +0.5;		// 0.5 so it draws on a full pixel
	box.origin.y += contentInset -0.5;		// 0.5 so it draws on a full pixel, - because it has to match the Y-flipped rects below
	box.size.width -= contentInset *2;
	box.size.height -= contentInset *2;
	[[self gridColor] set];
	[NSBezierPath setDefaultLineWidth: 1.0];
	[NSBezierPath strokeRect:box];
	
	NSRectClip(box);	// TODO Do we want this to clip drawing of cells? Or should we restore graf state?
	
	// Now draw grid itself:
	cols = (box.size.width / gridSize.width) +1;
	rows = (box.size.height / gridSize.height) +1;
	
	for( x = 0; x < cols; x++ )
	{
		for( y = 0; y < rows; y++ )
		{
			NSRect		gridBox = NSMakeRect( (x * gridSize.width) +0.5 +contentInset, (y * gridSize.height) +0.5 +contentInset,
												gridSize.width, gridSize.height );
			gridBox = [self flipRectsYAxis:gridBox];
			[NSBezierPath strokeRect:gridBox];
		}
	}
}


-(void)	drawCellsForDrawRect: (NSRect)rect
{
	/* This rect isn't in our cache?
		Redo the cache, including 5 item heights above/below and 5 item widths
		left/right beyond what is currently visible: */
	if( !NSContainsRect( visibleItemRect, [self flipRectsYAxis: rect] ) )
	{
		NSRect		cacheRect = NSInsetRect( [self visibleRect], cellSize.width *-(UKDISTVIEW_INVIS_ITEMS_CACHE_COUNT *2), cellSize.height *-(UKDISTVIEW_INVIS_ITEMS_CACHE_COUNT *2) );
		NSLog(@"Rebuilding cache");
		[self cacheVisibleItemIndexesInRect: [self flipRectsYAxis: cacheRect]];
	}
	
	// Now use the cache to draw all visible items:
	NSEnumerator*   indexEnny = [visibleItems objectEnumerator];
	NSNumber*		currIndex = nil;
	int				icount = [dataSource numberOfItemsInDistributedView: self];
	while( currIndex = [indexEnny nextObject] )
	{
		NSRect		box = NSMakeRect( 0,0, cellSize.width,cellSize.height );
		int			x = [currIndex intValue];
		
		if( x > icount )
			continue;
		#if UKDISTVIEW_BACKWARDS_COMPATIBLE
		box.origin = [dataSource distributedView: self positionForCell:prototype atItemIndex: x];
		#else
		box.origin = [dataSource distributedView: self positionForItemIndex: x];
		#endif
		box = [self snapRectToGrid: box];	// Does nothing if "force to grid" is off.
		
		BOOL		isSelected = [selectionSet containsObject:[NSNumber numberWithInt: x]];
		
		isSelected |= (dragDestItem == x);
		
		if( drawSnappedRects && isSelected )
		{
			NSRect		indicatorBox = box;
			indicatorBox = [self forceRectToGrid: box];
			indicatorBox = [self flipRectsYAxis: indicatorBox];
			
			if( NSIntersectsRect( indicatorBox, rect ) )
				[self drawSnapGuideInRect: indicatorBox];
		}
		box = [self flipRectsYAxis: box];
		
		if( NSIntersectsRect( box, rect ) )
		{
			#if !UKDISTVIEW_BACKWARDS_COMPATIBLE
			[dataSource distributedView: self setupCell: prototype forItemIndex: x];
			#endif
			[prototype setHighlighted: isSelected];
			[prototype drawWithFrame:box inView:self];
		}
	}

	/*// Loop over the whole view and draw it:
	{
		int		x, count = [dataSource numberOfItemsInDistributedView:self];
		rect = [self flipRectsYAxis: rect];
		
		for( x = 0; x < count; x++ )
		{
			NSRect		box = NSMakeRect( 0,0, cellSize.width,cellSize.height );
			#if UKDISTVIEW_BACKWARDS_COMPATIBLE
			box.origin = [dataSource distributedView: self positionForCell:prototype atItemIndex: x];
			#else
			box.origin = [dataSource distributedView: self positionForItemIndex: x];
			#endif
			box = [self snapRectToGrid: box];	// Does nothing if "force to grid" is off.
			
			if( NSIntersectsRect( rect, box ) )
			{
				BOOL		isSelected = [selectionSet containsObject:[NSNumber numberWithInt: x]];
				
				if( drawSnappedRects && isSelected )
				{
					NSRect		indicatorBox = box;
					indicatorBox = [self forceRectToGrid: box];
					indicatorBox = [self flipRectsYAxis: indicatorBox];
					
					[self drawSnapGuideInRect: indicatorBox];
				}
				box = [self flipRectsYAxis: box];
				
				#if !UKDISTVIEW_BACKWARDS_COMPATIBLE
				[dataSource distributedView: self setupCell: prototype forItemIndex: x];
				#endif
				[prototype setHighlighted:isSelected];
				[prototype drawWithFrame:box inView:self];
			}
		}
	}*/
}


/* A simple blue frame with slight white fill. You can also get a transparent
	version of the cell instead, if that's what you like. */

-(void)	drawSnapGuideInRect: (NSRect)box
{
  #if UKDISTVIEW_DRAW_FANCY_SNAP_GUIDES
	NSRect		drawBox = box;
	drawBox.origin.x = drawBox.origin.y = 0;
	NSImage*	snapGuideImg = [[[NSImage alloc] initWithSize: drawBox.size] autorelease];
	[snapGuideImg lockFocus];
		[prototype drawWithFrame: drawBox inView: self];
	[snapGuideImg unlockFocus];
	[snapGuideImg dissolveToPoint: box.origin fraction: 0.2];
  #else
	box = NSInsetRect( box, 2, 2 );
	box.origin.x += 0.5; box.origin.y += 0.5;	// Move them onto full pixels.
	[[[NSColor whiteColor] colorWithAlphaComponent:0.5] set];
	[NSBezierPath setDefaultLineWidth: 2.0];
	[NSBezierPath fillRect:box];
	[[[NSColor knobColor] colorWithAlphaComponent: 1.0] set];
	[NSBezierPath strokeRect:box];
  #endif
}


-(void)	drawSelectionRectForDrawRect: (NSRect)rect
{
	if( selectionRect.size.width > 0 && selectionRect.size.height > 0 )
	{
		NSRect		drawRect = selectionRect;
		drawRect.origin.x += 0.5; drawRect.origin.y += 0.5;		// Move them onto full pixels
	
		[[NSColor colorWithCalibratedWhite:0.5 alpha:0.3] set];
		[NSBezierPath fillRect:drawRect];
		[NSBezierPath setDefaultLineWidth: 1.0];
		[[NSColor colorWithCalibratedWhite:1.0 alpha:1.0] set];
		[NSBezierPath strokeRect:drawRect];
	}
}


// Draw this view's contents:
-(void)	drawRect: (NSRect)rect
{
	[self drawGridForDrawRect:rect];
	[self drawCellsForDrawRect:rect];
	[self drawSelectionRectForDrawRect:rect];
}


-(void) itemNeedsDisplay: (int)itemNb
{
	NSRect  ibox = [self rectForItemAtIndex: itemNb];
	NSRect  box = [self flipRectsYAxis: ibox];
	
	[self setNeedsDisplayInRect: box];
	
	if( drawSnappedRects )
	{
		NSRect		indicatorBox = [self forceRectToGrid: ibox];
		indicatorBox = [self flipRectsYAxis: indicatorBox];
		[self setNeedsDisplayInRect: indicatorBox];
	}
}


-(void) selectionSetNeedsDisplay
{
	NSEnumerator*   enny = [selectionSet objectEnumerator];
	NSNumber*		currIndex = nil;
	
	while( currIndex = [enny nextObject] )
		[self itemNeedsDisplay: [currIndex intValue]];
}


/* -----------------------------------------------------------------------------
	initiateMove:
		There has been a mouse down, and now we want the mouseItem/selection
		set to be moved on subsequent mouseDragged events. This is old-style
		"live" dragging, not inter-application drag and drop.
	
	REVISIONS:
		2003-12-20	UK	Extracted from mouseDown so initiateDrag can call it.
   -------------------------------------------------------------------------- */

-(void) initiateMove
{
	[[self window] setAcceptsMouseMovedEvents:YES];
}


/* -----------------------------------------------------------------------------
	initiateDrag:
		There has been a mouse down, and now we want the mouseItem/selection
		set to be dragged using the Drag & drop protocol. Takes care of setting
		up the drag image etc. by querying the data source.
		
		If the drag fails due to unsupported data source calls or similar, this
		will cause a local old-style "live" move using initiateMove.
	
	REVISIONS:
		2003-12-20	UK	Created.
   -------------------------------------------------------------------------- */

-(void) initiateDrag: (NSEvent*)event
{
	NSArray*		itemsArr = [selectionSet allObjects];
	NSPasteboard*   pb = [NSPasteboard pasteboardWithName: NSDragPboard];
	NSImage*		theDragImg = [self dragImageForItems: itemsArr
											event: event
											dragImageOffset: &dragStartImagePos];
	
	if( !theDragImg
		|| ![dataSource distributedView:self writeItems:itemsArr toPasteboard: pb] )
	{
		[self initiateMove];
		return;
	}
	
	[self addPositionsOfItems: itemsArr toPasteboard: pb];
	
	// Actually commence the drag:
	[self dragImage:theDragImg at:dragStartImagePos offset:NSMakeSize(0,0)
				event:event pasteboard:pb source:self slideBack:YES];
}


-(void) addPositionsOfItems: (NSArray*)indexes toPasteboard: (NSPasteboard*)pboard
{
	
	NSEnumerator*   enny = [indexes objectEnumerator];
	NSNumber*		currIndex = nil;
	NSMutableArray* files = [NSMutableArray arrayWithCapacity: [indexes count]];
	
	// Build an array of our icon positions:
	while( currIndex = [enny nextObject] )
	{
		int						x = [currIndex intValue];
		NSRect					box;
		
		box.size = cellSize;
		
		#if UKDISTVIEW_BACKWARDS_COMPATIBLE
		box.origin = [dataSource distributedView: self positionForCell: nil
										atItemIndex: x];
		#else
		box.origin = [dataSource distributedView:self positionForItemIndex: x];
		#endif
		
		box = [self flipRectsYAxis: box];
		
		// Make position relative to drag image's loc:
		box.origin.x -= dragStartImagePos.x;
		box.origin.y -= dragStartImagePos.y;
		
		[files addObject: NSStringFromPoint(box.origin)];
	}
	
	// Put it on the drag pasteboard:
	[pboard addTypes: [NSArray arrayWithObject: UKDistributedViewPositionsPboardType] owner: self];
	[pboard setPropertyList: files forType: UKDistributedViewPositionsPboardType];
}


/* -----------------------------------------------------------------------------
	dragImageForItems:event:dragImageOffset:
		Paint a nice drag image of all our items being dragged.
	
	REVISIONS:
		2003-12-20	UK	Created.
   -------------------------------------------------------------------------- */

-(NSImage*) dragImageForItems:(NSArray*)dragIndexes event:(NSEvent*)dragEvent
				dragImageOffset:(NSPointPointer)dragImageOffset
{
	NSRect			extents = [self rectAroundItems: dragIndexes];
	NSEnumerator*   enny = [dragIndexes objectEnumerator];
	NSNumber*		currIndex = nil;
	NSImage*		img = [[[NSImage alloc] initWithSize: extents.size] autorelease];
	
	[img lockFocus];
	
	// Draw each one: 
	while( currIndex = [enny nextObject] )
	{
		NSRect		currBox;
		int			x = [currIndex intValue];
		
		currBox.size = cellSize;
		#if UKDISTVIEW_BACKWARDS_COMPATIBLE
		currBox.origin = [dataSource distributedView: self positionForCell:prototype
										atItemIndex: x];
		#else
		currBox.origin = [dataSource distributedView:self positionForItemIndex: x];
		#endif
		currBox = [self flipRectsYAxis: currBox];
		currBox.origin.x -= extents.origin.x;
		currBox.origin.y -= extents.origin.y;
		
		#if !UKDISTVIEW_BACKWARDS_COMPATIBLE
		[dataSource distributedView: self setupCell: prototype forItemIndex: x];
		#endif
		[prototype setHighlighted: YES];
		[prototype drawWithFrame:currBox inView:self];
	}
	
	[img unlockFocus];
	
	*dragImageOffset = extents.origin;
	
	return img;
}


/* -----------------------------------------------------------------------------
	rectAroundItems:
		Return a rectangle enclosing all the items whose indexes are specified
		in the NSNumbers in the array dragIndexes.
	
	REVISIONS:
		2003-12-20	UK	Created.
   -------------------------------------------------------------------------- */

-(NSRect)   rectAroundItems: (NSArray*)dragIndexes
{
	NSRect			extents;
	NSEnumerator*   enny = [dragIndexes objectEnumerator];
	NSNumber*		currIndex = nil;
	float			l = INT_MAX, t = INT_MIN,
					r = INT_MIN, b = INT_MAX;
	
	// Find the lowest/highest X and Y coordinates and stuff them in l, t, r, and b:
	while( currIndex = [enny nextObject] )
	{
		NSRect		currBox = [self rectForItemAtIndex: [currIndex intValue]];
		
		currBox = [self flipRectsYAxis: currBox];
		
		if( NSMinX(currBox) < l )
			l = NSMinX(currBox);
		if( NSMinY(currBox) < b )
			b = NSMinY(currBox);
		if( NSMaxX(currBox) > r )
			r = NSMaxX(currBox);
		if( NSMaxY(currBox) > t )
			t = NSMaxY(currBox);
	}
	
	// Return the whole shebang as a rect:
	extents.origin.x = l;
	extents.origin.y = b;
	extents.size.width = r - l;
	extents.size.height = t - b;
	
	return extents;
}


/* -----------------------------------------------------------------------------
	draggingEntered:
		Someone moved a dragged item over our view, and it's of a flavor
		we've been declared to understand. Return what operation we want to
		do.
	
	REVISIONS:
		2003-12-21	UK	Created.
   -------------------------------------------------------------------------- */

-(NSDragOperation)  draggingEntered:(id <NSDraggingInfo>)sender
{
	NSDragOperation		retVal;
	
	if( dragDestItem != -1 )
		[self itemNeedsDisplay: dragDestItem];
	dragDestItem = [self getItemIndexAtPoint: [sender draggingLocation]];
	
	retVal = [dataSource distributedView:self validateDrop:sender
						proposedItem: &dragDestItem];
	if( dragDestItem != -1 )
		[self itemNeedsDisplay: dragDestItem];
	
	return retVal;
}


/* -----------------------------------------------------------------------------
	draggingUpdated:
		Someone moved a dragged item over our view, and it's of a flavor
		we've been declared to understand. Return what operation we want to
		do.
	
	REVISIONS:
		2003-12-21	UK	Created.
   -------------------------------------------------------------------------- */

-(NSDragOperation)  draggingUpdated:(id <NSDraggingInfo>)sender
{
	NSDragOperation		retVal;
	
	if( dragDestItem != -1 )
		[self itemNeedsDisplay: dragDestItem];
	dragDestItem = [self getItemIndexAtPoint: [sender draggingLocation]];
	
	retVal = [dataSource distributedView:self validateDrop:sender
						proposedItem: &dragDestItem];
	if( dragDestItem != -1 )
		[self itemNeedsDisplay: dragDestItem];
	
	return retVal;
}


/* -----------------------------------------------------------------------------
	draggingExited:
		Someone moved a dragged item over our view, and it's of a flavor
		we've been declared to understand. Return what operation we want to
		do.
	
	REVISIONS:
		2003-12-21	UK	Created.
   -------------------------------------------------------------------------- */

-(void)  draggingExited:(id <NSDraggingInfo>)sender
{
	if( dragDestItem != -1 )
		[self itemNeedsDisplay: dragDestItem];
	dragDestItem = -1;
	mouseItem = -1;
}


/* -----------------------------------------------------------------------------
	performDragOperation:
		Someone moved a dragged item over our view, and it's of a flavor
		we've been declared to understand. Return what operation we want to
		do.
	
	REVISIONS:
		2003-12-21	UK	Created.
   -------------------------------------------------------------------------- */

-(BOOL) performDragOperation:(id <NSDraggingInfo>)sender
{
	if( dragDestItem != -1 )
		[self itemNeedsDisplay: dragDestItem];
	
	BOOL retVal = [dataSource distributedView:self acceptDrop:sender
							onItem:dragDestItem];
							
	dragDestItem = -1;
	mouseItem = -1;
	
	return retVal;
}


-(void)	mouseDown: (NSEvent*)event
{
	lastPos = [event locationInWindow];
	lastPos = [self convertPoint:lastPos fromView:nil];
    mouseItem = [self getItemIndexAtPoint: lastPos];
	
	if( mouseItem == -1 )	// No item hit? Remove selection and start mouse tracking for selection rect.
	{
		if( !allowsEmptySelection )	// Empty selection not allowed? Can't unselect, and since rubber band needs to reset the selection, can't do selection rect either.
			return;
		[self selectionSetNeedsDisplay];
		[selectionSet removeAllObjects];
		[[NSNotificationCenter defaultCenter] postNotificationName: UKDistributedViewSelectionDidChangeNotification
												object: self];
	}
	else
	{
		if( [event clickCount] % 2 == 0 )
		{
			[delegate distributedView:self cellDoubleClickedAtItemIndex:mouseItem];
			return;
		}
		
		if( ([event modifierFlags] & NSShiftKeyMask) == NSShiftKeyMask )
		{
			// If shift key is down, toggle this item's selection status
			if( [selectionSet containsObject:[NSNumber numberWithInt: mouseItem]] )
			{
				[selectionSet removeObject:[NSNumber numberWithInt: mouseItem]];
				[[NSNotificationCenter defaultCenter] postNotificationName: UKDistributedViewSelectionDidChangeNotification
														object: self];
				[self itemNeedsDisplay: mouseItem];
				return;	// Don't drag unselected item.
			}
			else
			{
				if( [delegate distributedView:self shouldSelectItemIndex: mouseItem] )
				{
					[selectionSet addObject:[NSNumber numberWithInt: mouseItem]];
					[delegate distributedView:self didSelectItemIndex: mouseItem];
					[self itemNeedsDisplay: mouseItem];
					[[NSNotificationCenter defaultCenter] postNotificationName: UKDistributedViewSelectionDidChangeNotification
							object: self];
				}
				else
					return;
			}
		}
		else	// If shift isn't down, make sure we're selected and drag:
		{
			if( [delegate distributedView:self shouldSelectItemIndex: mouseItem] )
			{
				if( ![selectionSet containsObject:[NSNumber numberWithInt: mouseItem]] )
				{	
					[self selectionSetNeedsDisplay];
					[selectionSet removeAllObjects];
					[selectionSet addObject:[NSNumber numberWithInt: mouseItem]];
					[delegate distributedView:self didSelectItemIndex: mouseItem];
					[[NSNotificationCenter defaultCenter] postNotificationName: UKDistributedViewSelectionDidChangeNotification
							object: self];
					[self itemNeedsDisplay: mouseItem];
				}
			}
			else
				return;
		}
	}
	
	if( useSelectionRect || mouseItem != -1 )	// Don't start tracking if we're dealing with a selection rect and we're not allowed to do a selection rect.
		[self initiateMove];
}


/* -----------------------------------------------------------------------------
	mouseDragged:
		This is where we handle "live" old-style "moves" as well as the
		selection rectangles.
	
	REVISIONS:
		2003-12-20	UK	Documented.
   -------------------------------------------------------------------------- */

-(void)	mouseDragged:(NSEvent *)event
{
	NSPoint				eventLocation = [event locationInWindow];
	eventLocation = [self convertPoint:eventLocation fromView:nil];
	
	if( mouseItem == -1 )	// No item hit? Selection rect!
	{
		[self setNeedsDisplayInRect: NSInsetRect(selectionRect, -1, -1)];	// Invalidate old position.
		
		// Build rect:
		selectionRect.origin.x = lastPos.x;
		selectionRect.origin.y = lastPos.y;
		selectionRect.size.width = eventLocation.x -selectionRect.origin.x;
		selectionRect.size.height = eventLocation.y -selectionRect.origin.y;
		
		// Flip it if we have negative width or height:
		if( selectionRect.size.width < 0 )
		{
			selectionRect.size.width *= -1;
			selectionRect.origin.x -= selectionRect.size.width;
		}
		if( selectionRect.size.height < 0 )
		{
			selectionRect.size.height *= -1;
			selectionRect.origin.y -= selectionRect.size.height;
		}
		
		[self setNeedsDisplayInRect: NSInsetRect(selectionRect,-1,-1)];	// Invalidate new position.

		// Select items in the rect:
		[self selectItemsInRect:selectionRect byExtendingSelection:NO];
	}
	else if( dragMovesItems )	// Item hit? Drag the item, if we're set up that way:
	{
		// If mouse is inside our rect, drag locally:
		if( NSPointInRect( eventLocation, [self visibleRect] ) )
		{
			NSEnumerator*		enummy = [selectionSet objectEnumerator];
			NSNumber*			currentItemNum;
		
			if( ((([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask && !snapToGrid)		// snapToGrid is toggled using command key.
					|| (([event modifierFlags] & NSCommandKeyMask) != NSCommandKeyMask && snapToGrid))
					&& !forceToGrid
					&& showSnapGuides )
				drawSnappedRects = YES;
			
			while( currentItemNum = [enummy nextObject] )
			{
				NSPoint		pos;
				int			x = [currentItemNum intValue];
				
				#if UKDISTVIEW_BACKWARDS_COMPATIBLE
				pos = [dataSource distributedView:self positionForCell:nil atItemIndex: x];
				#else
				pos = [dataSource distributedView:self positionForItemIndex: x];
				#endif
				pos.x += [event deltaX];
				pos.y += [event deltaY];
							
				[self itemNeedsDisplay: x]; // Invalidate old position.
				[dataSource distributedView:self setPosition:pos forItemIndex: x];
				[self itemNeedsDisplay: x]; // Invalidate new position.
			}
			
		}
		else if( [dataSource respondsToSelector: @selector(distributedView:writeItems:toPasteboard:)] )	// Left our rect? Use system drag & drop service instead:
			[self initiateDrag: event];
	}
}

-(void)	mouseUp: (NSEvent*)event
{
	[[self window] setAcceptsMouseMovedEvents:NO];
	
	if( mouseItem == -1 )	// No item hit? Must be selection rect. Reset that.
	{
		[self setNeedsDisplayInRect: NSInsetRect(selectionRect,-1,-1)];	// Make sure old selection rect is removed.
		selectionRect.size.width = selectionRect.size.height = 0;
	}
	else	// An item hit? Must be end of drag or so:
	{
		NSPoint		eventLocation = [event locationInWindow];
		NSRect		box = [self rectForItemAtIndex:mouseItem];
		eventLocation = [self convertPoint:eventLocation fromView:nil];
		box = [self snapRectToGrid: box];
		box = [self flipRectsYAxis: box];
	
		if( NSPointInRect(eventLocation,box) && (((lastPos.x == eventLocation.x) && (lastPos.y == eventLocation.y)) || !dragMovesItems) )	// Wasn't a drag.
		{
			[self cellClicked:self];
		}
		lastPos = eventLocation;
		mouseItem = -1;
		
		if( dragMovesItems )	// Item hit? Drag the item, if we're set up that way:
		{
			NSEnumerator*		enummy = [selectionSet objectEnumerator];
			NSNumber*			currentItemNum;
		
			drawSnappedRects = NO;
			
			while( currentItemNum = [enummy nextObject] )
			{
				NSRect		ibox;
				
				#if UKDISTVIEW_BACKWARDS_COMPATIBLE
				ibox.origin = [dataSource distributedView:self positionForCell:nil atItemIndex: [currentItemNum intValue]];
				#else
				ibox.origin = [dataSource distributedView:self positionForItemIndex: [currentItemNum intValue]];
				#endif
				
				[self setNeedsDisplayInRect: [self flipRectsYAxis: ibox]];
				
				ibox.origin.x += [event deltaX];
				ibox.origin.y += [event deltaY];
				
				// Apply grid to item, if necessary:
				if( (([event modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask && !snapToGrid)		// snapToGrid is toggled using command key.
					|| (([event modifierFlags] & NSCommandKeyMask) != NSCommandKeyMask && snapToGrid) 
					|| forceToGrid )
				{
					
					/*ibox.origin.x += gridSize.width /2;		// gridSize added so item snaps to closest grid location, not the one with the lowest coordinate.
					ibox.origin.y += gridSize.height /2;	// gridSize added so item snaps to closest grid location, not the one with the lowest coordinate.
					ibox.origin.x = (truncf((pos.x -contentInset) / gridSize.width) * gridSize.width) +contentInset;
					ibox.origin.y = (truncf((pos.y -contentInset) / gridSize.height) * gridSize.height) +contentInset;*/
					ibox = [self forceRectToGrid: ibox];
					[self itemNeedsDisplay: [currentItemNum intValue]];
				}
				
				[dataSource distributedView:self setPosition:ibox.origin forItemIndex: [currentItemNum intValue]];
				[self itemNeedsDisplay: [currentItemNum intValue]];
			}
			[self contentSizeChanged];
		}
	}
	
	if( [self acceptsFirstResponder] )
		[[self window] makeFirstResponder:self];
}


-(NSRect)	snapRectToGrid: (NSRect)box
{
	if( forceToGrid )
		box = [self forceRectToGrid:box];
	return box;
}


-(NSRect)	forceRectToGrid: (NSRect)box
{
	float		xoffs = 0,
				yoffs = 0;

	// Offset objects relative to content inset:
	box.origin.x -= contentInset;
	box.origin.y -= contentInset;
	
	// Move rect to positive coordinates, otherwise they crowd at 0,0:
	if( box.origin.x < 0 )
	{
		xoffs = (truncf((-box.origin.x) / gridSize.width) +1) * gridSize.width;
		box.origin.x += xoffs;
	}
	if( box.origin.y < 0 )
	{
		yoffs = (truncf((-box.origin.y) / gridSize.height) +1) * gridSize.height;
		box.origin.y += yoffs;
	}
	
	// Actually move it onto the grid:
	box.origin.x = truncf((box.origin.x +(gridSize.width /2)) / gridSize.width) * gridSize.width;
	box.origin.y = truncf((box.origin.y +(gridSize.width /2)) / gridSize.height) * gridSize.height;
	
	// Undo origin shift:
	if( xoffs > 0 )
		box.origin.x -= xoffs;
	if( yoffs > 0 )
		box.origin.y -= yoffs;
	
	// Undo content inset shift:
	box.origin.x += contentInset;
	box.origin.y += contentInset;
	
	// Return adjusted box:
	return box;
}


-(NSRect)	flipRectsYAxis: (NSRect)box
{
	NSRect		result = box;
	result.origin.y = [self frame].size.height -box.origin.y -box.size.height;
	
	return result;
}


// Point must be in regular (non-flipped) coordinates:
-(int)	getItemIndexAtPoint: (NSPoint)aPoint
{
	NSEnumerator*   indexEnny = [visibleItems reverseObjectEnumerator]; // Opposite from drawing order, so we hit last drawn object (on top) first.
	NSNumber*		currIndex = nil;
	
	while( currIndex = [indexEnny nextObject] )
	{
		int			x = [currIndex intValue];
		NSRect		box;
		
		box.size = cellSize;
		box.origin = [dataSource distributedView: self positionForCell:prototype atItemIndex: x];
		box = [self snapRectToGrid: box];
		box = [self flipRectsYAxis: box];

		// if we're in the vicinity...		
		if( NSPointInRect( aPoint, box ) )
		{
			NSColor *colorAtPoint = nil;

			// Lock focus on ourselves to perform some spot drawing:
			[self lockFocus];
				// First empty the pixels inside our box:
				[[NSColor clearColor] set];
				NSRectFillUsingOperation( box, NSCompositeClear );

				// Next, draw our cell and grab the color at our mouse:
				[prototype drawWithFrame:box inView:self];
				colorAtPoint = NSReadPixel(aPoint);
			[self unlockFocus];

			[self setNeedsDisplayInRect: box];  // Update or our temporary drawing screws up the looks.
			
			/* Now if we've found a color, and if it's sufficiently
				opaque, then call the hit a success: */
			if( colorAtPoint && [colorAtPoint alphaComponent] > 0.1 )
				return x;
		}
	}
	
	return -1;
}


// Rect must be in flipped coordinates:
-(int)	getItemIndexInRect: (NSRect)aBox
{
	NSEnumerator*   indexEnny = [visibleItems reverseObjectEnumerator];
	NSNumber*		currIndex = nil;
	while( currIndex = [indexEnny nextObject] )
	{
		int			x = [currIndex intValue];
		NSRect		box = [self rectForItemAtIndex:x];
		
		box = [self snapRectToGrid: box];
		box = [self flipRectsYAxis: box];
		
		if( NSIntersectsRect( aBox, box ) )
			return x;
	}
	
	return -1;
}


// Rect must be in flipped coordinates:
-(int)	getUncachedItemIndexInRect: (NSRect)aBox
{
	int		x, count = [dataSource numberOfItemsInDistributedView:self];
	
	for( x = 0; x < count; x++ )
	{
		NSRect		box = [self rectForItemAtIndex:x];
		box = [self snapRectToGrid: box];

		if( NSIntersectsRect( aBox, box ) )
			return x;
	}
	
	return -1;
}


/* Return the best rect for this object that encloses all items at their current positions plus the
	content inset: */
-(NSRect)	bestRect
{
	int		x, count = [dataSource numberOfItemsInDistributedView:self];
	NSRect	bestBox = [self frame];
	
	bestBox.size.width = bestBox.size.height = 0;
	
	for( x = 0; x < count; x++ )
	{
		NSRect		box = [self rectForItemAtIndex:x];
		box = [self snapRectToGrid: box];

		if( (box.size.width +box.origin.x) > bestBox.size.width )
			bestBox.size.width = (box.size.width +box.origin.x);
		if( (box.size.height +box.origin.y) > bestBox.size.height )
			bestBox.size.height = (box.size.height +box.origin.y);
	}
	
	bestBox.size.width += contentInset;
	bestBox.size.height += contentInset;
		
	return bestBox;
}

-(NSSize)	bestSize
{
	int		x, count = [dataSource numberOfItemsInDistributedView:self];
	float   minX = INT_MAX,
			maxX = INT_MIN,
			minY = INT_MAX,
			maxY = INT_MIN;
	
	for( x = 0; x < count; x++ )
	{
		NSRect		box = [self rectForItemAtIndex:x];
		box = [self snapRectToGrid: box];

		if( (box.size.width +box.origin.x) > maxX )
			maxX = (box.size.width +box.origin.x);
		if( (box.size.height +box.origin.y) > maxY )
			maxY = (box.size.height +box.origin.y);
		if( box.origin.x < minX )
			minX = box.origin.x;
		if( box.origin.y < minY )
			minY = box.origin.y;
	}
		
	return NSMakeSize( maxX -minX +(contentInset *2), maxY -minY +(contentInset*2) );
}


// Rect is in flipped coordinates:
-(NSRect)	rectForItemAtIndex: (int)index
{
	NSRect		box = NSMakeRect( 0,0, cellSize.width,cellSize.height );
	#if UKDISTVIEW_BACKWARDS_COMPATIBLE
	box.origin = [dataSource distributedView:self positionForCell:nil atItemIndex:index];
	#else
	box.origin = [dataSource distributedView: self positionForItemIndex: index];
	#endif
	return box;
}


// Rect is in item coordinates, i.e. flipped Y-axis as opposed to Quartz:
-(void) cacheVisibleItemIndexesInRect: (NSRect)inBox
{
	int		x = 0,
			count = [dataSource numberOfItemsInDistributedView:self];
	NSRect  currBox;
	
	[visibleItems removeAllObjects];
	
	for( x = 0; x < count; x++ )
	{
		currBox = [self rectForItemAtIndex: x];
		if( NSIntersectsRect( currBox, inBox ) )	// Visible!
			[visibleItems addObject: [NSNumber numberWithInt: x]];
	}
	
	visibleItemRect = inBox;
}


-(void) invalidateVisibleItemsCache
{
	visibleItemRect = NSZeroRect;
	[visibleItems removeAllObjects];
}


/* Move the items, maintaining their relative positions, so the topmost and leftmost items
	are positioned at exactly contentInset pixels from the top left: */
-(IBAction)	rescrollItems: (id)sender
{
	int		x, count = [dataSource numberOfItemsInDistributedView:self];
	int		leftPos = INT_MAX, topPos = INT_MAX,
			leftoffs, topoffs;
	
	//  Find topmost and leftmost positions of our items:
	for( x = 0; x < count; x++ )
	{
		NSRect		box = [self rectForItemAtIndex:x];

		if( box.origin.x < leftPos )
			leftPos = box.origin.x;
		if( box.origin.y < topPos )
			topPos = box.origin.y;
	}

	leftoffs = contentInset -leftPos;
	topoffs = contentInset -topPos;
	
	// Now reposition all our items:
	for( x = 0; x < count; x++ )
	{
		#if UKDISTVIEW_BACKWARDS_COMPATIBLE
		NSPoint		pos = [dataSource distributedView:self positionForCell:nil atItemIndex:x];
		#else
		NSPoint		pos = [dataSource distributedView:self positionForItemIndex:x];
		#endif
		pos.x += leftoffs;
		pos.y += topoffs;
		[dataSource distributedView:self setPosition:pos forItemIndex:x];
	}
	
	[self contentSizeChanged];
	[self setNeedsDisplay:YES];
}



/* -----------------------------------------------------------------------------
	windowFrameSizeForBestSize:
		This assumes this view is set up so it always keeps the same distance
		to window edges and resizes along with the window, i.e. the "Size" view
		in IB looks something like the following:
		
	    |
	 +--+--+
	 |  s  |       "s" and "un" are supposed to be "springs".
	-+un+un+-
	 |  s  |
	 +--+--+
	    |
	
	REVISIONS:
		2003-12-18	UK	Created.
   -------------------------------------------------------------------------- */

-(NSSize)   windowFrameSizeForBestSize
{
	// Calculate rect for our window's content area:
	NSRect		contentRect = [NSWindow contentRectForFrameRect:[[self window] frame] styleMask:[[self window] styleMask]];

	// Calculate how many pixels are around this view in the window:
	NSSize wdSize = contentRect.size;
	
	wdSize.width -= [[self enclosingScrollView] bounds].size.width;
	wdSize.height -= [[self enclosingScrollView] bounds].size.height;
	
	// Calc best size and enlarge it by that many pixels:
	NSSize  finalSize = [self bestSize];
	finalSize.width += wdSize.width;
	finalSize.height += wdSize.height;
	
	// Adjust for scrollbars:
	finalSize.width += 17;
	finalSize.height += 17;
	
	contentRect.size = finalSize;
	
	// Return that as best size for our window:
	return [NSWindow frameRectForContentRect:contentRect styleMask:[[self window] styleMask]].size;
}


-(void)  updateSelectionSet
{
	NSEnumerator*		selEnny = [selectionSet objectEnumerator];
	int					count = [dataSource numberOfItemsInDistributedView:self];
	NSNumber*			currIndex = nil;
	
	while( currIndex = [selEnny nextObject] )
	{
		if( [currIndex intValue] >= count )
			[selectionSet removeObject: currIndex];
	}
}


-(void)	reloadData
{
	[self invalidateVisibleItemsCache];
	[self updateSelectionSet];
	[self contentSizeChanged];
	[self setNeedsDisplay:YES];
}


-(void)	noteNumberOfItemsChanged
{
	[self reloadData];
}


-(void)	contentSizeChanged
{
	if( sizeToFit )
	{
		NSRect		box = [self bestRect];
		
		NSScrollView*	sv = [self enclosingScrollView];
		NSSize			svBox = [sv contentSize];
		
		if( svBox.width > box.size.width )
			box.size.width = svBox.width;
		if( svBox.height > box.size.height )
			box.size.height = svBox.height;
		
		// Adjust for change in size so window doesn't "scroll away":
		NSRect		oldFrame = [self frame];
		NSSize		sizeDiffs;
		
		sizeDiffs.width = box.size.width -oldFrame.size.width;
		sizeDiffs.height = box.size.height -oldFrame.size.height;
		
		NSPoint newScroll = [sv documentVisibleRect].origin;
		newScroll.x += sizeDiffs.width;
		newScroll.y += sizeDiffs.height;
		
		// Resize and maintain scroll position:
		[self setFrame:box];
		[[sv contentView] scrollToPoint: newScroll];
		[sv reflectScrolledClipView: [sv contentView]];
	}
}


/* -----------------------------------------------------------------------------
	resizeWithOldSuperviewSize:
		This view was resized. Make sure view is reloaded properly.
	
	REVISIONS:
		2003-12-20	UK	Commented.
   -------------------------------------------------------------------------- */

-(void) resizeWithOldSuperviewSize:(NSSize)oldSize
{
	[super resizeWithOldSuperviewSize:oldSize];
	
	[self contentSizeChanged];
}


/* -----------------------------------------------------------------------------
	draggingSourceOperationMaskForLocal:
		Drag support.
	
	REVISIONS:
		2003-12-20	UK	Created.
   -------------------------------------------------------------------------- */

-(NSDragOperation)  draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	if( [dataSource respondsToSelector:@selector(distributedView:draggingSourceOperationMaskForLocal:)] )
		return [dataSource distributedView:self draggingSourceOperationMaskForLocal: isLocal];
	else
		return NSDragOperationNone;
}



/* -----------------------------------------------------------------------------
	validateMenuItem:
		Make sure menu items are enabled properly.
	
	REVISIONS:
		2003-06-29	UK	Created.
   -------------------------------------------------------------------------- */

-(BOOL)	validateMenuItem: (NSMenuItem*)menuItem
{
	// Edit menu commands:
	if( [menuItem action] == @selector(selectAll:) )
		return allowsMultipleSelection;
	else if( [menuItem action] == @selector(deselectAll:) )
		return( ([self selectedItemCount] > 0) && allowsEmptySelection );
	// Grid, repositioning and other Finder-like behaviour:
	else if( [menuItem action] == @selector(positionAllItems:) )
		return YES;
	else if( [menuItem action] == @selector(snapAllItemsToGrid:) )
		return YES;
	else if( [menuItem action] == @selector(toggleDrawsGrid:) )
	{
		[menuItem setState: drawsGrid];
		return YES;
	}
	else if( [menuItem action] == @selector(toggleSnapToGrid:) )
	{
		[menuItem setState: snapToGrid];
		return YES;
	}
	else if( [menuItem action] == @selector(rescrollItems:) )	// Don't see why you'd want a menu item for this. You should really call this from your window zooming code.
		return YES;
	else if( [delegate respondsToSelector: [menuItem action]] )
	{
		if( [delegate respondsToSelector: @selector(validateMenuItem:)] )
			return [delegate validateMenuItem: menuItem];
		else
			return YES;
	}
	else
		return NO;
}

-(BOOL)	acceptsFirstResponder
{
	return YES;
}

-(BOOL)	becomeFirstResponder
{
	return [super becomeFirstResponder];
}

-(BOOL)	resignFirstResponder
{
	return [super resignFirstResponder];
}


-(BOOL) acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}


-(BOOL) respondsToSelector: (SEL)theSel
{
	return( [[delegate class] instancesRespondToSelector: theSel]
			|| [[self class] instancesRespondToSelector: theSel] );
}

// Delegation stuff:
-(void) forwardInvocation:(NSInvocation *)invocation
{
    if ([delegate respondsToSelector:[invocation selector]])
        [invocation invokeWithTarget: delegate];
    else
        [self doesNotRecognizeSelector:[invocation selector]];
}


-(NSMethodSignature*)   methodSignatureForSelector:(SEL)aSelector
{
	NSMethodSignature*		sig = [super methodSignatureForSelector: aSelector];
	if( sig == nil && [delegate respondsToSelector: aSelector] )
		sig = [delegate methodSignatureForSelector: aSelector];
	
	return sig;
}


@end


/* -----------------------------------------------------------------------------
	Data Source methods:
   -------------------------------------------------------------------------- */

@implementation NSObject (UKDistributedViewDataSource)

-(int)			numberOfItemsInDistributedView: (UKDistributedView*)distributedView
{
	return 0;
}

-(NSPoint)		distributedView: (UKDistributedView*)distributedView positionForCell:(NSCell*)cell atItemIndex: (int)row
{
	return NSZeroPoint;
}


-(void)			distributedView: (UKDistributedView*)distributedView setPosition: (NSPoint)pos forItemIndex: (int)row
{
	
}


-(NSPoint)		distributedView: (UKDistributedView*)distributedView positionForItemIndex: (int)index
{
	#if UKDISTVIEW_BACKWARDS_COMPATIBLE
	return [self distributedView: distributedView positionForCell:nil atItemIndex: index];
	#else
	return NSZeroPoint;
	#endif
}


-(void)			distributedView: (UKDistributedView*)distributedView setupCell: (NSCell*)cell forItemIndex: (int)index;
{
	#if UKDISTVIEW_BACKWARDS_COMPATIBLE
	[self distributedView: distributedView positionForCell: cell atItemIndex: index];
	#endif
}

@end


/* -----------------------------------------------------------------------------
	Delegate methods:
   -------------------------------------------------------------------------- */

@implementation NSObject (UKDistributedViewDelegate)

-(void) distributedView: (UKDistributedView*)distributedView cellClickedAtItemIndex: (int) item
{
	
}

-(void) distributedView: (UKDistributedView*)distributedView cellDoubleClickedAtItemIndex: (int) item
{
	
}

-(BOOL) distributedView: (UKDistributedView*)distributedView shouldSelectItemIndex: (int)item
{
	return YES;
}


-(void) distributedView: (UKDistributedView*)distributedView didSelectItemIndex: (int)item
{
	
}


@end

