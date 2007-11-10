//
//  QSBadgeImage.m
//  Quicksilver
//
//  Created by Alcor on 9/11/04.

//

#import "QSBadgeImage.h"

#import "QSResourceManager.h"
#import "NSGeometry_BLTRExtensions.h"

#define countBadgeTextAttributes [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica Bold" size:24], NSFontAttributeName,[NSColor whiteColor],NSForegroundColorAttributeName,nil]

@implementation QSCountBadgeImage
- (void)setCount:(int)newCount{
	count=newCount;
}


+ (QSCountBadgeImage *)badgeForCount:(int)num{
	if (num<=0) return nil;
	NSImage *badgeImage=nil;
	NSString *numString=[NSString stringWithFormat:@"%d",num];
	if ([numString length]<3)
		badgeImage=[QSResourceManager imageNamed:@"countBadge1&2"];
	else if ([numString length]<4)
		badgeImage=[QSResourceManager imageNamed:@"countBadge3"];
	else if ([numString length]<5)
		badgeImage=[QSResourceManager imageNamed:@"countBadge4"];
	else
		badgeImage=[QSResourceManager imageNamed:@"countBadge5"];
	
	if (!badgeImage)return nil;
	//return badgeImage;

	QSCountBadgeImage *image=[[[self alloc]init]autorelease];
	[image setCount:num];
	[image addRepresentations:[badgeImage representations]];
	return image;
}

- (void)drawBadgeForIconRect:(NSRect)rect{
	NSRect countImageRect=rectFromSize([self size]);
	[self drawInRect:alignRectInRect(countImageRect,rect,3) fromRect:countImageRect operation:NSCompositeSourceOver fraction:1.0];
}



- (void)drawInRect:(NSRect)rect fromRect:(NSRect)fromRect operation:(NSCompositingOperation)op fraction:(float)delta{
	[super drawInRect:rect fromRect:rectFromSize([self size]) operation:op fraction:delta];
	
	NSString *numString=[NSString stringWithFormat:@"%d",count];
	NSRect textRect=NSInsetRect(rect,NSHeight(rect)/4,NSHeight(rect)/4);
	NSDictionary *numAttributes=[numString attributesToFitNumbersInRect:textRect withAttributes:countBadgeTextAttributes];
	//QSLog(@"font metric: %f %f %f %f",[[numAttributes objectForKey:NSFontAttributeName]ascender],
	//	  [[numAttributes objectForKey:NSFontAttributeName]descender],
	//	  [[numAttributes objectForKey:NSFontAttributeName]capHeight],
	//	  [[numAttributes objectForKey:NSFontAttributeName]defaultLineHeightForFont]);

	
	NSRect glyphRect=rectFromSize([numString sizeWithAttributes:numAttributes]);
	NSRect countTextRect=centerRectInRect(glyphRect,rect);
	
	//[[NSColor greenColor]set];
	//NSFrameRect(countTextRect);
	countTextRect.origin.y+=(-[[numAttributes objectForKey:NSFontAttributeName]descender])/4;
	
	//NSFrameRect(countTextRect);
	
	[numString drawInRect:countTextRect withAttributes:numAttributes];
	
}



@end
