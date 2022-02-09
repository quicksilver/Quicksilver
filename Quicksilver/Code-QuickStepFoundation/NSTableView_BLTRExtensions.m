//
// NSArray_Extensions.m
// Quicksilver
//
// Created by Alcor on Fri Apr 04 2003.
// Copyright (c) 2003 Blacktree, Inc. All rights reserved.
//

#import "NSTableView_BLTRExtensions.h"
#import "NSIndexSet+Extensions.h"

#define QSTableRowsType @"QSTableRowsType"

// CoreGraphics gradient helpers

typedef struct {
	CGFloat red1, green1, blue1, alpha1;
	CGFloat red2, green2, blue2, alpha2;
} _twoColorsType;

void _linearColorBlendFunction(void *info, const CGFloat *in, CGFloat *out) {
	_twoColorsType *twoColors = info;
	out[0] = (1.0 - *in) * twoColors->red1 + *in * twoColors->red2;
	out[1] = (1.0 - *in) * twoColors->green1 + *in * twoColors->green2;
	out[2] = (1.0 - *in) * twoColors->blue1 + *in * twoColors->blue2;
	out[3] = (1.0 - *in) * twoColors->alpha1 + *in * twoColors->alpha2;
}

void _linearColorReleaseInfoFunction(void *info) { free(info); }

static const CGFunctionCallbacks linearFunctionCallbacks = {0, &_linearColorBlendFunction, &_linearColorReleaseInfoFunction};

@implementation NSTableView (Fancification)

- (void)highlightSelectionInClipRect:(NSRect)rect withGradientColor:(NSColor *)color {
	// Take the color apart
	if (!color) color = [NSColor alternateSelectedControlColor];
	CGFloat hue, saturation, brightness, alpha;
	[[color colorUsingColorSpace:NSColorSpace.deviceRGBColorSpace] getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];

	// Create synthetic darker and lighter versions
	NSColor *lighterColor = [NSColor colorWithDeviceHue:hue saturation:MAX(0.0, saturation-.12) brightness:MIN(1.0, brightness+0.30) alpha:alpha];
	NSColor *darkerColor = [NSColor colorWithDeviceHue:hue saturation:MIN(1.0, (saturation > .04) ? saturation+0.12 : 0.0) brightness:MAX(0.0, brightness-0.045) alpha:alpha];

	// If this view isn't key, use the gray version of the dark color.
	//Note that this varies from the standard gray version that NSCell
	//		returns as its highlightColorWithFrame: when the cell is not in a
	//		key view, in that this is a lot darker. Mike and I think this is
	//		justified for this kind of view -- if you're using the dark
	//			selection color to show the selected status, it makes sense to
	//			leave it dark.

//	NSResponder *firstResponder = [[self window] firstResponder];
	//	if (![firstResponder isKindOfClass:[NSView class]] ||
	//		![(NSView *)firstResponder isDescendantOf:self] ||
	if (![[self window] isKeyWindow]) {
		color = [[color colorUsingColorSpaceName:NSDeviceWhiteColorSpace] colorUsingColorSpace:NSColorSpace.deviceRGBColorSpace];
		lighterColor = [[lighterColor colorUsingColorSpaceName:NSDeviceWhiteColorSpace] colorUsingColorSpace:NSColorSpace.deviceRGBColorSpace];
		darkerColor = [[darkerColor colorUsingColorSpaceName:NSDeviceWhiteColorSpace] colorUsingColorSpace:NSColorSpace.deviceRGBColorSpace];
	}

	// Set up the helper function for drawing washes
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	_twoColorsType *twoColors = malloc(sizeof(_twoColorsType) );
/* We malloc() the helper data because we may draw this wash during printing, in which case it won't necessarily be evaluated immediately. We need for all the data the shading function needs to draw to potentially outlive us.*/
	[lighterColor getRed:&twoColors->red1 green:&twoColors->green1 blue:&twoColors->blue1 alpha:&twoColors->alpha1];
	[darkerColor getRed:&twoColors->red2 green:&twoColors->green2 blue:&twoColors->blue2 alpha:&twoColors->alpha2];
	static const CGFloat domainAndRange[8] = {0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0};
	CGFunctionRef linearBlendFunctionRef = CGFunctionCreate(twoColors, 1, domainAndRange, 4, domainAndRange, &linearFunctionCallbacks);

	NSIndexSet *selectedRowIndexes = [self selectedRowIndexes];
	NSUInteger rowIndex = [selectedRowIndexes indexGreaterThanOrEqualToIndex:0];

	while (rowIndex != NSNotFound) {
		NSUInteger endOfCurrentRunRowIndex, newRowIndex = rowIndex;
		do {
			endOfCurrentRunRowIndex = newRowIndex;
			newRowIndex = [selectedRowIndexes indexGreaterThanIndex:endOfCurrentRunRowIndex];
		} while (newRowIndex == endOfCurrentRunRowIndex + 1);

		NSRect rowRect = NSUnionRect([self rectOfRow:rowIndex], [self rectOfRow:endOfCurrentRunRowIndex]);

		NSRect topBar, washRect;
		NSDivideRect(rowRect, &topBar, &washRect, 1.0, NSMinYEdge);

		// Draw the top line of pixels of the selected row in the
		//alternateSelectedControlColor
		[color set];
		NSRectFill(topBar);

		// Draw a soft wash underneath it
		CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
		CGContextSaveGState(context); {
			CGContextClipToRect(context, (CGRect) {{NSMinX(washRect),NSMinY(washRect)},{NSWidth(washRect),NSHeight(washRect)}});
			CGShadingRef cgShading = CGShadingCreateAxial(colorSpace, CGPointMake(0, NSMinY(washRect) ), CGPointMake(0, NSMaxY(washRect) ), linearBlendFunctionRef, NO, NO);
			CGContextDrawShading(context, cgShading);
			CGShadingRelease(cgShading);
		} CGContextRestoreGState(context);
		rowIndex = newRowIndex;
	}
	CGFunctionRelease(linearBlendFunctionRef);
	CGColorSpaceRelease(colorSpace);
}

@end


@implementation NSTableView (Separator)
- (void)drawSeparatorForRow:(NSInteger)rowIndex clipRect:(NSRect)clipRect {
	clipRect = [self rectOfRow:rowIndex];
	clipRect.origin.y += NSHeight(clipRect) / 2;
	clipRect.size.height = 1.0;
	[[NSColor grayColor] set];
	NSRectFill(clipRect);
}

- (BOOL)writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard {
	[pboard declareTypes:[NSArray arrayWithObject:QSTableRowsType] owner:self];
	[pboard setPropertyList:rows forType:QSTableRowsType];
	return YES;
}

- (NSIndexSet *)rowsFromDrag:(id <NSDraggingInfo>)info {
	return [NSIndexSet indexSetFromArray:[[info draggingPasteboard] propertyListForType:QSTableRowsType]];
}

@end
