//
// QSFancyTableView.m
// Quicksilver
//
// Created by Nicholas Jitkoff on 4/22/06.
// Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "QSFancyTableView.h"
#import "NSTableView_BLTRExtensions.h"

#import "QSShading.h"

@implementation QSFancyTableView

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
	[nc addObserver:self selector:@selector(_windowDidChangeKeyNotification:) name:NSWindowDidResignKeyNotification object:newWindow];
	[nc removeObserver:self name:NSWindowDidBecomeKeyNotification object:nil];
	[nc addObserver:self selector:@selector(_windowDidChangeKeyNotification:) name:NSWindowDidBecomeKeyNotification object:newWindow];
}


- (void)highlightSelectionInClipRect:(NSRect)rect {
	[self highlightSelectionInClipRect:rect withGradientColor:[self highlightColor]];
}

- (void)selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extend {
	[super selectRowIndexes:indexes byExtendingSelection:extend];
	[self setNeedsDisplay:YES]; // we display extra because we draw
                                // multiple contiguous selected rows differently, so changing
                                // one row's selection can change how others draw.
}

- (void)deselectRow:(NSInteger)row {
	[super deselectRow:row];
	[self setNeedsDisplay:YES];					   
}

- (id)_highlightColorForCell:(NSCell *)cell {
	return nil;
}

- (void)_windowDidChangeKeyNotification:(NSNotification *)notification {
	[self setNeedsDisplay:YES];
}

@end

@implementation QSFancyOutlineView

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
	[nc addObserver:self selector:@selector(_windowDidChangeKeyNotification:) name:NSWindowDidResignKeyNotification object:newWindow];
	[nc removeObserver:self name:NSWindowDidBecomeKeyNotification object:nil];
	[nc addObserver:self selector:@selector(_windowDidChangeKeyNotification:) name:NSWindowDidBecomeKeyNotification object:newWindow];
}

- (void)highlightSelectionInClipRect:(NSRect)rect {
	[self highlightSelectionInClipRect:rect withGradientColor:[self highlightColor]];
}

- (void)selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extend {
	[super selectRowIndexes:indexes byExtendingSelection:extend];
	[self setNeedsDisplay:YES]; // we display extra because we draw
                                // multiple contiguous selected rows differently, so changing
                                // one row's selection can change how others draw.
}

- (void)deselectRow:(NSInteger)row {
	[super deselectRow:row];
	[self setNeedsDisplay:YES];						   
}

- (id)_highlightColorForCell:(NSCell *)cell {
	return nil;
}

- (void)_windowDidChangeKeyNotification:(NSNotification *)notification {
	[self setNeedsDisplay:YES];
}

@end
