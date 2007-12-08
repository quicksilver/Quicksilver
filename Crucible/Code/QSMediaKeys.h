/*
 *  QSMediaKeys.h
 *  Quicksilver
 *
 *  Created by Alcor on 12/29/04.
 *  Copyright 2004 Blacktree. All rights reserved.
 *
 */

#import <IOKit/IOKitLib.h>

#import <IOKit/hidsystem/IOHIDLib.h>
#import <IOKit/hidsystem/ev_keymap.h>
#import <IOKit/IOMessage.h>

void HIDPostSysDefinedKey(const UInt8 sysKeyCode );
void HIDPostAuxKey(const UInt8 auxKeyCode );