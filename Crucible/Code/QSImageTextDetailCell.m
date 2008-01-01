//
//  QSImageTextDetailCell.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 4/27/06.

//

#import "QSImageTextDetailCell.h"
#import "NSGeometry_BLTRExtensions.h"
#import "NSBezierPath_BLTRExtensions.h"
#define detailTextAttributes [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica-Bold" size:9.0] , NSFontAttributeName, [NSColor whiteColor] , NSForegroundColorAttributeName, nil]

@implementation QSImageTextDetailCell
@synthesize details;

- (id)initTextCell:(NSString *)aString {
	self = [super initTextCell:aString];
	if (self != nil) {
		details = nil;
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone {
  QSImageTextDetailCell *cell = (QSImageTextDetailCell *)[super copyWithZone:zone];
  cell->details = nil;
	cell.details = details;
  return cell;
}


- (void)dealloc {
  self.details = nil;
  [super dealloc];
}


- (float) detailWidthForFrame:(NSRect)frame {
	if (![details length]) return 0;
	NSSize textSize = [details sizeWithAttributes:detailTextAttributes];
	textSize.width += textSize.height;
	return textSize.width;
}

- (void)setObjectValue:(id)object {
	[super setObjectValue:object];
  
	if (object && ![object isKindOfClass:[NSString class]]) {
		id newdetail = [object valueForKey:[self overrideForKey:@"details"]];
		if ([newdetail isKindOfClass:[NSNumber class]])
			newdetail = [newdetail stringValue];
		self.details = newdetail;/// = @"test";
	}
}


- (NSAttributedString *)detailsAttributedString {
  if (![details length]) return nil;
  NSFont *font = [self font];
  font = [NSFont fontWithName:[font fontName] size:[font pointSize] * 0.9];
  return [[[NSAttributedString alloc] initWithString:details attributes:[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil]] autorelease];                                                                        
}


- (NSRect) textRectForFrame:(NSRect)frame detailsRect:(NSRect *)dRect {
  frame = [super textRectForFrame:frame];
  
  
  NSSize textSize = [[self attributedStringValue] size];
  NSSize detailsSize = [[self detailsAttributedString] size];
  
  float idealHeight = textSize.height;
  
  BOOL showDetails = NSHeight(frame) >= detailsSize.height + textSize.height;
  if (showDetails) idealHeight += detailsSize.height;
  
  frame.origin.y += (NSHeight(frame) - idealHeight)/2;
  frame.size.height = idealHeight;

  NSRect detailsRect = NSZeroRect;
  NSDivideRect(frame, &frame, &detailsRect, textSize.height, NSMinYEdge);
  
//  if (showDetails) {
//    detailsRect = NSOffsetRect(frame, 0, textSize.height);  
//  }
//  NSLog(@"size %f %f", textSize.height, NSHeight(frame));
//  NSLog(@"dize %f %d", detailsSize.height, showDetails);

  
  if (dRect) *dRect = detailsRect;
  return frame;
}


- (NSRect) textRectForFrame:(NSRect)frame {
  return [self textRectForFrame:frame detailsRect:NULL];
}


//- (NSAttributedString *)attributedStringValue {
//  NSMutableAttributedString *string = [[[super attributedStringValue] mutableCopy] autorelease];
//  NSLog(@"deets %@", details);
//  
//  if ([details length]) {
//    NSAttributedString *detailsString = [[[NSAttributedString alloc] initWithString:details] autorelease];
////    [string appendAttributedString: [[[NSAttributedString alloc] initWithString:@"\n"] autorelease]];
//    [string appendAttributedString:detailsString];
//  }
//  return string; 
//}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  [super drawWithFrame:cellFrame inView:controlView];
  NSRect detailsRect = NSZeroRect;
  [self textRectForFrame:cellFrame detailsRect:&detailsRect];
  if (!NSEqualRects(detailsRect, NSZeroRect)) {
    [[NSGraphicsContext currentContext] saveGraphicsState];
    CGContextRef context = (CGContextRef)([[NSGraphicsContext currentContext] graphicsPort]);
    CGContextSetAlpha(context, 0.5);
    CGContextBeginTransparencyLayer(context, 0);
    [[self detailsAttributedString] drawInRect:detailsRect];
    CGContextEndTransparencyLayer(context); 
    
    [[NSGraphicsContext currentContext] restoreGraphicsState];
  }
}
//- (NSRect) textRectForFrame:(NSRect)frame {
//	frame = [super textRectForFrame:frame];
//	if (!details) return frame;
//	NSRect textFrame, detailFrame;
//	float width = [self detailWidthForFrame:textFrame];
//  if (width) width += 3;
//  NSDivideRect (frame, &detailFrame, &textFrame, width, NSMaxXEdge);
//  
//	return textFrame;
//}


//- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
//	[super drawWithFrame:cellFrame inView:controlView];
//	if (details) {
//		NSRect rect = [super textRectForFrame:cellFrame];
//		float width = [self detailWidthForFrame:rect];
//		rect.origin.x += NSWidth(rect) -width;
//		rect.size.width = width;
//		
//		BOOL highlighted = [self isHighlighted];
//		
//		NSRect textRect = rect; //NSInsetRect(rect, NSHeight(rect) /4, NSHeight(rect)/4);
//		textRect = NSInsetRect(textRect, 0, NSHeight(rect) /2-6);
//		
//		NSBezierPath *path = [NSBezierPath bezierPath];
//		[path appendBezierPathWithRoundedRectangle:textRect withRadius:NSHeight(textRect) /2];
//		NSDictionary *numAttributes = detailTextAttributes;
//		
//		NSRect glyphRect = rectFromSize([details sizeWithAttributes:numAttributes]);
//		NSRect detailTextRect = centerRectInRect(glyphRect, rect);
//		
//		detailTextRect.origin.x += 0.1;
//		detailTextRect.origin.y += (-[[numAttributes objectForKey:NSFontAttributeName] descender] /2);
//		
//		//NSFrameRect(detailTextRect);
//		if (!highlighted) {
//			[[NSColor colorWithCalibratedWhite:0.0 alpha:0.3] set];
//		} else {
//			[[NSColor colorWithCalibratedWhite:1.0 alpha:0.4] set];
//			
//		}
//		[path fill];
//		//[[NSColor greenColor] set];
//		//NSFrameRect(detailTextRect);
//		
//		[details drawInRect:detailTextRect withAttributes:numAttributes];
//	} 	
//}



@end
