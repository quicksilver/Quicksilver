#import "QSAboutWindowController.h"
#import <Quartz/Quartz.h>
#import <WebKit/WebKit.h>
//#import "QSResourceManager.h"
#import "NSScreen_BLTRExtensions.h"

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
	[[creditsView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[appBundle sharedSupportPath] stringByAppendingPathComponent:@"Credits.html"]]]];
//	[creditsView changeDocumentBackgroundColor:[NSColor greenColor]];
	[[creditsView preferences] setDefaultTextEncodingName:@"utf-8"];
	[creditsView setDrawsBackground:NO];
	[creditsView setPolicyDelegate:self];
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
