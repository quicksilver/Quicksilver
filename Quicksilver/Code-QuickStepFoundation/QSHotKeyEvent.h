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
- (void)setIdentifier:(NSString *)anIdentifier;
+ (QSHotKeyEvent *)hotKeyWithIdentifier:(NSString *)identifier;
+ (QSHotKeyEvent *)hotKeyWithDictionary:(NSDictionary *)dict;
@end

@interface NDHotKeyEvent (QSMods)
+ (id)getHotKeyForKeyCode:(unsigned short)aKeyCode character:(unichar)aChar safeModifierFlags:(NSUInteger)aModifierFlags;
@end
