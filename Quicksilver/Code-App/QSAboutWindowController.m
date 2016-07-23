#import "QSAboutWindowController.h"
#import <Quartz/Quartz.h>
#import <WebKit/WebKit.h>
//#import "QSResourceManager.h"
#import "NSScreen_BLTRExtensions.h"

@interface QCView (Private)
- (void)setClearsBackground:(BOOL)flag;
@end

@interface QSAboutWindowController () <WebPolicyDelegate>
@end

@implementation QSAboutWindowController
- (id)init {
	self = [super initWithWindowNibName:@"About" owner:self];
	return self;
}

- (void)awakeFromNib {
#ifdef DEBUG
	NSLog(@"awake");
#endif
	NSBundle *appBundle = [NSBundle mainBundle];
	NSString *name = [appBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	if (!name)
		name = @"Quicksilver";
	NSWindow *aboutWindow = [self window];
    [NTViewLocalizer localizeWindow:aboutWindow table:@"About" bundle:[NSBundle mainBundle]];


	[aboutWindow setDelegate:self]; // needed, so windowWillClose: method is called
	[(NSTextField *)[aboutWindow initialFirstResponder] setStringValue:[NSString stringWithFormat:@"%@ (%@)", name, [appBundle objectForInfoDictionaryKey:@"CFBundleVersion"]]];
	[aboutWindow center];
	if (![NSFont fontWithName:@"HiraKakuPro-W3" size:10.0]) {
		NSLog(@"HiraKakuPro-W3 not found. Removing chinese characters");
		NSView *subview;
		NSView *contentView = [aboutWindow contentView];
		while (subview = [contentView viewWithTag:1])
			[subview removeFromSuperview];
	}
	[[creditsView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[appBundle bundlePath] stringByAppendingPathComponent:@"Contents/SharedSupport/Credits.html"]]]];
//	[creditsView changeDocumentBackgroundColor:[NSColor greenColor]];
	[[creditsView preferences] setDefaultTextEncodingName:@"utf-8"];
	[creditsView setDrawsBackground:NO];
	[creditsView setPolicyDelegate:self];

	if ([[NSScreen mainScreen] usesOpenGLAcceleration]) {
		NSRect r = [imageView frame];
		r.origin = [aboutWindow convertBaseToScreen:r.origin];
		NSWindow *window = [[[NSWindow class] alloc] initWithContentRect:r styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
		[window setIgnoresMouseEvents:YES];
		[window setBackgroundColor:[NSColor clearColor]];
		[window setOpaque:NO];
		[window setHasShadow:NO];
		/* 2012-06-20 Rob McBroom
		   The analyzer might complain that `window` needs to be autoreleased, but this takes care of it.
		*/
		[window setReleasedWhenClosed:YES];
		QCView *content = [[QCView alloc] init];
		[content loadCompositionFromFile:[appBundle pathForResource:@"QSSplash" ofType:@"qtz"]];
		[window setContentView:content];
		[content setEraseColor:[NSColor clearColor]];
		[content setClearsBackground:YES];
//		[content startRendering]; // moved to showWindow: method
		[content setMaxRenderingFrameRate:10];
		[window display];
		[aboutWindow addChildWindow:window ordered:NSWindowAbove];
		[imageView removeFromSuperview];
	}
}

- (IBAction)showWindow:(id)sender {
	// start rendering QS animation each time the window is opened
	[[[[[self window] childWindows] objectAtIndex:0] contentView] startRendering];
	[super showWindow:sender];
}

- (void)windowWillClose:(NSNotification *)notification {
	// stop rendering QS animation each time the window is closed
	[[[[[notification object] childWindows] objectAtIndex:0] contentView] stopRendering];
}

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id)listener {
	if ([[[request URL] scheme] isEqualToString:@"file"])
		[listener use];
	else {
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
		[listener ignore];
	}
}

- (BOOL)showCredits { return showCredits;  }
- (void)setShowCredits:(BOOL)flag {
	showCredits = flag;
}

@end
