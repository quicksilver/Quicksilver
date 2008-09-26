//
// QSImageView.m
// Quicksilver
//
// Created by Alcor on 2/13/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "QSImageView.h"
#import "NSImage_BLTRExtensions.h"

@implementation QSImageCell

- (id)initImageCell:(NSImage *)image {
	self = [super initImageCell:image];
	if (self != nil) {
		adjustResolution = YES;
	}
	return self;
}

- (void)awakeFromNib {
	adjustResolution = YES;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	NSImage *image = [self image];
	[image setFlipped:NO];
	if (adjustResolution) {
		[image setSize:[[image bestRepresentationForSize:cellFrame.size] size]];
	}
	[super drawWithFrame:cellFrame inView:controlView];
}

@end

@implementation QSImageView
- (void)setUpGState {
	[super setUpGState];
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	[[self image] setSize:[[[self image] bestRepresentationForSize:[self frame].size] size]];
}
@end
