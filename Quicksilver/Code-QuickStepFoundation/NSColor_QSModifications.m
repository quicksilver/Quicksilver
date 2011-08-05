//
// NSColor_QSModifications.m
// Quicksilver
//
// Created by Alcor on Fri Mar 19 2004.
// Copyright (c) 2004 Blacktree, Inc.. All rights reserved.
//

#import "NSColor_QSModifications.h"

@implementation NSColor (Contrast)

- (NSColor *)colorWithLighting:(float)light { return [self colorWithLighting:light plasticity:0]; }

- (NSColor *)colorWithLighting:(float)light plasticity:(float)plastic {
	if (plastic > 1) plastic = 1.0;
	if (plastic < 0) plastic = 0.0;
	NSColor *color = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	CGFloat h, s, b, a;

	[color getHue:&h saturation:&s brightness:&b alpha:&a];

	b += light; //*(1-plastic);

//	float overflow = MAX(b-1.0, 0);

//	s = s-overflow*plastic;
	//NSLog(@"%f %f %f", brightness, saturation, overflow);
	color = [NSColor colorWithCalibratedHue:h saturation:s brightness:b alpha:a];

	if (plastic) {
		color = [color blendedColorWithFraction:plastic*light ofColor:[NSColor colorWithCalibratedWhite:1.0 alpha:[color alphaComponent]]];
	}
	return color;
}

- (NSColor *)readableTextColor {
	return ([[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace] brightnessComponent] > 0.5) ? [NSColor blackColor] : [NSColor whiteColor];
}

#if 0
static NSColor *accentColor = nil;
+ (NSColor *)accentColor {
//	if (!accentColor) {
//
//	}
	return accentColor;
}
+ (void)setAccentColor:(NSColor *)color {
	[accentColor release];
	accentColor = [color retain];
}
#endif

@end
