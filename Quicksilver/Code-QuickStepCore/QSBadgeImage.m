//
// QSBadgeImage.m
// Quicksilver
//
// Created by Alcor on 9/11/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "QSBadgeImage.h"
#import "QSResourceManager.h"
#import <QSFoundation/QSFoundation.h>

#define countBadgeTextAttributes [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica Bold" size:24] , NSFontAttributeName, [NSColor whiteColor] , NSForegroundColorAttributeName, nil]

@implementation QSCountBadgeImage
- (void)setCount:(NSInteger)newCount { count = newCount; }

+ (QSCountBadgeImage *)badgeForCount:(NSInteger)num {
	if (num <= 0) return nil;
	NSImage *badgeImage;
	NSString *numString = [NSString stringWithFormat:@"%ld", (long)num];
	if ([numString length] < 3)
		badgeImage = [QSResourceManager imageNamed:@"countBadge1&2"];
	else if ([numString length] < 4)
		badgeImage = [QSResourceManager imageNamed:@"countBadge3"];
	else if ([numString length] < 5)
		badgeImage = [QSResourceManager imageNamed:@"countBadge4"];
	else
		badgeImage = [QSResourceManager imageNamed:@"countBadge5"];

	if (!badgeImage) return nil;

	QSCountBadgeImage *image = [[self alloc] init];
	[image setCount:num];
	[image addRepresentations:[badgeImage representations]];
	return image;
}

- (void)drawBadgeForIconRect:(NSRect)rect {
	NSRect countImageRect = rectFromSize([self size]);
	[self drawInRect:alignRectInRect(countImageRect, rect, 3) fromRect:countImageRect operation:NSCompositingOperationSourceOver fraction:1.0];
}

- (void)drawInRect:(NSRect)rect fromRect:(NSRect)fromRect operation:(NSCompositingOperation)op fraction:(CGFloat)delta respectFlipped:(BOOL)respectContextIsFlipped hints:(NSDictionary *)hints {
    
	[super drawInRect:rect fromRect:rectFromSize([self size]) operation:op fraction:delta respectFlipped:respectContextIsFlipped hints:hints];

	NSString *numString = [NSString stringWithFormat:@"%ld", (long)count];
	NSRect textRect = NSInsetRect(rect, NSHeight(rect) /3.5, NSHeight(rect)/4);
	NSDictionary *numAttributes = [numString attributesToFitNumbersInRect:textRect withAttributes:countBadgeTextAttributes];

	NSRect glyphRect = rectFromSize([numString sizeWithAttributes:numAttributes]);
	NSRect countTextRect = centerRectInRect(glyphRect, rect);

	countTextRect.origin.y += (-[[numAttributes objectForKey:NSFontAttributeName] descender]) /4;

	[numString drawInRect:countTextRect withAttributes:numAttributes];
}

@end
