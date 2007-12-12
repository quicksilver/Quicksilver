//
//  QSMainMenuPrefPane.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 6/11/06.

//

#import "QSMainMenuPrefPane.h"

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

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id)listener {
	//QSLog(@"handle %@ %@", actionInformation, frame);
	
	BOOL external = NO; 	
	if ([[[request URL] scheme] isEqualToString:@"http"]) {

		if ([[[request URL] host] hasPrefix:@"docs.blacktree.com"]) {
			external = NO;
		} else if ([[[request URL] host] hasPrefix:@"quicksilver.blacktree.com"]) {
				external = NO;
		} else {
				external = YES;
		}
	} else if ([[[request URL] scheme] isEqualToString:@"file"]) {
		external = NO;
	} else {
		external = YES;
	}
	
	if ([[[request URL] scheme] hasPrefix:@"qs"]) {
		[[NSApp delegate] openURL:[request URL]];
	} else if (external) {
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
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
			request = [[request mutableCopy] autorelease];
			[(NSMutableURLRequest *)request  setURL:[NSURL fileURLWithPath:path]];
		}
	} else if ([[[request URL] scheme] isEqualToString:@"qsimage"]) {
		//		NSString *path = [[request URL] resourceSpecifier];
		//		request = [[request mutableCopy] autorelease];
		//		[(NSMutableURLRequest *)request  setURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:[path stringByDeletingPathExtension] ofType:[path pathExtension]]]];
		
		NSString *path = [QSRez pathForImageNamed:[[request URL] host]];
		
		if (path) {
			request = [[request mutableCopy] autorelease];
			[(NSMutableURLRequest *)request  setURL:[NSURL fileURLWithPath:path]];
		}
		
	}
	return request;
}

- (IBAction)goHome:(id)sender {
	NSString *path = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/SharedSupport/Guide.html"];
	NSURL *guideURL = [NSURL fileURLWithPath:path];
	NSString *content = [NSString stringWithContentsOfFile:path];
	
	//content = [NSString stringWithFormat:content, [NSApp versionString]];
//	QSLog(@"content %@", content);
		
	[[guideView mainFrame] loadRequest:[NSURLRequest requestWithURL:guideURL]];
//	[[guideView mainFrame] loadHTMLString:@"test" baseURL:guideURL];
	
	
}

- (IBAction)showInBrowser:(id)sender {
	NSURL *url = [[[[guideView mainFrame] dataSource] mainResource] URL];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

#define SEARCH_URL @"http://docs.blacktree.com/?do = search&id = %@"
- (IBAction)search:(id)sender {
	NSString *urlString = [NSString stringWithFormat:SEARCH_URL, [sender stringValue]];
	NSString *searchURL = [NSURL URLWithString:urlString];
	[[guideView mainFrame] loadRequest:[NSURLRequest requestWithURL:searchURL]];
}

@end
