//
//  UKFinderIconCell.h
//  Filie
//
//  Created by Uli Kusterer on Fri Dec 19 2003.
//  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
//

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>


// -----------------------------------------------------------------------------
//  Constants:
// -----------------------------------------------------------------------------

#define UKFIC_TEXT_VERTMARGIN		2		// How many pixels is selection supposed to extend above and below the title?
#define UKFIC_TEXT_HORZMARGIN		4		// How many pixels is selection supposed to extend to the left and right of the title?
#define UKFIC_SELBOX_VERTMARGIN		1		// How much distance do you want between top of cell/title and icon's highlight box?
#define UKFIC_SELBOX_HORZMARGIN		1		// How much distance do you want between right/left edges of cell and icon's highlight box?
#define UKFIC_SELBOX_OUTLINE_WIDTH  2		// Width of outline of selection box around icon.
#define UKFIC_IMAGE_VERTMARGIN		2		// Distance between maximum top/bottom edges of image and highlight box.
#define UKFIC_IMAGE_HORZMARGIN		2		// Distance between maximum left/right edges of image and highlight box.


// -----------------------------------------------------------------------------
//  Class declaration:
// -----------------------------------------------------------------------------

@interface UKFinderIconCell : NSActionCell
{
	NSString*			title;			// Title text to display under image.
	BOOL				selected;		// Is this cell currently selected?
	NSColor*			nameColor;		// Color to use for name. Defaults to white.
	NSColor*			boxColor;		// Color to use for the box around the icon (when highlighted). Defaults to grey.
	NSColor*			selectionColor; // Color to use for background of the highlighted name. Defaults to blue.
	NSCellImagePosition imagePosition;  // Image position relative to title.
}

-(id)		init;
-(id)		initImageCell: (NSImage*)img;	// Designated initializer.

-(void)		setHighlighted: (BOOL)isSelected;
-(void)		drawWithFrame: (NSRect)box inView: (NSView*)aView;

-(void)		setNameColor: (NSColor*)col;
-(NSColor*) nameColor;

-(void)		setBoxColor: (NSColor*)col;
-(NSColor*) boxColor;

-(void)		setSelectionColor: (NSColor*)col;
-(NSColor*) selectionColor;

-(void)		resetColors;

// Accessing image:
//setImage: and image are inherited from NSCell.
-(NSCellImagePosition)  imagePosition;
-(void)					setImagePosition: (NSCellImagePosition)newImagePosition;	// Currently, only "above" and "below" work.

// Get/set title in table views etc.:
-(id)   objectValue;
-(void) setObjectValue:(id <NSCopying>)obj;


@end


NSString*   UKStringByTruncatingStringWithAttributesForWidth( NSString* s,
																NSDictionary* attrs,
																float wid );
