//
// QSTrackingwindow.m
// Quicksilver
//
// Created by Alcor on 7/5/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "QSTrackingWindow.h"
#import "QSTypes.h"

@implementation QSTrackingWindow
+ (QSTrackingWindow *)trackingWindow {
	QSTrackingWindow* window = [[[QSTrackingWindow alloc] initWithContentRect:NSZeroRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreRetained defer:YES] autorelease];
	[window setBackgroundColor: [[NSColor redColor] colorWithAlphaComponent:0.5]];
	[window setOpaque:NO];
	[window setIgnoresMouseEvents:YES];
	[window setHasShadow:NO];
	[window setLevel:kCGPopUpMenuWindowLevel-1];
	[window setSticky:YES];
	[window setDelegate:[window contentView]];
	NSMutableArray *types = [[standardPasteboardTypes mutableCopy] autorelease];
 // [types addObjectsFromArray:[[QSReg objectHandlers] allKeys]];
	[window registerForDraggedTypes:types];
	return window;
}

- (void)sendEvent:(NSEvent *)theEvent {
	//NSLog(@"Event %@", theEvent);
	[super sendEvent:theEvent];
}

- (void)updateTrackingRect {
	
#ifdef DEBUG
	if (VERBOSE) NSLog(@"update");
#endif
	
	//logRect([self frame]);
	if (trackingRect) [[self contentView] removeTrackingRect:trackingRect];
	trackingRect = [[self contentView] addTrackingRect:NSMakeRect(0, 0, NSWidth([self frame]), NSHeight([self frame]) ) owner:self userData:self assumeInside:NO];
}

- (void)setFrame:(NSRect)frameRect display:(BOOL)flag {
	[super setFrame:frameRect display:flag];
	[self updateTrackingRect];
}

- (void)mouseEntered:(NSEvent *)theEvent {
	
#ifdef DEBUG
	if (VERBOSE) NSLog(@"entered tracking");
#endif
	
	[[self delegate] mouseEntered:theEvent];
}

- (void)mouseExited:(NSEvent *)theEvent {

#ifdef DEBUG
	if (VERBOSE) NSLog(@"exited tracking");
#endif
	
	[[self delegate] mouseExited:theEvent];
}

- (unsigned int) draggingEntered:(id <NSDraggingInfo>)theEvent {
	
#ifdef DEBUG
	if (VERBOSE) NSLog(@"dragging tracking");
#endif
	
	[[self delegate] mouseEntered:nil];
	return NSDragOperationEvery;
}

- (BOOL)canBecomeKeyWindow {return NO;}
- (BOOL)canBecomeMainWindow {return NO;}

- (id <QSTrackingWindowDelegate>)delegate {
    return (id <QSTrackingWindowDelegate>)[super delegate];
}

- (void)setDelegate:(id <QSTrackingWindowDelegate>)delegate {
    [super setDelegate:
#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1060
    (id <NSWindowDelegate>)
#endif
    delegate];
}

@end
