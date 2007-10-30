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
				NSIMage or similar.

	AUTHOR:		M. Uli Kusterer (UK), (c) 2003, all rights reserved.

	REVISIONS:
		2003-06-24	UK	Created.
   ========================================================================== */

/* -----------------------------------------------------------------------------
	Headers:
   -------------------------------------------------------------------------- */

#import <AppKit/AppKit.h>


/* -----------------------------------------------------------------------------
	Constants:
   -------------------------------------------------------------------------- */

/* Set this to zero to cause "snap guides" to be drawn as simple blue boxes
	with a semi-transparent white fill. If this is on (the default) you'll
	get a transparent version of the cell drawn in the location it will snap
	to. */

#ifndef UKDISTVIEW_DRAW_FANCY_SNAP_GUIDES
#define UKDISTVIEW_DRAW_FANCY_SNAP_GUIDES		1
#endif

/* Set this to 0 to cause deprecated methods to be excluded. This is useful
	for spotting where your app still makes calls to them.
	Right now, this turns on some experimental code, so leave this at 1 if
	you're shipping production code. */

#ifndef UKDISTVIEW_BACKWARDS_COMPATIBLE
#define UKDISTVIEW_BACKWARDS_COMPATIBLE			1
#endif

/* The following is used to determine how many items to cache around the ones
	actually visible. More means speedier scrolling, less means better drawing
	and mouse tracking performance. Note that this doesn't really find that
	number of items on each side, but rather just extends the rect in which
	items must lie to be cached so it can hold that many items. */
#ifndef UKDISTVIEW_INVIS_ITEMS_CACHE_COUNT
#define UKDISTVIEW_INVIS_ITEMS_CACHE_COUNT		5
#endif


/* This is the pasteboard type that is used during a real "drag and drop"
	drag to add the positions of the dragged items to the drag. Note that
	these positions are relative to the location of the dragged image, i.e.
	if you drag 5 items, the one in the lower left will probably be at 0,0.
	The coordinates are stored as an array of NSStrings, and are in Quartz
	coordinates, i.e. the y axis increases upwards. */
#define UKDistributedViewPositionsPboardType	@"UKDistributedViewPositionsPboardType"

/* -----------------------------------------------------------------------------
	UKDistributedView:
   -------------------------------------------------------------------------- */

@interface UKDistributedView : NSView
{
// You *should* be using the accessors below:
	IBOutlet id			dataSource;					// The data source thet provides our items.
	IBOutlet id			delegate;					// The delegate that receives messages from us.
	NSSize				cellSize;					// Size of cells and grid when ordering items by grid.
	NSSize				gridSize;					// Size of grid to align items on. Usually, this is half our cell size.
	float				contentInset;				// How many pixels of border to leave around the items.
	BOOL				forceToGrid;				// Force all cells' positions to the grid. This behaves like "keep arranged by name" in Finder, and doesn't change actual cell positions.
	BOOL				snapToGrid;					// Force moved and new cells' positions to the grid. This behaves like "snap to grid" in MacOS 9's Finder and actually changes cell positions, but doesn't move existing cells.
	BOOL				dragMovesItems;				// Dragging an item changes its position.
	NSCell*				prototype;					// The prototype cell used for our items.
	NSMutableSet*		selectionSet;				// The selection.
	BOOL				allowsMultipleSelection;	// Can select more than one item?
	BOOL				allowsEmptySelection;		// Can select less than one item?
	BOOL				useSelectionRect;			// May user drag in empty areas to get a "rubber band"-style selection rect?
	BOOL				sizeToFit;					// Should this view always resize to enclose its items?
	BOOL				showSnapGuides;				// Show position indicator boxes during drag with grid?
	BOOL				drawsGrid;					// Draw lines where the grid is?
	NSColor*			gridColor;					// Color to use for grid lines.
	BOOL				multiPositioningMode;		// YES when we're in multi-position mode, which causes a speed-up when positioning new items by doing some caching.

// private: *do not use*
	int					mouseItem;					// Item currently being tracked on a click.
	NSPoint				lastPos;					// Last mouse position during mouse tracking.
	NSRect				selectionRect;				// Selection rect while we're tracking it.
	BOOL				drawSnappedRects;			// Draw "snap position" indicator rects behind selected items.
	NSPoint				lastSuggestedItemPos;		// Cached item position for multiPositionMode to more quickly allow positioning new items.
	NSRect				visibleItemRect;			// Rect in which we last cached the indexes of visible items.
	NSMutableArray*		visibleItems;				// Cached indexes of the items that are visible in the visibleItemRect.
	int					dragDestItem;				// Item being highlighted during drop.
	NSPoint				dragStartImagePos;			// Position dragged image started out in.
}

// Data source & delegate:
-(id)				dataSource;
-(void)				setDataSource: (id)d;

