//
// QSMainMenuPrefPane.m
// Quicksilver
//
// Created by Nicholas Jitkoff on 6/11/06.
// Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "QSMainMenuPrefPane.h"
#import "QSResourceManager.h"
#import "QSController.h"

@interface WebView (Private)
- (void)setDrawsBackground:(BOOL)flag;
@end

@implementation QSMainMenuPrefPane
- (NSString *)mainNibName {
	return @"QSMainMenuPrefPane";
}
- (void)didReselect {
	[self goHome:nil];
}
- (void)awakeFromNib {
	[guideView setDrawsBackground:YES];
	[guideView setMediaStyle:@"print"];
	[self goHome:nil];
}
- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame {
	[progressIndicator startAnimation:nil];
	[progressIndicator setHidden:NO];
}
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	[progressIndicator stopAnimation:nil];
	[progressIndicator setHidden:YES];
}

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id)listener {
	BOOL external = NO;
	NSURL *url = [request URL];
	if ([[url scheme] isEqualToString:@"http"]) {
		if ([[url host] hasPrefix:@"docs.blacktree.com"])
			external = NO;
		else if ([[url host] hasPrefix:@"qs0.blacktree.com"])
			external = NO;
		else
			external = YES;
	} else if ([[url scheme] isEqualToString:@"file"]) {
		external = NO;
	} else {
		external = YES;
	}
	if ([[url scheme] hasPrefix:@"qs"]) {
		[(QSController *)[NSApp delegate] openURL:url];
	} else if (external) {
		[[NSWorkspace sharedWorkspace] openURL:url];
		[listener ignore];
	} else {
		[listener use];
	}
}

- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource {
	if ([[[request URL] scheme] isEqualToString:@"resource"]) {
		NSString *path = [[request URL] resourceSpecifier];
		path = [[NSBundle mainBundle] pathForResource:[path stringByDeletingPathExtension] ofType:[path pathExtension]];
		if (path) {
			request = [request mutableCopy];
			[(NSMutableURLRequest *)request setURL:[NSURL fileURLWithPath:path]];
		}
	} else if ([[[request URL] scheme] isEqualToString:@"qsimage"]) {
		NSString *path = [[QSResourceManager sharedInstance] pathForImageNamed:[[request URL] host]];
		if (path) {
			request = [request mutableCopy];
			[(NSMutableURLRequest *)request setURL:[NSURL fileURLWithPath:path]];
		}
	}
	return request;
}

- (IBAction)goHome:(id)sender {
	[[guideView mainFrame] loadRequest:[NSURLRequest requestWithURL:[[NSBundle mainBundle] URLForResource:@"Guide" withExtension:@"html"]]];
}

- (IBAction)showInBrowser:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[[[[guideView mainFrame] dataSource] mainResource] URL]];
}

- (IBAction)search:(id)sender {
	[[guideView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:kHelpSearchURL, [sender stringValue]]]]];
}

@end
