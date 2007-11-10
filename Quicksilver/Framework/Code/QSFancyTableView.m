//
//  QSFancyTableView.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 4/22/06.

//

#import "QSFancyTableView.h"
#import "NSTableView_BLTRExtensions.h"

#import "QSShading.h"


@implementation QSFancyTableView

// NSObject

- (void)dealloc;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


// NSView

- (void)viewWillMoveToWindow:(NSWindow *)newWindow;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSWindowDidResignKeyNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(_windowDidChangeKeyNotification:)
												 name:NSWindowDidResignKeyNotification object:newWindow];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSWindowDidBecomeKeyNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(_windowDidChangeKeyNotification:)
												 name:NSWindowDidBecomeKeyNotification object:newWindow];
}




- (void)drawBackgroundInClipRect:(NSRect)clipRect{
	
	NSColor *backgroundColor = [self backgroundColor];
	float hue, saturation, brightness, alpha;
	[[backgroundColor
      colorUsingColorSpaceName:NSDeviceRGBColorSpace] getHue:&hue
												  saturation:&saturation brightness:&brightness alpha:&alpha];
	
	// Create synthetic darker and lighter versions
	NSColor *lighterColor = [NSColor colorWithDeviceHue:hue
											 saturation:MAX(0.0, saturation*.88) brightness:MIN(1.0,
																								brightness*1.15) alpha:alpha];
	
	//	NSColor *lighterColor=[backgroundColor colorWithLighting:1.0 plasticity:0
	//.0];
	
//	NSColor *darkerColor = [NSColor colorWithDeviceHue:hue
//											saturation:MIN(1.0, (saturation > .04) ? saturation*1.12 :
//														   0.0) brightness:MAX(0.0, brightness*0.9) alpha:alpha];
	QSFillRectWithGradientFromEdge([self frame],lighterColor,backgroundColor,NSMinYEdge);
	
}



- (void)highlightSelectionInClipRect:(NSRect)rect{
	[self highlightSelectionInClipRect:rect withGradientColor:[self highlightColor]];
}

- (void)selectRow:(int)row byExtendingSelection:(BOOL)extend;
{
	[super selectRow:row byExtendingSelection:extend];
	[self setNeedsDisplay:YES]; // we display extra because we draw
								//multiple contiguous selected rows differently, so changing
								//	one row's selection can change how others draw.
}

- (void)deselectRow:(int)row;
{
	[super deselectRow:row];
	[self setNeedsDisplay:YES]; // we display extra because we draw
								//multiple contiguous selected rows differently, so changing
								//	one row's selection can change how others draw.
}


// NSTableView (Private)

- (id)_highlightColorForCell:(NSCell *)cell;
{
	return nil;
}

- (void)_windowDidChangeKeyNotification:(NSNotification
										 *)notification;
{
	[self setNeedsDisplay:YES];
}

@end






@implementation QSFancyOutlineView

// NSObject

- (void)dealloc;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


// NSView

- (void)viewWillMoveToWindow:(NSWindow *)newWindow;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSWindowDidResignKeyNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(_windowDidChangeKeyNotification:)
												 name:NSWindowDidResignKeyNotification object:newWindow];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSWindowDidBecomeKeyNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(_windowDidChangeKeyNotification:)
												 name:NSWindowDidBecomeKeyNotification object:newWindow];
}



- (void)drawBackgroundInClipRect:(NSRect)clipRect{
	
	NSColor *backgroundColor = [self backgroundColor];
	float hue, saturation, brightness, alpha;
	[[backgroundColor
      colorUsingColorSpaceName:NSDeviceRGBColorSpace] getHue:&hue
												  saturation:&saturation brightness:&brightness alpha:&alpha];
	
	// Create synthetic darker and lighter versions
	NSColor *lighterColor = [NSColor colorWithDeviceHue:hue
											 saturation:MAX(0.0, saturation*.88) brightness:MIN(1.0,
																								brightness*1.15) alpha:alpha];

//	NSColor *lighterColor=[backgroundColor colorWithLighting:1.0 plasticity:0
//.0];
	
//	NSColor *darkerColor = [NSColor colorWithDeviceHue:hue
//											saturation:MIN(1.0, (saturation > .04) ? saturation*1.12 :
//														   0.0) brightness:MAX(0.0, brightness*0.9) alpha:alpha];
	QSFillRectWithGradientFromEdge([self frame],lighterColor,backgroundColor,NSMinYEdge);
	
}


- (void)highlightSelectionInClipRect:(NSRect)rect{
	[self highlightSelectionInClipRect:rect withGradientColor:[self highlightColor]];
}

- (void)selectRow:(int)row byExtendingSelection:(BOOL)extend;
{
	[super selectRow:row byExtendingSelection:extend];
	[self setNeedsDisplay:YES]; // we display extra because we draw
								//multiple contiguous selected rows differently, so changing
								//	one row's selection can change how others draw.
}

- (void)deselectRow:(int)row;
{
	[super deselectRow:row];
	[self setNeedsDisplay:YES]; // we display extra because we draw
								//multiple contiguous selected rows differently, so changing
								//	one row's selection can change how others draw.
}


// NSTableView (Private)

- (id)_highlightColorForCell:(NSCell *)cell;
{
	return nil;
}

- (void)_windowDidChangeKeyNotification:(NSNotification
										 *)notification;
{
	[self setNeedsDisplay:YES];
}

@end
