//
//  QSCrashReporterWindowController.h
//  Quicksilver
//
//  Created by Patrick Robertson on 20/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

@class WebView;
@interface QSCrashReporterWindowController : NSWindowController <NSWindowDelegate, NSURLConnectionDelegate>
{

	IBOutlet WebView *crashReporterWebView;
    IBOutlet NSButton *deletePluginButton;
    IBOutlet NSTextField *commentsField;

}

- (IBAction)sendCrashReport:(id)sender;
- (IBAction)doNothing:(id)sender;
- (void)clearCaches;

@end
