//
//  NSAppleEventDescriptor+NDAppleScriptObject_QSMods.h
//  Quicksilver
//
//  Created by Alcor on 8/19/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "NSAppleEventDescriptor+NDCoercion.h"
@interface NSAppleEventDescriptor (NDAppleScriptObject_QSMods)

//+ (NSAppleEventDescriptor *)targetDescriptorWithBundleID:(NSString *)bundleID;
+ (NSAppleEventDescriptor *)targetDescriptorWithTypeSignature:(OSType)type;
- (NSAppleEventDescriptor *)AESend;
#warning 64BIT: Inspect use of long
- (NSAppleEventDescriptor *)AESendWithSendMode:(AESendMode)sendMode priority:(AESendPriority)sendPriority timeout:(long) timeOutInTicks;
@end
