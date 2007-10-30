//
//  KeyCombo.h
//
//  Created by Quentin D. Carnicelli on Tue Jun 18 2002.
//  Copyright (c) 2001 Subband inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface KeyCombo : NSObject <NSCopying, NSCoding>
{
	short mKeyCode;
	long mModifiers;
}

+ (id)keyCombo;
+ (id)clearKeyCombo;
+ (id)keyComboWithKeyCode: (short)keycode andModifiers: (long)modifiers;

- (id)initWithKeyCode: (short)keycode andModifiers: (long)modifiers;

- (id)copyWithZone:(NSZone*)zone;
- (BOOL)isEqual:(id)object;

- (short)keyCode;
- (short)modifiers;

- (BOOL)isValid;

- (NSString*)userDisplayRep;
+ (NSDictionary*)keyCodesDictionary;

@end

@interface NSUserDefaults (KeyComboAdditions)

- (void)setKeyCombo: (KeyCombo*)combo forKey: (NSString*)key;
- (KeyCombo*)keyComboForKey: (NSString*)key;

@end
