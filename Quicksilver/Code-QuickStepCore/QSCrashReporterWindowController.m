//
//  QSCrashReporterWindowController.m
//  Quicksilver
//
//  Created by Patrick Robertson on 20/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QSCrashReporterWindowController.h"
#import <WebKit/WebKit.h>
#import "QSController.h"
#import "QSPaths.h"

@implementation QSCrashReporterWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    [[crashReporterWebView preferences] setDefaultTextEncodingName:@"utf-8"];
	[crashReporterWebView setDrawsBackground:NO];
	[crashReporterWebView setPolicyDelegate:self];
    [[self window] setDelegate:self];
    [[self window] setLevel:NSModalPanelWindowLevel];
    if ([[QSController sharedInstance] crashReportPath]) {
        [[crashReporterWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:[[NSBundle mainBundle] URLForResource:@"CrashReporterText" withExtension:@"html"]]];
    } else {
        NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"PluginReporterText" ofType:@"html"];
        NSString *htmlString = [NSString stringWithContentsOfFile:resourcePath encoding:NSUTF8StringEncoding error:nil];
        NSDictionary *state = [NSDictionary dictionaryWithContentsOfFile:pStateLocation];

        htmlString = [htmlString stringByReplacingOccurrencesOfString:@"***" withString:[state objectForKey:kQSPluginCausedCrashAtLaunch]];
        [[crashReporterWebView mainFrame] loadHTMLString:htmlString baseURL:[NSURL fileURLWithPath:[resourcePath stringByDeletingLastPathComponent]]];
        [doNothingButton setTitle:@"Do Nothing"];
        [reportOrFixButton setTitle:@"Delete Plugin"];
    }
}

// If links are clicked, open them in the default browser (not the web view in the crash reporter window)
- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation
		request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id)listener {
	if ([[request URL] isFileURL]) {
		[listener use];
    }
	else {
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
		[listener ignore];
	}
}

- (IBAction)sendCrashReport:(id)sender {
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSString *crashReportPath = [[QSController sharedInstance] crashReportPath];
    if (crashReportPath) {
        // do crash reporting here
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:kCrashReporterURL]];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
        NSError *err = nil;
        
        NSString *crashLogContent = [NSString stringWithContentsOfFile:crashReportPath encoding:NSUTF8StringEncoding error:&err];
        if (err) {
            NSLog(@"Error getting crash log: %@",err);
        }
        crashLogContent = [crashLogContent stringByReplacingOccurrencesOfString:[@"~" stringByExpandingTildeInPath] withString:@"USER_DIR"];
        // encode the crash log contents. URLEncoding (correctly) leaves '&' as they are. It must be done manually here.
        
        NSString *postString = [NSString stringWithFormat:@"name=%@&data=%@",[[crashReportPath lastPathComponent] URLEncodeValue], [crashLogContent URLEncodeValue]];
        
        [request setValue:[NSString stringWithFormat:@"%d", [postString length]]
       forHTTPHeaderField:@"Content-length"];
        
        [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
        
        [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        [crashReportPath release];
    } else {
        // delete the fault plugin
        NSDictionary *state = [NSDictionary dictionaryWithContentsOfFile:pStateLocation];
        NSString *faultyPluginPath = [state objectForKey:kQSFaultyPluginPath];
        if (faultyPluginPath) {
            if (![fm removeItemAtPath:faultyPluginPath error:nil]) {
                NSLog(@"Error removing faulty plugin. Continuing to attempt a launch");
            }
        }
    }
    [fm release];
    [self close];
}

- (void)windowWillClose:(id)sender {
    [NSApp stopModal];
}

- (IBAction)doNothing:(id)sender {
    [self close];
}

// Required delegate methods for URLConnections
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse*)response {
    return;
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    return;
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    return;
}


@end
