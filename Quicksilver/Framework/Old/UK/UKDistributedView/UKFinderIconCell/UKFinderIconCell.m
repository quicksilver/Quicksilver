//
//  UKFinderIconCell.m
//  Filie
//
//  Created by Uli Kusterer on Fri Dec 19 2003.
//  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
//

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import "UKFinderIconCell.h"
#import "NSBezierPathCappedBoxes.h"


@implementation UKFinderIconCell


// -----------------------------------------------------------------------------
//  Designated initializer:
// -----------------------------------------------------------------------------

-(id)   initImageCell: (NSImage*)img
{
	if( self = [super initImageCell: img] )
	{
		selected = NO;
		title = [@"Untitled" retain];
		nameColor = [[NSColor controlBackgroundColor] retain];
		boxColor = [[NSColor secondarySelectedControlColor] retain];
		selectionColor = [[NSColor alternateSelectedControlColor] retain];
		imagePosition = NSImageAbove;
	}
	
	return self;
}


// -----------------------------------------------------------------------------
//  Initializer for us lazy ones:
// -----------------------------------------------------------------------------

-(id)   init
{
	return [self initImageCell: [NSImage imageNamed: @"NSApplicationIcon"]];
}


// -----------------------------------------------------------------------------
//  Destructor:
// -----------------------------------------------------------------------------

-(void) dealloc
{
	[title release];
	[nameColor release];
	[boxColor release];
	[selectionColor release];
	
	[super dealloc];
}


// -----------------------------------------------------------------------------
//  Reset boxColor, nameColor and selectionColor to the defaults:
// -----------------------------------------------------------------------------

-(void) resetColors
{
	[self setNameColor: [NSColor controlBackgroundColor]];
	[self setBoxColor: [NSColor secondarySelectedControlColor]];
	[self setSelectionColor: [NSColor alternateSelectedControlColor]];
}


// -----------------------------------------------------------------------------
//  Mutator for cell selection state:
// -----------------------------------------------------------------------------

-(void) setHighlighted: (BOOL)isSelected
{
	selected = isSelected;
}


// -----------------------------------------------------------------------------
//  Draws everything you see of the cell:
// -----------------------------------------------------------------------------

-(void) drawWithFrame: (NSRect)box inView: (NSView*)aView
{
	NSRect			imgBox = box,
					textBox = box,
					textBgBox = box;
	NSDictionary*   attrs = nil;
	NSColor*		bgColor = nil;
	NSString*		displayTitle = title;
	
	[NSGraphicsContext saveGraphicsState];
	[NSBezierPath clipRect: box];   // Make sure we don't draw outside our cell.
	
	// Set up text attributes for title:
	if( selected )
	{
		attrs = [NSDictionary dictionaryWithObjectsAndKeys:
						[NSFont systemFontOfSize: 12], NSFontAttributeName,
						[NSColor alternateSelectedControlTextColor], NSForegroundColorAttributeName,
						nil];
		bgColor = selectionColor;
	}
	else
	{
		attrs = [NSDictionary dictionaryWithObjectsAndKeys:
						[NSFont systemFontOfSize: 12], NSFontAttributeName,
						[NSColor controlTextColor], NSForegroundColorAttributeName,
						nil];
		bgColor = nameColor;
	}
	
	NSSize			txSize = [title sizeWithAttributes: attrs];
	
	// Truncate string if needed:
	displayTitle = UKStringByTruncatingStringWithAttributesForWidth( title, attrs,
							(box.size.width -txSize.height -(2* UKFIC_TEXT_HORZMARGIN)) );

	// Calculate rectangle for text:
	txSize = [displayTitle sizeWithAttributes: attrs];
	
	if( imagePosition == NSImageAbove		// Finder icon view (big, title below image).
		|| imagePosition == NSImageBelow )  // Title *above* image.
	{
		textBox.size = txSize;
		textBox.origin.x += truncf((box.size.width -txSize.width) / 2);  // Center our text at cell's bottom.
		if( imagePosition == NSImageAbove )
			textBox.origin.y += UKFIC_TEXT_VERTMARGIN;
		else
			textBox.origin.y = box.origin.y +box.size.height -txSize.height -UKFIC_TEXT_VERTMARGIN;
		textBgBox = NSInsetRect( textBox, -UKFIC_TEXT_HORZMARGIN -truncf(txSize.height /2),
									-UKFIC_TEXT_VERTMARGIN );		// Give us some room around our text.
	}
	else if( imagePosition == NSImageLeft
			|| imagePosition == NSImageRight )
	{
		// TODO: Sidewards titles are broken.
		
		textBox.size = txSize;
		textBox.origin.y += truncf((box.size.height -txSize.height) / 2);  // Center our text vertically in cell.
		if( imagePosition == NSImageRight )
			textBox.origin.x += UKFIC_TEXT_VERTMARGIN;
		else
			textBox.origin.x = box.origin.x +box.size.width -txSize.width -UKFIC_TEXT_VERTMARGIN;
		textBgBox = NSInsetRect( textBox, -UKFIC_TEXT_VERTMARGIN, -UKFIC_TEXT_HORZMARGIN -truncf(txSize.height /2) );		// Give us some room around our text.
	}
		
	// Draw text background either with white, or with "selected" color:
	[bgColor set];
	[[NSBezierPath bezierPathWithCappedBoxInRect: textBgBox] fill];   // draw text bg.
	
	// Draw actual text:
	[displayTitle drawInRect: textBox withAttributes: attrs];
	
	// Prepare image and image highlight rect:
	switch( imagePosition )
	{
		case NSImageAbove:
			imgBox.origin.y += textBgBox.size.height;
			imgBox.size.height -= textBgBox.size.height;
			break;
			
		case NSImageBelow:
			imgBox.size.height -= textBgBox.size.height;
			break;
		
		// TODO: Sidewards titles are broken.
		case NSImageLeft:
			imgBox.origin.y += textBgBox.size.width;
			imgBox.size.width -= textBgBox.size.width;
			break;
			
		case NSImageRight:
			imgBox.size.width -= textBgBox.size.width;
			break;
		
		case NSNoImage:
		case NSImageOnly:
		case NSImageOverlaps:
			NSLog(@"UKFinderIconCell - Unsupported image position mode.");
			break;
	}
	
	imgBox = NSInsetRect( imgBox, UKFIC_SELBOX_HORZMARGIN +UKFIC_SELBOX_OUTLINE_WIDTH,
									UKFIC_SELBOX_VERTMARGIN +UKFIC_SELBOX_OUTLINE_WIDTH );
	
	// Make sure icon box is pretty and square:
	if( imgBox.size.height < imgBox.size.width )
	{
		float   diff = imgBox.size.width -imgBox.size.height;
		
		imgBox.size.width = imgBox.size.height; // Force width to be same as height.
		imgBox.origin.x += truncf(diff/2);		// Center narrower box in cell.
	}
	
	// If selected, draw image highlight rect:
	if( selected )
	{
		// Set up line for selection outline:
		NSLineJoinStyle svLjs = [NSBezierPath defaultLineJoinStyle];
		[NSBezierPath setDefaultLineJoinStyle: NSRoundLineJoinStyle];
		float			svLwd = [NSBezierPath defaultLineWidth];
		[NSBezierPath setDefaultLineWidth: UKFIC_SELBOX_OUTLINE_WIDTH];
		
		// Draw selection outline:
		NSColor*	scc = boxColor;
		[[scc colorWithAlphaComponent: 0.7] set];			// Slightly transparent body first.
		[NSBezierPath fillRect: imgBox];
		[scc set];											// Opaque rounded boundaries next.
		[NSBezierPath strokeRect: imgBox];
		
		// Clean up:
		[NSBezierPath setDefaultLineJoinStyle: svLjs];
		[NSBezierPath setDefaultLineWidth: svLwd];
		[[NSColor blackColor] set];
	}
	
	// Draw icon in box:
	imgBox = NSInsetRect( imgBox, UKFIC_IMAGE_HORZMARGIN, UKFIC_IMAGE_VERTMARGIN );
	
	[super drawWithFrame: imgBox inView: aView];
	
	[NSGraphicsContext restoreGraphicsState];
}


