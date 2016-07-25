//
//  QSCrashReporterWindowController.m
//  Quicksilver
//
//  Created by Patrick Robertson on 20/03/2012.
//  Copyright (c) 2012. All rights reserved.
//

#import "QSCrashReporterWindowController.h"
#import <WebKit/WebKit.h>
#import "QSController.h"
#import "QSPaths.h"
#import "QSPlugIn.h"

@interface QSCrashReporterWindowController () <WebPolicyDelegate>
@end

@implementation QSCrashReporterWindowController

@synthesize crashReporterIsWorking;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [self setCrashReporterIsWorking:NO];
    
    // if there is a 'crashReportPath' (i.e. Quicksilver crashed)
    if ([[QSController sharedInstance] crashReportPath]) {
        // populate the HTML field in the reporter window with the text from CrashReporterText.html
        [[crashReporterWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:[[NSBundle mainBundle] URLForResource:@"CrashReporterText" withExtension:@"html"]]];
    // else if there's no 'crashReportPath' (i.e. a plugin caused Quicksilver to crash
    } else {
        // Populate the HTML field in reporter window with the PluginReporterText.html file, replacing *** with the plugin name
        NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"PluginReporterText" ofType:@"html"];
        NSString *htmlString = [NSString stringWithContentsOfFile:resourcePath encoding:NSUTF8StringEncoding error:nil];
        NSDictionary *state = [NSDictionary dictionaryWithContentsOfFile:pStateLocation];
        
        [deletePluginCheckbox setHidden:NO];
        // remove the words 'plugin' or 'module' from the plugin name, so the word doesn't display twice in the crash reporter window
        // e.g. we don't want "The 1Password Module plugin caused Quicksilver to crash..."
        NSString *pluginName = [state objectForKey:kQSPluginCausedCrashAtLaunch]; 
        pluginName = [pluginName stringByReplacingOccurrencesOfString:@" Plugin" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [pluginName length])];
        pluginName = [pluginName stringByReplacingOccurrencesOfString:@" Module" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [pluginName length])];
        htmlString = [htmlString stringByReplacingOccurrencesOfString:@"***" withString:pluginName];
        [[crashReporterWebView mainFrame] loadHTMLString:htmlString baseURL:[NSURL fileURLWithPath:[resourcePath stringByDeletingLastPathComponent]]];
        
    }
    // set up the crash reporter web view (that loads the HTML files
    [[crashReporterWebView preferences] setDefaultTextEncodingName:@"utf-8"];
	[crashReporterWebView setDrawsBackground:NO];
	[crashReporterWebView setPolicyDelegate:self];
    
    [[self window] setDelegate:self];
    // put the window above the rest
    [[self window] setLevel:NSModalPanelWindowLevel];

    // clear the caches incase they caused a crash
    [self clearCaches];
}

- (void)clearCaches {
    // Use QSLibrarian to clear caches and force a new scan
    [QSLibrarian removeIndexes];
    [QSLib startThreadedAndForcedScan];
}

- (void)deletePlugin {
    // delete the faulty plugin
    NSDictionary *state = [NSDictionary dictionaryWithContentsOfFile:pStateLocation];
    NSString *faultyPluginPath = [state objectForKey:kQSFaultyPluginPath];
    if (faultyPluginPath) {
        QSPlugIn *pluginToDelete = [QSPlugIn plugInWithBundle:[NSBundle bundleWithPath:faultyPluginPath]];
        [pluginToDelete delete];
    }
}

#pragma mark Button Press Methods

- (IBAction)sendCrashReport:(id)sender {
    
    [self setCrashReporterIsWorking:YES];
    
    // Get the user comments from the text field
    NSString *userComments = [[commentsField stringValue] URLEncodeValue];
    
    // Create an URLRequest to the crash reporter server
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:kCrashReporterURL]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];

    NSString *crashLogContent, *name;
    
    if ([[QSController sharedInstance] crashReportPath]) {
        // Report Quicksilver Crash
        NSError *err = nil;
        // pull the crash log from the .crash file (located at crashReportPath)
        crashLogContent = [NSString stringWithContentsOfFile:[[QSController sharedInstance] crashReportPath] encoding:NSUTF8StringEncoding error:&err];
        if (err) {
            NSLog(@"Error getting crash log: %@",err);  
        }
        name = [[[[QSController sharedInstance] crashReportPath] lastPathComponent] URLEncodeValue];
    } else {
        NSDictionary *state =[NSDictionary dictionaryWithContentsOfFile:pStateLocation];
        // name the crash file Plugin-NAME_OF_PLUGIN-UNIQUE_STRING.crash
        name = [[NSString stringWithFormat:@"Plugin-%@-%@.crash",[state objectForKey:kQSPluginCausedCrashAtLaunch], [NSString uniqueString]] URLEncodeValue];
        // Obtain the plugin's Info.plist (for sending to the server)
        NSDictionary *faultyPluginInfoDict = [[NSBundle bundleWithPath:[state objectForKey:kQSFaultyPluginPath]] infoDictionary];
        
        // create a crash log file with the plugin name and Info.plist dictionary
        crashLogContent = [NSString stringWithFormat:@"Mac OS X: %@\nQuicksilver: %@\n\nCrashed Plugin:\n%@",[NSApplication macOSXFullVersion],[NSApp versionString],[faultyPluginInfoDict description]];
    }

    // Anonymise the crash report
    crashLogContent = [crashLogContent stringByReplacingOccurrencesOfString:[@"~" stringByExpandingTildeInPath] withString:@"USER_DIR"];
    crashLogContent = [crashLogContent URLEncodeValue];
    
    // Set the POST keys and names (for receiving the by the server using $_POST['key']
    NSString *postString = [NSString stringWithFormat:@"name=%@&data=%@&comments=%@",name, crashLogContent, userComments];

    [request setValue:kQSUserAgent forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setValue:[NSString stringWithFormat:@"%ld", (long)[postString length]]
   forHTTPHeaderField:@"Content-length"];
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    
    // Launch request to server
    [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    // Delete the plugin if the checkbox is selected
    if ([deletePluginCheckbox integerValue]) {
        [self deletePlugin];
    }
    [self close];
}

// Corresponds to the Don't Send button on the crash reporter. Closes the window
- (IBAction)doNothing:(id)sender {
    crashReporterIsWorking = YES;
    // Delete the plugin if the checkbox is selected
    if ([deletePluginCheckbox integerValue]) {
        [self deletePlugin];
    }
    [self close];
}

// Corresponds to the ? button on the crash reporter
- (IBAction)openCrashReportsWikiPage:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kCrashReportsWikiURL]];
}

#pragma mark NSURLConnection Delegate Methods

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

#pragma mark NSWindow Delegate Methods

- (void)windowWillClose:(id)sender {
    [self setCrashReporterIsWorking:NO];
    [NSApp stopModal];
}

#pragma mark NSTextField Delegate Methods

// Allow the user to use the return key to enter a newline in the text cell
- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector {
    
    BOOL retval = NO;
    if (commandSelector == @selector(insertNewline:)) {
        retval = YES;
        [fieldEditor insertNewlineIgnoringFieldEditor:nil];
    }
    return retval;
}

@end
