//
//  QSHotKeyTriggerManager.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on Sun Jun 13 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QSFoundation/QSFoundation.h>
#import <QSCore/QSCore.h>
#import <Foundation/Foundation.h>
#import <QSCore/QSTriggerManager.h>

@class QSHotKeyField;
@interface QSHotKeyTriggerManager : QSTriggerManager {
	IBOutlet QSHotKeyField *hotKeyField;
}
- (NSEvent *)nextHotKeyUpEventUntilDate:(NSDate *)date;
- (void)setHotKey:(NSDictionary *)dict;
@end
