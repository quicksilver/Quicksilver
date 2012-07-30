//
//  QSGrowlNotifier.m
//  QSGrowlNotifier
//
//  Created by Nicholas Jitkoff on 7/12/04.
//  Copyright __MyCompanyName__ 2004. All rights reserved.
//

#import <QSCore/QSNotifyMediator.h>
#import "QSGrowlNotifier.h"
#import <Growl/GrowlApplicationBridge.h>

#define QSGrowlNotification			@"Quicksilver Notification"
#define QSiTunesNotification		@"iTunes Notification"

Class GAB;

@implementation QSGrowlNotifier
+ (void) initialize {
	[super initialize];
	NSBundle *plugin = [NSBundle bundleForClass:self];
	NSString *path = [[plugin privateFrameworksPath] stringByAppendingPathComponent:@"Growl.framework"];
	NSBundle *bundle = [NSBundle bundleWithPath:path];
	if (path && [bundle load]) {
		GAB = NSClassFromString(@"GrowlApplicationBridge");
	} else {
		GAB = nil;
	}
}

- (id) init {
	if (self = [super init]) {
		[GAB setGrowlDelegate:self];
	}
	return self;
}

- (NSDictionary *) registrationDictionaryForGrowl {
	NSArray *notifications = [NSArray arrayWithObjects:QSGrowlNotification, QSiTunesNotification, nil];
	return [NSDictionary dictionaryWithObjectsAndKeys:
		notifications, GROWL_NOTIFICATIONS_ALL,
		notifications, GROWL_NOTIFICATIONS_DEFAULT,
		nil];
}

- (NSString *) applicationNameForGrowl {
	return @"Quicksilver";
}

- (void) displayNotificationWithAttributes:(NSDictionary *)attributes {
	
	NSString *type = QSGrowlNotification;
	if ([[attributes objectForKey:QSNotifierType] isEqualToString:@"QSiTunesTrackChangeNotification"]) {
		type = QSiTunesNotification;
	}
	
	NSString *text = [attributes objectForKey:QSNotifierText];
	if (!text)
		text = @"";
	
	[GAB notifyWithTitle:[attributes objectForKey:QSNotifierTitle]
                 description:text
            notificationName:type
                    iconData:[[attributes objectForKey:QSNotifierIcon] TIFFRepresentation]
                    priority:0
                    isSticky:NO
                clickContext:nil
                  identifier:(type == QSiTunesNotification ? QSiTunesNotification : nil)];
}

@end