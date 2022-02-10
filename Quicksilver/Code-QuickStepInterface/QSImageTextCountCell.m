//
// QSImageTextCountCell.m
// Quicksilver
//
// Created by Nicholas Jitkoff on 4/27/06.
// Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "QSImageTextCountCell.h"
#import "NSGeometry_BLTRExtensions.h"
#import "NSBezierPath_BLTRExtensions.h"
#define countBadgeTextAttributes [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica-Bold" size:9.0] , NSFontAttributeName, [NSColor whiteColor] , NSForegroundColorAttributeName, nil]

@implementation QSImageTextCountCell

- (id)initTextCell:(NSString *)aString {
	self = [super initTextCell:aString];
	if (self != nil) {
		count = nil;
		NSLog(@"init");
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone {
	QSImageTextCountCell *cell = (QSImageTextCountCell *)[super copyWithZone:zone];
	cell->count = nil;
	[cell setCount:count];
	return cell;
}

- (NSString *)count { return count;  }
- (void)setCount: (NSString *)newCount {
	if (count != newCount) {
		count = [newCount copy];
	}
}



- (CGFloat) countWidthForFrame/*:(NSRect)frame*/ {
	if (![count length]) return 0;
	NSSize textSize = [count sizeWithAttributes:countBadgeTextAttributes];
	textSize.width += textSize.height;
	return textSize.width;
}

- (void)setObjectValue:(id)object {
	if (object && ![object isKindOfClass:[NSString class]]) {
		id newCount = [object valueForKey:@"count"];
		if ([newCount isKindOfClass:[NSNumber class]])
			newCount = [newCount stringValue];
		[self setCount:newCount];
	}
	[super setObjectValue:object];
}

- (NSRect) textRectForFrame:(NSRect)frame {
	frame = [super textRectForFrame:frame];
	if (!count) return frame;
	NSRect textFrame, countFrame;
	CGFloat width = [self countWidthForFrame/*:textFrame*/];
		if (width) width += 3;
	NSDivideRect (frame, &countFrame, &textFrame, width, NSMaxXEdge);
	return textFrame;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	[super drawWithFrame:cellFrame inView:controlView];
	if (count) {
		NSRect rect = [super textRectForFrame:cellFrame];
		CGFloat width = [self countWidthForFrame/*:rect*/];
		rect.origin.x += NSWidth(rect) -width;
		rect.size.width = width;

		BOOL highlighted = [self isHighlighted];

		NSRect textRect = rect; //NSInsetRect(rect, NSHeight(rect) /4, NSHeight(rect)/4);
		textRect = NSInsetRect(textRect, 0, NSHeight(rect) /2-6);

		NSBezierPath *path = [NSBezierPath bezierPath];
		[path appendBezierPathWithRoundedRectangle:textRect withRadius:NSHeight(textRect) /2];
		NSDictionary *numAttributes = countBadgeTextAttributes;

		NSRect glyphRect = rectFromSize([count sizeWithAttributes:numAttributes]);
		NSRect countTextRect = centerRectInRect(glyphRect, rect);

		countTextRect.origin.x += 0.1;
		countTextRect.origin.y += (-[[numAttributes objectForKey:NSFontAttributeName] descender] /2-2);

		if (highlighted) {
			[[NSColor colorWithCalibratedWhite:1.0 alpha:0.4] set];
		} else {
			[[NSColor colorWithCalibratedWhite:0.0 alpha:0.3] set];
		}
		[path fill];
		[count drawInRect:countTextRect withAttributes:numAttributes];
	}
}

@end
