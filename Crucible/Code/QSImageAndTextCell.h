//
//  QSImageAndTextCell.h
//

//

#import <Cocoa/Cocoa.h>

@interface QSImageAndTextCell : NSTextFieldCell {
	BOOL editing;
  NSImage	*image_;
	NSSize imageSize_;
  NSDictionary *keys_;
}

- (void)setImage:(NSImage *)anImage;
- (NSImage *)image;
- (float)imageWidthForFrame:(NSRect)frame;
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (NSSize)cellSize;
- (NSRect)textRectForFrame:(NSRect)frame;
- (NSSize) imageSize;
- (void) setImageSize: (NSSize) newImageSize;
- (NSDictionary *)keys;
- (void)setKeys:(NSDictionary *)value;
- (NSString *)overrideForKey:(NSString *)key;
@end