-(id)				delegate;
-(void)				setDelegate: (id)d;

// Selection:
-(void)				setAllowsMultipleSelection: (BOOL)state;
-(BOOL)				allowsMultipleSelection;

-(void)				setAllowsEmptySelection: (BOOL)state;
-(BOOL)				allowsEmptySelection;

-(void)				setUseSelectionRect: (BOOL)state;		// Set to YES to get a "rubber-band" selection rectangle when empty areas are clicked.
-(BOOL)				useSelectionRect;

-(int)				selectedItemCount;
-(NSEnumerator*)	selectedItemEnumerator;

-(void)				selectItem: (int)index byExtendingSelection: (BOOL)ext;
-(void)				selectItemsInRect: (NSRect)aBox byExtendingSelection: (BOOL)ext;
-(IBAction)			selectAll: (id)sender;
-(IBAction)			deselectAll: (id)sender;

// UKDistView-specific actions:
-(IBAction)			toggleDrawsGrid: (id)sender;
-(IBAction)			toggleSnapToGrid: (id)sender;

// Options for behavior:
-(void)		setForceToGrid: (BOOL)state;	// Nudges all items into the grid when displaying/hit testing.
-(BOOL)		forceToGrid;

-(void)		setSnapToGrid: (BOOL)state;		// Snaps items moved by the user and newly created ones to the grid, but keeps existing items at their positions.
-(BOOL)		snapToGrid;

-(void)		setShowSnapGuides: (BOOL)state;	// Shows little boxes when dragging an item with grid on, so the user knows where the item will actually end up.
-(BOOL)		showSnapGuides;

-(void)		setDrawsGrid: (BOOL)state;
-(BOOL)		drawsGrid;

-(void)		setGridColor: (NSColor*)c;
-(NSColor*)	gridColor;

-(void)		setDragMovesItems: (BOOL)state;	// Clicking an item allows the user to drag it around.
-(BOOL)		dragMovesItems;

// The cell used for displaying items:
-(id)		prototype;
-(void)		setPrototype: (NSCell*)aCell;

// Data management:
-(void)		noteNumberOfItemsChanged;
-(void)		reloadData;

// Sizing, margins etc.:
-(void)		setContentInset: (float)inset;	// Set margin around content area. This border isn't really enforced, but is used by the positioning and rescrolling methods.
-(float)	contentInset;

-(void)		setCellSize: (NSSize)size;	// Cell size. All items must be the same size. Also changes gridSize to cellSize /2.
-(NSSize)	cellSize;

-(void)		setGridSize: (NSSize)size;
-(NSSize)	gridSize;

-(void)		setSizeToFit: (BOOL)state;	// Always make this object resize so it encloses all its items or fills the visible area of the containing scroll view.
-(BOOL) 	sizeToFit;

/* Determining/changing positions of items in this view:
	Note that this changes the actual item positions, *permanently*. */
-(NSPoint)	suggestedPosition;						// Get best position for a new item.

-(void)		positionItem: (int)itemIndex;			// Move an item from its current to the next best position.
-(void)		setMultiPositioningMode: (BOOL)state;   // Set this to YES to speed up groups of positionItem: calls
-(BOOL)		multiPositioningMode;

-(IBAction)	positionAllItems: (id)sender;			// Places all items on grid positions, starting at the top left in horizontal lines. They are put in their natural order, i.e. starting with 0 in the top left, 1 to its right etc.
-(IBAction)	snapAllItemsToGrid: (id)sender;			// Places all items on the nearest grid positions. Does the same as "clean up" does in the Finder.
-(NSRect)	rectForItemAtIndex: (int)index;			// Returns a flipped rect.

// Drawing:
-(void)		itemNeedsDisplay: (int)itemNb;			// Cause redraw of an item (eventually calls setNeedsDisplayInRect: on this view).

// Hit-testing:
-(int)		getItemIndexAtPoint: (NSPoint)aPoint;
-(int)		getItemIndexInRect: (NSRect)aBox;		// aBox must have a reversed Y-axis. This checks for intersection of the two rects.

// Goodies for zooming/sizing windows:
-(IBAction)	rescrollItems: (id)sender;		// This is what Finder X never gets right. This moves all items so the leftmost one is at the left of the view and the topmost one at the top, removing any empty space above them, but not changing the items' relative positions.
-(NSRect)	bestRect;						// Do this after a rescroll to get the best size for showing all window contents at their current positions.
-(NSSize)	bestSize;						// Similar to bestRect, but returns the extents of all items (plus margins). I.e. this is what bestRect.size would be after a rescroll.
-(NSSize)   windowFrameSizeForBestSize;		// Useful for zooming. Calls bestSize to determine a good size for this view.

