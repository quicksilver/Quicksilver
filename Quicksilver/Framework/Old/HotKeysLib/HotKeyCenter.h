//
//  HotKeyCenter.h
//
//  Created by Quentin D. Carnicelli on Thu Jun 06 2002.
//  Copyright (c) 2002 Subband inc.. All rights reserved.
//
//  Feedback welcome at qdc@subband.com
//  This code is provided AS IS, so don't hurt yourself with it...
//

#import <AppKit/AppKit.h>
#import "KeyCombo.h"

@interface HotKeyCenter : NSObject
{
	BOOL mEnabled;
	NSMutableDictionary* mHotKeys;
}

+ (id)sharedCenter;

- (BOOL)addHotKey: (NSString*)name combo:(KeyCombo*)combo target: (id)target action:(SEL)action;
- (void)removeHotKey: (NSString*)name;

- (NSArray*)allNames;
- (KeyCombo*)keyComboForName: (NSString*)name;

- (void)setEnabled: (BOOL)enabled;
- (BOOL)enabled;

- (void)sendEvent: (NSEvent*)event;

@end
