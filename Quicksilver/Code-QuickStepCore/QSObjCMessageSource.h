//
//  QSObjCMessageSource.h
//  Quicksilver
//
//  Created by Alcor on 8/14/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "QSObject.h"

#define QSObjCMessageType @"qs.ObjCMessage"
#define kQSObjCMessageAction @"action"
#define kQSObjCMessageTargetClass @"target"
#define kQSObjCMessageSendToClass @"classMethod"
#define kQSObjCMessageArgumentAction @"argumentAction"

@interface QSObjCMessageSource : NSObject {
	NSMutableArray *messageArray;
}
@end


@interface QSObject (ObjCMessaging)

+ (QSObject *)messageObjectWithInfo:(NSDictionary *)dictionary identifier:(NSString *)identifier;
+ (QSObject *)messageObjectWithTargetClass:(NSString *)class selectorString:(NSString *)selector;
@end
