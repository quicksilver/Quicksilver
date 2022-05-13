//
//  QSPreferencePane.h
//  Quicksilver
//
//  Created by Alcor on 11/2/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QSPreferencePane : NSObject <NSWindowDelegate>
{
	IBOutlet NSWindow *_window;
	IBOutlet NSView *_initialKeyView;
	IBOutlet NSView *_firstKeyView;
	IBOutlet NSView *_lastKeyView;
	NSView *_mainView;
	NSBundle *_bundle;
	NSDictionary *_info;
}

@property (nonatomic, strong) NSDictionary *info;

- (id)initWithInfo:(NSDictionary *)info;
- (void)requestRelaunch;
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
- (id)preferencesSplitView;
- (NSString *)name;
- (NSString *)description;

@end
