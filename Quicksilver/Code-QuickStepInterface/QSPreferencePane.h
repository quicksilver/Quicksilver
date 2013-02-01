//
//  QSPreferencePane.h
//  Quicksilver
//
//  Created by Alcor on 11/2/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QSPreferencePane : NSObject
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= 1060)
   <NSWindowDelegate>
#endif
{
	IBOutlet NSWindow *_window;
	IBOutlet NSView *_initialKeyView;
	IBOutlet NSView *_firstKeyView;
	IBOutlet NSView *_lastKeyView;
	NSView *_mainView;
	NSBundle *_bundle;
	NSDictionary *_info;
}
- (id)initWithInfo:(NSDictionary *)info;
- (void)requestRelaunch;
- (IBAction)showPaneHelp:(id)sender;
- (void)paneWillMoveToWindow:(NSWindow *)newWindow;
- (void)paneDidMoveToWindow:(NSWindow *)newWindow;
- (id)initWithBundle:(NSBundle *)bundle;
- (NSView *)mainView;
- (void)paneLoadedByController:(id)controller;
- (NSView *)loadMainView;
- (NSString *)helpPage;
- (void)mainViewDidLoad;
- (void)setInfo:(NSDictionary *)info;
- (void)didReselect;

- (NSBundle *)mainNibBundle;
@end
