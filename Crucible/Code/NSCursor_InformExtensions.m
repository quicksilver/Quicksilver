//
//  NSCursor_InformExtensions.m
//  Quicksilver
//
//  Created by Alcor on Thu May 06 2004.

//

#import "NSCursor_InformExtensions.h"

#import "NSBezierPath_BLTRExtensions.h"

#define informAttributes [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:9], NSFontAttributeName,[NSColor darkGrayColor],NSForegroundColorAttributeName,[NSNumber numberWithFloat:1],NSBaselineOffsetAttributeName,nil]


@implementation NSCursor (InformExtensions)
+ informativeCursorWithString:(NSString *)string{
	
	if (![string length])return [self arrowCursor];
	NSSize size=[string sizeWithAttributes:informAttributes];
	NSImage *arrowImage=[[self arrowCursor]image];
	NSSize arrowSize=[arrowImage size];
	NSRect textRect=NSMakeRect(16,1,size.width,size.height);
	NSPoint padding=NSMakePoint(size.height/2,1);
	textRect=NSOffsetRect(textRect,padding.x,padding.y);
	NSRect blobRect=NSInsetRect(textRect,-padding.x,-padding.y);
	NSRect cursorRect=NSMakeRect(0,0,arrowSize.width,arrowSize.height);
	NSRect imageRect=NSUnionRect(NSInsetRect(blobRect,-1,-1),cursorRect);
	
	//imageRect=NSInsetRect(imageRect,0,NSHeight(imageRect)/2);
	
	NSImage * cImg=[[NSImage alloc]initWithSize:imageRect.size];
	NSBezierPath *roundRect=[NSBezierPath bezierPath];
	[roundRect appendBezierPathWithRoundedRectangle:blobRect withRadius:size.height/2 indent:NO];
	
	[cImg lockFocus];
	[arrowImage compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
	[[NSColor colorWithCalibratedWhite:1.0 alpha:0.7]setFill];
	[[NSColor colorWithCalibratedWhite:0.5 alpha:0.3]setStroke];
	[roundRect fill];  
	[roundRect stroke];
	
	[string drawInRect:textRect withAttributes:informAttributes];
	[cImg unlockFocus];
	return [[[NSCursor alloc]initWithImage:cImg hotSpot:NSZeroPoint]autorelease];
}
@end
/*
+ informativeCursorWithString:(NSString *)string{
	NSSize size=[string sizeWithAttributes:informAttributes];
	NSImage *arrowImage=[[self arrowCursor]image];
	NSRect imageRect=NSMakeRect(0,0,size.width,size.height);
	imageRect=NSInsetRect(imageRect,0,NSHeight(imageRect)/2);
	
	NSImage * cImg=[[NSImage alloc]initWithSize:imageRect.size];
	NSBezierPath *roundRect=[NSBezierPath bezierPath];
	[roundRect appendBezierPathWithRoundedRectangle:NSInsetRect(imageRect,1,1) withRadius:size.height/2 indent:NO];
	
	[cImg lockFocus];
	[arrowImage compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
	[[NSColor colorWithCalibratedWhite:1.0 alpha:0.8]setFill];
	[[NSColor colorWithCalibratedWhite:0.5 alpha:0.8]setStroke];
	[roundRect fill];  
	[roundRect stroke];
	
	[string drawAtPoint:NSMakePoint(1,1) withAttributes:informAttributes];
	[cImg unlockFocus];
	return [[[NSCursor alloc]initWithImage:cImg hotSpot:NSZeroPoint]autorelease];
}
*/