// Customization:
-(void)		drawSnapGuideInRect: (NSRect)box;	// Draws one of the "snap guide" boxes indicating where your item will end up.

// Drag & drop:
-(NSImage*) dragImageForItems:(NSArray*)dragIndexes event:(NSEvent*)dragEvent
				dragImageOffset:(NSPointPointer)dragImageOffset;

// private:
-(NSRect)	snapRectToGrid: (NSRect)box;	// Calls forceRectToGrid if forceToGrid is true, otherwise returns the rect unmodified.
-(NSRect)	forceRectToGrid: (NSRect)box;
-(NSRect)	flipRectsYAxis: (NSRect)box;
-(void)		contentSizeChanged;
-(void)		drawGridForDrawRect: (NSRect)rect;
-(void)		drawCellsForDrawRect: (NSRect)rect;
-(void)		drawSelectionRectForDrawRect: (NSRect)rect;
-(void)		selectionSetNeedsDisplay;

-(void)		cacheVisibleItemIndexesInRect: (NSRect)inBox;   // Build cache of (potentially) visible items used for drawing and mouse tracking.
-(void)		invalidateVisibleItemsCache;
-(int)		getUncachedItemIndexInRect: (NSRect)aBox;
-(NSRect)   rectAroundItems: (NSArray*)dragIndexes;

-(void)		initiateDrag: (NSEvent*)event;
-(void)		initiateMove;
-(void)		addPositionsOfItems: (NSArray*)indexes toPasteboard: (NSPasteboard*)pboard;

@end


/* -----------------------------------------------------------------------------
	Data source protocol:
   -------------------------------------------------------------------------- */

@interface NSObject (UKDistributedViewDataSource)

/* NOTE: Item positions are in "flipped" coordinates, i.e. the y-axis has
		been reversed and starts at the top and increases down. That way,
		items will not need to be repositioned when the view or window
		are resized. */

/* You *must* implement these to do anything useful:
	You are supposed to directly manipulate the cell passed to display your
	data in it appropriately. Handy tip: Messages to nil objects are simply
	ignored. */
-(int)			numberOfItemsInDistributedView: (UKDistributedView*)distributedView;

#if UKDISTVIEW_BACKWARDS_COMPATIBLE
-(NSPoint)		distributedView: (UKDistributedView*)distributedView
						positionForCell:(NSCell*)cell /* may be nil if the view only wants the item position. */
						atItemIndex: (int)row;
#endif

// Implement this if you want the user to be able to reposition your items:
-(void)			distributedView: (UKDistributedView*)distributedView
						setPosition: (NSPoint)pos
						forItemIndex: (int)row;

// Experimental: (Use distributedView:positionForCell:atItemIndex: for now)
-(NSPoint)		distributedView: (UKDistributedView*)distributedView positionForItemIndex: (int)index;
-(void)			distributedView: (UKDistributedView*)distributedView setupCell: (NSCell*)cell forItemIndex: (int)index;

@end


// Drag & drop:
//  These are optional. If not implemented, but setPosition is, you can still
//  perform old-style "live" moving of the items inside their window.

@interface NSObject (UKDistributedViewDnDDataSource)

-(BOOL)				distributedView: (UKDistributedView*)dv writeItems:(NSArray*)indexes
						toPasteboard: (NSPasteboard*)pboard;

-(NSDragOperation)  distributedView: (UKDistributedView*)dv
						draggingSourceOperationMaskForLocal: (BOOL)isLocal;

-(NSDragOperation)  distributedView: (UKDistributedView*)dv validateDrop: (id <NSDraggingInfo>)info
						proposedItem: (int*)row;	// Change "row", if you want. -1 means it's not on any item.

-(BOOL)				distributedView: (UKDistributedView*)dv acceptDrop:(id <NSDraggingInfo>)info
						onItem:(int)row;

@end


/* -----------------------------------------------------------------------------
	Delegate protocol:
   -------------------------------------------------------------------------- */

@interface NSObject (UKDistributedViewDelegate)

// Called upon a mouseUp in a cell: (except if it was a drag)
-(void) distributedView: (UKDistributedView*)distributedView cellClickedAtItemIndex: (int)item;

// Called on the second mouseDown of a double-click in a cell:
-(void) distributedView: (UKDistributedView*)distributedView cellDoubleClickedAtItemIndex: (int)item;

// Selection changes: (not sent for programmatic selection changes)
-(BOOL) distributedView: (UKDistributedView*)distributedView shouldSelectItemIndex: (int)item;
-(void) distributedView: (UKDistributedView*)distributedView didSelectItemIndex: (int)item;

@end


/* -----------------------------------------------------------------------------
	Notifications:
   -------------------------------------------------------------------------- */

extern NSString*		UKDistributedViewSelectionDidChangeNotification;	// Object is the UKDistributedView.

