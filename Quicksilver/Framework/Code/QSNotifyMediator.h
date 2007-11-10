//
//  QSNotificationDisplay.h
//  Quicksilver
//
//  Created by Alcor on 6/24/04.

//

#define QSNotifierStyle @"style"
#define QSNotifierIcon @"icon"
#define QSNotifierTitle @"title"
#define QSNotifierText @"text"
#define QSNotifierDetails @"details"
#define QSNotifierType @"type"
#define QSNotifierLocation @"location"
#define QSNotifierDuration @"duration"
#define QSNotifierAppearDuration @"appearDuration"
#define QSNotifierDisappearDuration @"disappearDuration"

#define kQSNotifiers @"QSNotifiers"

//



#import <Cocoa/Cocoa.h>

BOOL QSShowNotifierWithAttributes(NSDictionary *attributes);

@protocol QSNotifier
- (void) displayNotificationWithAttributes:(NSDictionary *)attributes;
@end

@interface QSRegistry (QSNotifier)
- (id <QSNotifier>)preferredNotifier;
@end


@interface QSNotifyScriptCommand : NSScriptCommand
@end
