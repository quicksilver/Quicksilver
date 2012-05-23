//
//  QSImageAndTextCell.h
//
//  Copyright (c) 2001 Apple. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QSImageAndTextCell : NSTextFieldCell {
	BOOL editing;
	@private
	NSImage	*image;
	NSSize imageSize;
}

- (void)setImage:(NSImage *)anImage;
- (NSImage *)image;
- (CGFloat) imageWidthForFrame:(NSRect)frame;
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (NSSize) cellSize;
- (NSRect) textRectForFrame:(NSRect)frame;
- (NSSize) imageSize;
- (void)setImageSize: (NSSize) newImageSize;

@end
