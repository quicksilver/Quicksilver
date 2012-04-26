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

    // var used to store the faulty plugin's info.plist dict (since it won't exist if the user deletes the plugin)
    faultyPluginInfoDict = nil;
    
    if ([[QSController sharedInstance] crashReportPath]) {
        [[crashReporterWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:[[NSBundle mainBundle] URLForResource:@"CrashReporterText" withExtension:@"html"]]];
        [deletePluginButton setHidden:YES];
    } else {
        NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"PluginReporterText" ofType:@"html"];
        NSString *htmlString = [NSString stringWithContentsOfFile:resourcePath encoding:NSUTF8StringEncoding error:nil];
        NSDictionary *state = [NSDictionary dictionaryWithContentsOfFile:pStateLocation];
        faultyPluginInfoDict = [[[NSBundle bundleWithPath:[state objectForKey:kQSFaultyPluginPath]] infoDictionary] retain];
        htmlString = [htmlString stringByReplacingOccurrencesOfString:@"***" withString:[state objectForKey:kQSPluginCausedCrashAtLaunch]];
        [[crashReporterWebView mainFrame] loadHTMLString:htmlString baseURL:[NSURL fileURLWithPath:[resourcePath stringByDeletingLastPathComponent]]];
    }
    [[crashReporterWebView preferences] setDefaultTextEncodingName:@"utf-8"];
	[crashReporterWebView setDrawsBackground:NO];
	[crashReporterWebView setPolicyDelegate:self];
    [[self window] setDelegate:self];
    [[self window] setLevel:NSModalPanelWindowLevel];

    // clear the caches incase they caused a crash
    [self clearCaches];
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

- (IBAction)deletePlugin:(id)sender {
    NSFileManager *fm = [[NSFileManager alloc] init];
    // delete the fault plugin
    NSDictionary *state = [NSDictionary dictionaryWithContentsOfFile:pStateLocation];
    NSString *faultyPluginPath = [state objectForKey:kQSFaultyPluginPath];
    if (faultyPluginPath) {
        if (![fm removeItemAtPath:faultyPluginPath error:nil]) {
            NSLog(@"Error removing faulty plugin from %@", faultyPluginPath);
        }
    }
    [fm release];
}

- (IBAction)sendCrashReport:(id)sender {
    
    NSString *userComments = [[commentsField stringValue] URLEncodeValue];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:kCrashReporterURL]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];

    NSString *crashLogContent, *name;
    
    NSString *crashReportPath = [[QSController sharedInstance] crashReportPath];
    if (crashReportPath) {
        // Report Quicksilver Crash
        NSError *err = nil;
        crashLogContent = [NSString stringWithContentsOfFile:crashReportPath encoding:NSUTF8StringEncoding error:&err];
        if (err) {
            NSLog(@"Error getting crash log: %@",err);  
        }
        name = [[crashReportPath lastPathComponent] URLEncodeValue];
    } else {
        // Report plugin crash
        NSDictionary *state =[NSDictionary dictionaryWithContentsOfFile:pStateLocation];
        // name the crash file Plugin-NAME_OF_PLUGIN-UNIQUE_STRING.crash
        name = [[NSString stringWithFormat:@"Plugin-%@-%@.crash",[state objectForKey:kQSPluginCausedCrashAtLaunch], [NSString uniqueString]] URLEncodeValue];
        crashLogContent = [NSString stringWithFormat:@"Crashed Plugin Information\n\n%@",[faultyPluginInfoDict description]];
    }

    crashLogContent = [crashLogContent stringByReplacingOccurrencesOfString:[@"~" stringByExpandingTildeInPath] withString:@"USER_DIR"];
    crashLogContent = [crashLogContent URLEncodeValue];
    
    NSString *postString = [NSString stringWithFormat:@"name=%@&data=%@&comments=%@",name, crashLogContent, userComments];

    [request setValue:[NSString stringWithFormat:@"%d", [postString length]]
   forHTTPHeaderField:@"Content-length"];
    
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    
    [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    [crashReportPath release];
    [self close];
}

- (void)clearCaches {
    [QSLibrarian removeIndexes];
    [QSLib startThreadedAndForcedScan];
}

- (void)windowWillClose:(id)sender {
    if (faultyPluginInfoDict) {
        [faultyPluginInfoDict release];
    }
    [NSApp stopModal];
}

- (IBAction)doNothing:(id)sender {
    [self close];
}


- (IBAction)openCrashReportsWikiPage:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kCrashReportsWikiURL]];
}


@end
