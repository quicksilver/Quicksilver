/*
	FSBrowserCell.m
	Copyright (c) 2001-2002, Apple Computer, Inc., all rights reserved.
	Author: Chuck Pisula

	Milestones:
	Initially created 3/1/01

	Browers cell that knows how to display file system info obtained from an FSNodeInfo object.
*/

/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple’s copyrights in 
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "FSNodeInfo.h"
#import "FSBrowserCell.h"

#define ICON_INSET_VERT		2.0	/* The size of empty space between the icon end the top/bottom of the cell */ 
#define ICON_SIZE 		16.0	/* Our Icons are ICON_SIZE x ICON_SIZE */
#define ICON_INSET_HORIZ	4.0	/* Distance to inset the icon from the left edge. */
#define ICON_TEXT_SPACING	2.0	/* Distance between the end of the icon and the text part */

@interface FSBrowserCell (PrivateUtilities)
// This is a category in FSBrowserCell since it somewhat UI related and its a good idea to keep the UI part separate from the low level parts.
+ (NSDictionary*)stringAttributesForNode:(FSNodeInfo*)node;
@end

@implementation FSBrowserCell

/*
+ (NSImage*)branchImage {
    // Override the default branch image (we don't want the arrow).
    return nil;
}

+ (NSImage*)highlightedBranchImage {
    // Override the default branch image (we don't want the arrow).
    return nil;
}
*/

- (void)dealloc {
    [iconImage release];
    iconImage = nil;
    [super dealloc];
}

- (void)setAttributedStringValueFromFSNodeInfo:(FSNodeInfo*)node {
    // Given a particular FSNodeInfo object set up our display properties.
    NSString *stringValue = [node lastPathComponent];

//    if ([node isExtensionHidden])
 //       stringValue=[stringValue stringByDeletingPathExtension];

    // Set the text part.   FSNode will format the string (underline, bold, etc...) based on various properties of the file.
    [self setStringValue:stringValue];
    
    // Set the image part.  FSNodeInfo knows how to look up the proper icon to use for a give file/directory.
    [self setIconImage: [NSImage imageNamed:@"LoadingFileIconSmall"]];
    
    // If we don't have access to the file, make sure the user can't select it!
    [self setEnabled: [node isReadable]];

    // Make sure the cell knows if it has children or not.
    [self setLeaf:![node isDirectory]];
}

- (void)setIconImage: (NSImage *)image {
    [iconImage autorelease];
    iconImage = [image copy];
    
    // Make sure the image is going to display at the size we want.
    [iconImage setSize: NSMakeSize(ICON_SIZE,ICON_SIZE)];
}

- (NSImage*)iconImage {
    return iconImage;
}

- (NSSize)cellSizeForBounds:(NSRect)aRect {
    // Make our cells a bit higher than normal to give some additional space for the icon to fit.
    NSSize theSize = [super cellSizeForBounds:aRect];
    theSize.width += [[self iconImage] size].width + ICON_INSET_HORIZ + ICON_INSET_HORIZ;
    theSize.height = ICON_SIZE + ICON_INSET_VERT * 2.0;
    return theSize;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {    
    if (iconImage != nil) {
        NSSize	imageSize = [iconImage size];
        NSRect	imageFrame, highlightRect, textFrame;
	
	// Divide the cell into 2 parts, the image part (on the left) and the text part.
	NSDivideRect(cellFrame, &imageFrame, &textFrame, ICON_INSET_HORIZ + ICON_TEXT_SPACING + imageSize.width, NSMinXEdge);
        imageFrame.origin.x += ICON_INSET_HORIZ;
        imageFrame.size = imageSize;

	// Adjust the image frame top account for the fact that we may or may not be in a flipped control view, since when compositing
	// the online documentation states: "The image will have the orientation of the base coordinate system, regardless of the destination coordinates".
        if ([controlView isFlipped]) imageFrame.origin.y += ceil((textFrame.size.height + imageFrame.size.height) / 2);
        else imageFrame.origin.y += ceil((textFrame.size.height - imageFrame.size.height) / 2);

	// Depending on the current state, set the color we will highlight with.
        if ([self isHighlighted]) {
	    // use highlightColorInView instead of [NSColor selectedControlColor] since NSBrowserCell slightly dims all cells except those in the right most column.
	    // The return value from highlightColorInView will return the appropriate one for you. 
	    [[self highlightColorInView: controlView] set];
        } else {
	    [[NSColor controlBackgroundColor] set];
	}

	// Draw the highligh, bu only the portion that won't be caught by the call to [super drawInteriorWithFrame:...] below.  No need to draw parts 2 times!
	highlightRect = NSMakeRect(NSMinX(cellFrame), NSMinY(cellFrame), NSWidth(cellFrame) - NSWidth(textFrame), NSHeight(cellFrame));
	NSRectFill(highlightRect);
	
	// Blit the image.
        [iconImage compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
    
	// Have NSBrowser kindly draw the text part, since it knows how to do that for us, no need to re-invent what it knows how to do.
	[super drawInteriorWithFrame:textFrame inView:controlView];
    } else {
	// Atleast draw something if we couldn't find an icon.  You may want to do something more intelligent.
    	[super drawInteriorWithFrame:cellFrame inView:controlView];
    }
}

@end


@implementation FSBrowserCell (PrivateUtilities)

+ (NSDictionary*)stringAttributesForNode:(FSNodeInfo*)node {
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    [attrs setObject: [NSFont systemFontOfSize:11] forKey:NSFontAttributeName];
    return attrs;
}

@end

