//
//  QSObject_AEConversion.h
//  Quicksilver
//
//  Created by Alcor on 3/20/05.

//

#import <Cocoa/Cocoa.h>
#import <QSCrucible/QSObject.h>

@protocol QSObjectHandler_AEConversion
- (NSAppleEventDescriptor *)AEDescriptorForObject:(QSObject*)object;
- (QSObject *)objectWithAEDescriptor:(NSAppleEventDescriptor *)descriptor;
@end

@interface QSObject (AEConversion)
+ (QSObject *)objectWithAEDescriptor:(NSAppleEventDescriptor *)desc types:(NSArray *)types;
- (QSObject *)initWithAEDescriptor:(NSAppleEventDescriptor *)desc;
- (NSAppleEventDescriptor *)AEDescriptor;
@end
