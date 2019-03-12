/*
	ImageAndTextCell.m
	Copyright (c) 2001 by Apple Computer, Inc., all rights reserved.
	Author: Chuck Pisula

	Milestones:
	Initially created 3/1/01

 Subclass of NSTextFieldCell which can display text and an image simultaneously.
 */

/*
IMPORTANT: This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation,
 modification or redistribution of this Apple software constitutes acceptance of these
 terms. If you do not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.

 In consideration of your agreement to abide by the following terms, and subject to these
 terms, Apple grants you a personal, non-exclusive license, under Apple's copyrights in
 this original Apple software (the "Apple Software"), to use, reproduce, modify and
 redistribute the Apple Software, with or without modifications, in source and/or binary
 forms; provided that if you redistribute the Apple Software in its entirety and without
 modifications, you must retain this notice and the following text and disclaimers in all
 such redistributions of the Apple Software. Neither the name, trademarks, service marks
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your
 derivative works or by other works in which the Apple Software may be incorporated.

 The Apple Software is provided by Apple on an "AS IS" basis. APPLE MAKES NO WARRANTIES,
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

#import "QSImageAndTextCell.h"
#import <QSFoundation/NSGeometry_BLTRExtensions.h>
#import <QSFoundation/NSImage_BLTRExtensions.h>

@implementation QSImageAndTextCell


- (id)copyWithZone:(NSZone *)zone {
	QSImageAndTextCell *cell = (QSImageAndTextCell *)[super copyWithZone:zone];
	cell->image = nil;
	[cell setImage:image];
	return cell;
}

- (void)setImage:(NSImage *)anImage {
	if (anImage != image) {
		image = anImage;
	}
}

- (NSImage *)image {
	return image;
}

- (NSRect) imageFrameForCellFrame:(NSRect)cellFrame {
	if (image != nil) {
		NSRect imageFrame;
		imageFrame.size = [image size];
		imageFrame.origin = cellFrame.origin;
		imageFrame.origin.x += 3;
		imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
		return imageFrame;
	} else
		return NSZeroRect;
}

- (void)setObjectValue:(id)object {
	if ([object isKindOfClass:[NSString class]]) {
		[super setObjectValue:object];
	} else {
		@try {
			id value;
			value = [object valueForKey:@"text"];
			[super setObjectValue:value?value:@""];
			value = [object valueForKey:@"image"];
			[self setImage:value];
		}
		@catch (NSException *exception) {
			[super setObjectValue:@""];
			NSLog(@"Error %@", exception);
		}
	}
}

- (CGFloat) imageWidthForFrame:(NSRect)frame {
	if (imageSize.width) {
		return imageSize.width;
	} else {
		return NSHeight(frame);
	}

}
- (NSRect) textRectForFrame:(NSRect)frame {
	NSRect textFrame, imageFrame;
	NSDivideRect (frame, &imageFrame, &textFrame, 1+[self imageWidthForFrame:frame] *1.125, NSMinXEdge);
	return textFrame;
}
- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
	editing = YES;
	NSRect textFrame = [self textRectForFrame:aRect];
	[super editWithFrame: textFrame inView: controlView editor:textObj delegate:anObject event: theEvent];
}
- (void)endEditing:(NSText *)textObj {
	editing = NO;
	[super endEditing:textObj];

}
//- (NSText *)setUpFieldEditorAttributes:(NSText *)textObj {
//	[super setUpFieldEditorAttributes:textObj];
//	[textObj setTextColor:[NSColor controlTextColor]];
//	return textObj;
//
//}
- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength {
	NSRect textFrame = [self textRectForFrame:aRect];
	[super selectWithFrame: textFrame inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	if (image != nil) {
		NSSize	theImageSize;
		NSRect	imageFrame;

		if (NSHeight(cellFrame) <= 18) {
			theImageSize = QSSize16; //NSMakeSize(NSHeight(cellFrame), NSHeight(cellFrame) );
		} else {
			theImageSize = NSMakeSize(NSHeight(cellFrame), NSHeight(cellFrame) );
		}

		NSRect rest;
		NSDivideRect(cellFrame, &imageFrame, &rest, 1+[self imageWidthForFrame:cellFrame] *1.125, NSMinXEdge);
		if ([self drawsBackground]) {
			[[self backgroundColor] set];
			NSRectFill(imageFrame);
		}
		imageFrame.origin.x += 3;
		imageFrame.size = theImageSize;

        
		NSImageRep *bestRep = [image bestRepresentationForSize:theImageSize];
		[image setSize:[bestRep size]];
		CGFloat opacity = [self isEnabled] ? 1.0 : 0.5;

		[image drawInRect:imageFrame fromRect:rectFromSize([image size]) operation:NSCompositingOperationSourceOver fraction:opacity respectFlipped:[controlView isFlipped] hints:nil];

	}

	cellFrame = [self textRectForFrame:cellFrame];
	NSRect textCellFrame = cellFrame;

	textCellFrame.size.height = [super cellSizeForBounds:textCellFrame] .height;
	textCellFrame = centerRectInRect(textCellFrame, cellFrame);

	[self setTextColor:[self isHighlighted] && !editing?[NSColor alternateSelectedControlTextColor] :[NSColor selectedControlTextColor]];
	[super drawWithFrame:textCellFrame inView:controlView];

	[self setTextColor:[NSColor controlTextColor]];
}

// - (NSSize) cellSizeForBounds:(NSRect)bounds {
// 	bounds.size.width -= 1+[self imageWidthForFrame:bounds] *1.125;
// 	NSSize cellSize = [super cellSizeForBounds:bounds];
// 	cellSize.width += 1+[self imageWidthForFrame:bounds] *1.125;
// 	return cellSize;
// }

- (NSSize) cellSize {
	NSSize cellSize = [super cellSize];
	cellSize.width += 1+[self imageWidthForFrame:NSZeroRect] *1.125;
	return cellSize;
}

- (NSSize) imageSize { return imageSize;  }
- (void)setImageSize: (NSSize) newImageSize {
	imageSize = newImageSize;
}

@end
