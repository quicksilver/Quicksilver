//
//  NDHotKeyEvent_QSMods.h
//  Quicksilver
//
//  Created by Alcor on 8/16/04.

//

#import <Cocoa/Cocoa.h>

#import "NDHotKeyEvent.h"
unsigned int carbonModifierFlagsToCocoaModifierFlags( unsigned int aModifierFlags );
@interface QSHotKeyEvent : NDHotKeyEvent{
	NSString *identifier;
}
- (NSString *)identifier;
- (void)setIdentifier:(NSString *)anIdentifier;
+ (QSHotKeyEvent *)hotKeyWithIdentifier:(NSString *)identifier;
+ (QSHotKeyEvent *)hotKeyWithDictionary:(NSDictionary *)dict;		
@end

@interface NDHotKeyEvent (QSMods)
+ (NDHotKeyEvent *)getHotKeyForKeyCode:(unsigned short)aKeyCode character:(unichar)aChar safeModifierFlags:(unsigned int)aModifierFlags;
@end