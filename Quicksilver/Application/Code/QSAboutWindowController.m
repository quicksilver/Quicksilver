//
//  QSAboutWindowController.m
//  Quicksilver
//
//  Created by Alcor on 4/16/05.

//


#import <Carbon/Carbon.h>
#import <Quartz/Quartz.h>
#import <WebKit/WebKit.h>

#import "QSAboutWindowController.h"

@interface QCView (Private)
- (void)setClearsBackground:(BOOL)flag;
@end

@implementation QSAboutWindowController
- (id)init {
	self = [super initWithWindowNibName:@"About" owner:self];
	if (self != nil) {
	}
	return self;
}

- (void)awakeFromNib {
	// [versionField setStringValue:[NSApp versionString]];
	NSBundle *appBundle = [NSBundle mainBundle];
	
	NSString *name = [appBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	if (!name) name = @"Quicksilver";
	NSString *versionString = [NSString stringWithFormat:@"%@ (%@) ", name, [appBundle objectForInfoDictionaryKey:@"CFBundleVersion"]];
	
	[(NSTextField *)[[self window] initialFirstResponder] setStringValue:versionString];
	[[self window] center];  
	
	NSView *contentView = [[self window] contentView];
	if ((GetCurrentKeyModifiers() & (controlKey | rightControlKey) )) {
		[(NSImage *)[QSRez daedalusImage] setSize:QSSize128];
		[[contentView viewWithTag:2] setImage:[QSRez daedalusImage]]; 	
	}
	
	if (![NSFont fontWithName:@"HiraKakuPro-W3" size:10.0]) {
		QSLog(@"HiraKakuPro-W3 not found. Removing chinese characters");
		NSView *subview;
		while ((subview = [contentView viewWithTag:1]))
			[subview removeFromSuperview];
	}
	NSString *path = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/SharedSupport/Credits.html"];
	[[creditsView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
	[creditsView changeDocumentBackgroundColor:[NSColor greenColor]];
	[[creditsView preferences] setDefaultTextEncodingName:@"utf-8"];
	[creditsView setDrawsBackground:NO];
	[creditsView setPolicyDelegate:self];
	
	BOOL supportsQuartzExtreme = [[NSScreen mainScreen] usesOpenGLAcceleration];
	
	if (1 || (fDEV && supportsQuartzExtreme)) {
		NSRect r = [imageView frame];
		
		r.origin = [[self window] convertBaseToScreen:r.origin];

		NSWindow *window = [[[NSWindow class] alloc] initWithContentRect:r styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
		[window setIgnoresMouseEvents:YES];
		[window setBackgroundColor: [NSColor clearColor]];
		[window setOpaque:NO];
		[window setHasShadow:NO];
		[window setReleasedWhenClosed:YES];
		
		QCView *content = [[[QCView alloc] init] autorelease];
		NSString *path = [[NSBundle mainBundle] pathForResource:@"QSSplash" ofType:@"qtz"];
		[content loadCompositionFromFile:path];
		[window setContentView:content]; 		
		[content setEraseColor:[NSColor clearColor]];
		[content setClearsBackground:YES];
		[content startRendering];
		[content setMaxRenderingFrameRate:10];
		[window display];
		
		[[self window] addChildWindow:window ordered:NSWindowAbove];
		[imageView removeFromSuperview];
	}
	
	
	
	
}

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id)listener {
	
	if (![[[request URL] scheme] isEqualToString:@"file"]) {
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
		[listener ignore];
	} else {
		[listener use]; 	
	}
}

- (BOOL)showCredits { return showCredits;  }
- (void)setShowCredits:(BOOL)flag {
    showCredits = flag;
}

@end
