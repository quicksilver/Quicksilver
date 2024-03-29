//
//  QSHotKeyEvent.h
//  Quicksilver
//
//  Created by Alcor on 8/16/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "NDHotKeyEvent.h"
NSUInteger carbonModifierFlagsToCocoaModifierFlags( NSUInteger aModifierFlags );
@interface QSHotKeyEvent : NDHotKeyEvent {
	NSString *identifier;
}
- (NSString *)identifier;
- (NSArray *)identifiers;
- (void)setIdentifier:(NSString *)anIdentifier;
- (void)typeHotkey;
+ (QSHotKeyEvent *)hotKeyWithIdentifier:(NSString *)identifier;
@end
