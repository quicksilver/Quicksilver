//
// QSSimpleWebWindow.m
// Quicksilver
//
// Created by Alcor on 5/27/05.
// Copyright 2005 Blacktree, Inc. All rights reserved.
//

#import "QSSimpleWebWindowController.h"
#import "QSWindow.h"
#import <WebKit/WebKit.h>

@interface QSSimpleWebWindowController () <NSFileManagerDelegate>
@end

@implementation QSSimpleWebWindowController

- (id)initWithWindow:(id)window {
	NSRect windowRect = NSMakeRect(100, 100, 300, 300);
	window = [[QSWindow alloc] initWithContentRect:windowRect styleMask:NSTitledWindowMask | NSUtilityWindowMask | NSNonactivatingPanelMask | NSClosableWindowMask | NSResizableWindowMask | NSMiniaturizableWindowMask backing:NSBackingStoreBuffered defer:NO];
	[window setBackgroundColor: [NSColor colorWithDeviceWhite:1.0 alpha:0.9]];
	[window setOpaque:NO];
	[window setAlphaValue:1.0];
	[window setLevel:kCGNormalWindowLevel];
	[window setHidesOnDeactivate:NO]; [window setCanHide:NO];
	[window setDelegate:self];
	[window setReleasedWhenClosed:YES];
	[window setMovableByWindowBackground:NO];
	WebView *wv = [[WebView alloc] initWithFrame:windowRect frameName:nil groupName:nil];
	[window setContentView:wv];

	//NSLog(@"loaded %@", window);

	self = [super initWithWindow:window];

	if (self != nil) {
		[window setDelegate:self];
		NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"mainToolbar"];

		[toolbar setDelegate:self];
		[toolbar setAllowsUserCustomization:YES];
		[toolbar setAutosavesConfiguration:YES];
		//[toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
		[toolbar setSizeMode:NSToolbarSizeModeSmall];
		[window setToolbar:toolbar];
	}
	return self;
}

- (void)openURL:(NSURL *)url {
	[[[[self window] contentView] mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)URL {
    QSGCDMainSync(^{
        [[[[self window] contentView] mainFrame] loadHTMLString:string baseURL:URL];
    });
}


- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
	return [NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier,
		NSToolbarSpaceItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier,
		NSToolbarCustomizeToolbarItemIdentifier, @"Backward", @"Forward", @"Stop", @"Reload", @"URLField", nil];
}
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
	return [NSArray arrayWithObjects:NSToolbarFlexibleSpaceItemIdentifier,
		NSToolbarCustomizeToolbarItemIdentifier, @"Backward", @"Forward", @"Stop", @"Reload", @"URLField", nil];
}
#define safariBundle [NSBundle bundleWithPath:[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.apple.Safari"]]

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
	 itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag {
	NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	if ( [itemIdentifier isEqualToString:@"URLField"] ) {

		NSRect fRect = NSMakeRect(0, 0, 128, 16);
		NSTextField *textField = [[NSTextField alloc] initWithFrame:fRect];
		[[textField cell] setControlSize:NSSmallControlSize];
		[item setLabel:@"URL"];
		[item setPaletteLabel:[item label]];
		[item setView:textField];
		[item setMinSize:NSMakeSize(128, 24)];
		[item setMaxSize:NSMakeSize(9999, 32)];
		[textField setTarget:[[self window] contentView]];
		[textField setAction:@selector(takeStringURLFrom:)];
	} else if ( [itemIdentifier isEqualToString:@"Backward"] ) {
		[item setLabel:@"Back"];
		[item setPaletteLabel:[item label]];
		[item setImage:[safariBundle imageNamed:@"Back"]];
		[item setTarget:[[self window] contentView]];
		[item setAction:@selector(goBack:)];
	} else if ( [itemIdentifier isEqualToString:@"Forward"] ) {
		[item setLabel:@"Forward"];
		[item setPaletteLabel:[item label]];
		[item setImage:[safariBundle imageNamed:@"Forward"]];
		[item setTarget:[[self window] contentView]];
		[item setAction:@selector(goForward:)];
	} else if ( [itemIdentifier isEqualToString:@"Stop"] ) {
		[item setLabel:@"Stop"];
		[item setPaletteLabel:[item label]];
		[item setImage:[safariBundle imageNamed:@"Stop"]];
		[item setTarget:[[self window] contentView]];
		[item setAction:@selector(stopLoading:)];
	} else if ( [itemIdentifier isEqualToString:@"Reload"] ) {
		[item setLabel:@"Reload"];
		[item setPaletteLabel:[item label]];
		[item setImage:[safariBundle imageNamed:@"Reload"]];
		[item setTarget:[[self window] contentView]];
		[item setAction:@selector(reload:)];
	} else if ( [itemIdentifier isEqualToString:@"SearchItem"] ) {
		// Configuration code for "SearchItem"
	}

	return item;
}
- (BOOL)windowShouldClose:(id)sender {
	return YES;
}
@end
