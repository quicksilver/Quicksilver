//
// NSCursor_InformExtensions.m
// Quicksilver
//
// Created by Alcor on Thu May 06 2004.
// Copyright (c) 2004 Blacktree. All rights reserved.
//

#import "NSCursor_InformExtensions.h"
#import "NSBezierPath_BLTRExtensions.h"

#define informAttributes [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:9] , NSFontAttributeName, [NSColor darkGrayColor] , NSForegroundColorAttributeName, [NSNumber numberWithDouble:1] , NSBaselineOffsetAttributeName, nil]


@implementation NSCursor (InformExtensions)
+(NSCursor *) informativeCursorWithString:(NSString *)string {
	if (![string length]) return [self arrowCursor];
	NSSize size = [string sizeWithAttributes:informAttributes];
	NSImage *arrowImage = [[self arrowCursor] image];
	NSPoint padding = NSMakePoint(size.height/2, 1);
	NSRect textRect = NSOffsetRect(NSMakeRect(16, 1, size.width, size.height), padding.x, padding.y);
	NSRect blobRect = NSInsetRect(textRect, -padding.x, -padding.y);
	NSSize arrowSize = [arrowImage size];
	NSRect imageRect = NSUnionRect(NSInsetRect(blobRect, -1, -1), NSMakeRect(0, 0, arrowSize.width, arrowSize.height));

	NSImage *cImg = [[NSImage alloc] initWithSize:imageRect.size];
	NSBezierPath *roundRect = [NSBezierPath bezierPath];
	[roundRect appendBezierPathWithRoundedRectangle:blobRect withRadius:size.height/2 indent:NO];

	[cImg lockFocus];
	[arrowImage drawAtPoint:NSZeroPoint fromRect:imageRect operation:NSCompositingOperationSourceOver fraction:1.0];
	[[NSColor colorWithCalibratedWhite:1.0 alpha:0.7] setFill];
	[[NSColor colorWithCalibratedWhite:0.5 alpha:0.3] setStroke];
	[roundRect fill];
	[roundRect stroke];

	[string drawInRect:textRect withAttributes:informAttributes];
	[cImg unlockFocus];
	NSCursor *result = [[NSCursor alloc] initWithImage:cImg hotSpot:NSZeroPoint];
	return result;
}
@end
