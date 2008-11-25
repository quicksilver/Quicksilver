//
//  QSObject_AEConversion.h
//  Quicksilver
//
//  Created by Alcor on 3/20/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QSObject.h"

@interface QSObject (AEConversion)
- (NSAppleEventDescriptor *)AEDescriptor;
+ (QSObject *)objectWithAEDescriptor:(NSAppleEventDescriptor *)desc;

@end