// -----------------------------------------------------------------------------
//  Accessor for cell title string ("file name"):
// -----------------------------------------------------------------------------

-(NSString*)	title
{
	return title;
}


// -----------------------------------------------------------------------------
//  Mutator for cell title string ("file name"):
// -----------------------------------------------------------------------------

-(void)			setTitle: (NSString*)tle
{
	[tle retain];
	[title release];
	title = tle;
}


// -----------------------------------------------------------------------------
//  Mutator for name background color:
// -----------------------------------------------------------------------------

-(void)		setNameColor: (NSColor*)col
{
	[col retain];
	[nameColor release];
	nameColor = col;
}


// -----------------------------------------------------------------------------
//  Accessor for name background color:
// -----------------------------------------------------------------------------

-(NSColor*) nameColor
{
	return nameColor;
}


// -----------------------------------------------------------------------------
//  Mutator for icon highlight box color:
// -----------------------------------------------------------------------------

-(void)		setBoxColor: (NSColor*)col
{
	[col retain];
	[boxColor release];
	boxColor = col;
}


// -----------------------------------------------------------------------------
//  Accessor for icon highlight box color:
// -----------------------------------------------------------------------------

-(NSColor*) boxColor
{
	return boxColor;
}


// -----------------------------------------------------------------------------
//  Mutator for name highlight color:
// -----------------------------------------------------------------------------

-(void)		setSelectionColor: (NSColor*)col;
{
	[col retain];
	[selectionColor release];
	selectionColor = col;
}


// -----------------------------------------------------------------------------
//  Accessor for name highlight color:
// -----------------------------------------------------------------------------

-(NSColor*) selectionColor;
{
	return selectionColor;
}


-(NSCellImagePosition)  imagePosition
{
    return imagePosition;
}

-(void) setImagePosition: (NSCellImagePosition)newImagePosition
{
   imagePosition = newImagePosition;
}


-(id)   objectValue
{
	return title;
}


-(void) setObjectValue:(id <NSCopying>)obj
{
	if( [(NSObject*)obj isKindOfClass: [NSString class]] )
		title = [(NSObject*)obj retain];
	else
		title = [[(id)obj stringValue] retain];
}




@end


// -----------------------------------------------------------------------------
//  Returns a truncated version of the specified string that fits a width:
//		Appends three periods as an "ellipsis" to the string to indicate that
//		it was truncated.
// -----------------------------------------------------------------------------

NSString*   UKStringByTruncatingStringWithAttributesForWidth( NSString* s, NSDictionary* attrs, float wid )
{
	NSAutoreleasePool*  pool = [[NSAutoreleasePool alloc] init];
	NSString*			currString = s;
	NSSize				txSize = [currString sizeWithAttributes: attrs];
	int					lastKept;
	lastKept = [currString length] -1;
	
	while( txSize.width > wid )
	{
		if( lastKept <= 1 )
			break;
		
		lastKept--;
		
		currString = [[s substringToIndex: lastKept] stringByAppendingString: @"..."];
		txSize = [currString sizeWithAttributes: attrs];
	}
	
	[currString retain];		// Make sure result isn't autoreleased.
	
	[pool release];
	
	[currString autorelease];   // Balance retain and add it to current pool.
	
	return currString;
}