/*
 QSImageAndTextCell.m
 ALCHEMY
 */

#import "QSImageAndTextCell.h"
#import "NSGeometry_BLTRExtensions.h"
@implementation QSImageAndTextCell

- (void)dealloc {
  [image_ release];
  image_ = nil;
  [super dealloc];
}
- (id)copyWithZone:(NSZone *)zone {
  QSImageAndTextCell *cell = (QSImageAndTextCell *)[super copyWithZone:zone];
  cell->image_ = nil;
	[cell setImage:image_];
  return cell;
}

- (void)setImage:(NSImage *)anImage {
  if (anImage != image_) {
    [image_ release];
    image_ = [anImage retain];
  }
}

- (NSImage *)image {
  return image_;
}

- (NSRect) imageFrameForCellFrame:(NSRect)cellFrame {
  if (image_ != nil) {
    NSRect imageFrame;
    imageFrame.size = [image_ size];
    imageFrame.origin = cellFrame.origin;
    imageFrame.origin.x += 3;
    imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
    return imageFrame;
  }
  else
    return NSZeroRect;
}

- (NSString *)overrideForKey:(NSString *)key {
  NSString *override = [keys_ objectForKey:key];
  if (override) return override;
  return key;
}



- (void)setObjectValue:(id)object {
	
	if ([object isKindOfClass:[NSString class]] || [object isKindOfClass:[NSAttributedString class]]) {
		[super setObjectValue:object];
	} else {
    @try {
			id value;
			value=[object valueForKey:[self overrideForKey:@"text"]];
			[super setObjectValue:value?value:@""];
			value=[object valueForKey:[self overrideForKey:@"image"]];
			[self setImage:value];
    }
    @catch (NSException * e) {
      QSLog(@"Error %@", e);
      [super setObjectValue:@""];
    }
	}
}

- (float) imageWidthForFrame:(NSRect)frame {
	if (imageSize_.width) {
		return imageSize_.width;
	} else {
		return  NSHeight(frame);
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
- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength {
	NSRect textFrame = [self textRectForFrame:aRect];
  [super selectWithFrame: textFrame inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)drawImage:(NSImage*)image withFrame:(NSRect)frame inView:(NSView*)controlView {  
  if ([controlView isFlipped]){
    [image setFlipped:YES];
  }
  NSImageRep *bestRep=[image bestRepresentationForSize:imageSize_];
  [image setSize:[bestRep size]];
  //float opacity=[self isEnabled]?1.0:0.5;
  NSSize size = [image size];
  
  //NSLog(@"image, %@", NSStringFromRect(frame));
  [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
  [image drawInRect:frame 
           fromRect:NSMakeRect(0, 0, size.width, size.height)
          operation:NSCompositeSourceOver
           fraction:1.0];
  
  [image setFlipped:NO];
  
}


- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    if (image_ != nil) {
        NSSize	size = imageSize_;
        NSRect	imageFrame;
        
        if (NSEqualSizes(size,NSZeroSize)) {
            if (NSHeight(cellFrame) <= 18){
                size = NSMakeSize(16, 16);
            }else{
                size = NSMakeSize(NSHeight(cellFrame),NSHeight(cellFrame));
            }
        }
        
        
		NSRect rest;
        NSDivideRect(cellFrame, &imageFrame, &rest, 1+[self imageWidthForFrame:cellFrame] *1.125, NSMinXEdge);
        if ([self drawsBackground]) {
            [[self backgroundColor] set];
            NSRectFill(imageFrame);
        }
        imageFrame.origin.x += 3;
        imageFrame.size = size;
        
		[self drawImage:image_ withFrame:imageFrame inView:controlView];
    }
	
	cellFrame = [self textRectForFrame:cellFrame];
	NSRect textCellFrame = cellFrame;
  
	textCellFrame.size.height = [super cellSizeForBounds:textCellFrame] .height;
	textCellFrame = centerRectInRect(textCellFrame, cellFrame);
	

	[self setTextColor:[self isHighlighted] && !editing?[NSColor alternateSelectedControlTextColor] :[NSColor selectedControlTextColor]];
    [super drawWithFrame:cellFrame inView:controlView];
	
	[self setTextColor:[NSColor controlTextColor]];
}

// This caused the bug with huge table tooltips
//- (NSSize) cellSizeForBounds:(NSRect)bounds {
//	bounds.size.width -= 1+[self imageWidthForFrame:bounds] *1.125;
//	NSSize cellSize = [super cellSizeForBounds:bounds];  
//	cellSize.width += 1+[self imageWidthForFrame:bounds] *1.125;
//	return cellSize;
//}

- (NSSize)cellSize {
    NSSize cellSize = [super cellSize];
    cellSize.width += 1 + [self imageWidthForFrame:NSZeroRect] * 1.125;
    return cellSize;
}

- (NSSize) imageSize { return imageSize_;  }
- (void) setImageSize: (NSSize) newImageSize
{
  imageSize_ = newImageSize;
}

- (NSDictionary *) keys {
  return [[keys_ retain] autorelease];
}

- (void)setKeys:(NSDictionary *)value {
  if (keys_ != value) {
    [keys_ release];
    keys_ = [value copy];
  }
}

@end
