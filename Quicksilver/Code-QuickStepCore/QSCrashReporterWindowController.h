//
//  QSCrashReporterWindowController.h
//  Quicksilver
//
//  Created by Patrick Robertson on 20/03/2012.
//  Copyright (c) 2012. All rights reserved.
//

#import <AppKit/AppKit.h>

@class WebView;
@interface QSCrashReporterWindowController : NSWindowController <NSWindowDelegate,
#if (MAC_OS_X_VERSION_MIN_REQUIRED >= 1070)
NSURLConnectionDelegate,
#endif
NSControlTextEditingDelegate>
{
    // Connections to QSCrashReporter.xib
	IBOutlet WebView *crashReporterWebView;
    BOOL crashReporterIsWorking;
    IBOutlet NSButton *deletePluginCheckbox;
    IBOutlet NSTextField *commentsField;

}

@property BOOL crashReporterIsWorking;

- (IBAction)sendCrashReport:(id)sender;
- (IBAction)doNothing:(id)sender;
- (void)clearCaches;
- (void)deletePlugin;
- (IBAction)openCrashReportsWikiPage:(id)sender;

@end
