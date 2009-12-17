#import "QSAboutWindowController.h"
#import <Carbon/Carbon.h>
#import <Quartz/Quartz.h>
#import <WebKit/WebKit.h>
//#import "QSResourceManager.h"
#import "NSScreen_BLTRExtensions.h"

@interface QCView (Private)
- (void)setClearsBackground:(BOOL)flag;
@end

@implementation QSAboutWindowController
- (id)init {
	self = [super initWithWindowNibName:@"About" owner:self];
	return self;
}

- (void)awakeFromNib {
	NSBundle *appBundle = [NSBundle mainBundle];
	NSString *name = [appBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	if (!name)
		name = @"Quicksilver";
	NSWindow *aboutWindow = [self window];
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
		[window setReleasedWhenClosed:YES];
		QCView *content = [[QCView alloc] init];
		[content loadCompositionFromFile:[appBundle pathForResource:@"QSSplash" ofType:@"qtz"]];
		[window setContentView:content];
		[content setEraseColor:[NSColor clearColor]];
		[content setClearsBackground:YES];
		[content startRendering];
		[content setMaxRenderingFrameRate:10];
		[content release];
		[window display];
		[aboutWindow addChildWindow:window ordered:NSWindowAbove];
		[imageView removeFromSuperview];
	}
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
