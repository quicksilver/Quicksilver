//
//  QSHotKeyEvent.h
//  Quicksilver
//
//  Created by Alcor on 8/16/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "NDHotKeyEvent.h"

@interface QSHotKeyEvent : NDHotKeyEvent

@property (retain) NSString *identifier;

+ (instancetype)hotKeyWithIdentifier:(NSString *)identifier;
+ (instancetype)hotKeyWithDictionary:(NSDictionary *)dict;
- (NSArray *)identifiers;

- (void)typeHotkey;
@end

@interface NDHotKeyEvent (QSMods)
+ (id)getHotKeyForKeyCode:(unsigned short)aKeyCode character:(unichar)aChar safeModifierFlags:(NSUInteger)aModifierFlags DEPRECATED_ATTRIBUTE;
@end
