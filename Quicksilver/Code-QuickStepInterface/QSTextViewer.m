//
// QSTextViewer.m
// Quicksilver
//
// Created by Nicholas Jitkoff on 7/2/05.
// Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "QSTextViewer.h"
#import "QSWindow.h"

QSTextViewer * QSShowTextViewerWithString(NSString *string) {
	QSTextViewer *tv = [[QSTextViewer alloc] initWithWindow:nil];
	[tv setString:string];
	return tv;
}

QSTextViewer * QSShowTextViewerWithFile(NSString *path) {
	NSString *string = [NSString stringWithContentsOfFile:path usedEncoding:nil error:nil];
	QSTextViewer *tv = [[QSTextViewer alloc] initWithWindow:nil];
	[tv setString:string];
	return tv;
}

@interface QSTextViewer () <NSFileManagerDelegate>
@end

@implementation QSTextViewer

- (id)initWithWindow:(id)window {
	NSRect windowRect = NSMakeRect(100, 100, 480, 320);
	window = [[QSWindow alloc] initWithContentRect:windowRect styleMask:NSTitledWindowMask | NSUtilityWindowMask | NSNonactivatingPanelMask | NSClosableWindowMask | NSResizableWindowMask | NSMiniaturizableWindowMask backing:NSBackingStoreBuffered defer:NO];
	[window setBackgroundColor:[NSColor colorWithDeviceWhite:1.0 alpha:0.9]];
	[window setOpaque:NO];
	[window setAlphaValue:1.0];
	[window setLevel:kCGFloatingWindowLevel];
	[window setHidesOnDeactivate:NO];
	[window setCanHide:NO];
	[window setDelegate:self];
	[window setMovableByWindowBackground:NO];
/*	NSTextView *textview = [[NSTextView alloc] initWithFrame:windowRect];
	[window setContentView:textview];
	[textview release];*/
	[window setReleasedWhenClosed:YES];
	[window center];

	NSScrollView *scrollview = [[NSScrollView alloc] initWithFrame:[[window contentView] frame]];
	[scrollview setBorderType:NSNoBorder];
	[scrollview setHasVerticalScroller:YES];
	[scrollview setHasHorizontalScroller:NO];
	[scrollview setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	NSSize contentSize = [scrollview contentSize];

	NSTextView *theTextView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
	[theTextView setMinSize:NSMakeSize(0.0, contentSize.height)];
	[theTextView setMaxSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MIN)];
	[theTextView setVerticallyResizable:YES];
	[theTextView setHorizontallyResizable:NO];
	[theTextView setAutoresizingMask:NSViewWidthSizable];
	[[theTextView textContainer] setContainerSize:NSMakeSize(contentSize.width, CGFLOAT_MIN)];
	[[theTextView textContainer] setWidthTracksTextView:YES];

	[scrollview setDocumentView:theTextView];
	[window setContentView:scrollview];
	[window makeKeyAndOrderFront:nil];
	[window makeFirstResponder:theTextView];

	[[theTextView enclosingScrollView] setHasHorizontalScroller:YES];
	[theTextView setHorizontallyResizable:YES];
	[theTextView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
	[[theTextView textContainer] setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MIN)];
	[[theTextView textContainer] setWidthTracksTextView:YES];

	//NSLog(@"loaded %@", window);

	self = [super initWithWindow:window];

	if (self != nil) {
		[window setDelegate:self];
	//	NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"mainToolbar"];
//
//		[toolbar setDelegate:self];
//		[toolbar setAllowsUserCustomization:YES];
//		[toolbar setAutosavesConfiguration:YES];
//		//[toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
//		[toolbar setSizeMode:NSToolbarSizeModeSmall];
//		[window setToolbar:[toolbar autorelease]];

	}
	return self;
}

- (NSTextView *)textView {
	return [[[self window] contentView] documentView];
}

- (void)setString:(NSString *)string {
	[[self textView] setString:string];
}

- (BOOL)windowShouldClose:(id)sender {
	//textView = nil;
	[[self window] setDelegate:nil];
	[self setWindow:nil];
	return YES;
}
@end
