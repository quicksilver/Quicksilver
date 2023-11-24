//
// QSInterfaceMediator.m
// Quicksilver
//
// Created by Alcor on 7/28/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "QSInterfaceMediator.h"

@implementation QSRegistry (QSCommandInterface)
- (NSString *)preferredCommandInterfaceID {
	NSString *key = [[NSUserDefaults standardUserDefaults] stringForKey:kQSCommandInterfaceControllers];
	if (![[self tableNamed:kQSCommandInterfaceControllers] objectForKey:key]) key = @"QSBezelInterfaceController";
	return key;
}

- (QSInterfaceController*)preferredCommandInterface {
	QSInterfaceController *mediator = [prefInstances objectForKey:kQSCommandInterfaceControllers];
	if (!mediator) {
		mediator = [self instanceForKey:[self preferredCommandInterfaceID] inTable:kQSCommandInterfaceControllers];
		if (mediator) {
			[prefInstances setObject:mediator forKey:kQSCommandInterfaceControllers];
        } else {
            QSShowNotifierWithAttributes([NSDictionary dictionaryWithObjectsAndKeys:@"QSNotification", QSNotifierType, [QSResourceManager imageNamed:kQSBundleID], QSNotifierIcon, NSLocalizedString(@"Interface Changed", nil), QSNotifierTitle, NSLocalizedString(@"Interface could not be loaded. Switching to Bezel",nil),  QSNotifierText, nil]);
            mediator = [self instanceForKey:@"QSBezelnterfaceController" inTable:kQSCommandInterfaceControllers];
            [prefInstances setObject:mediator forKey:kQSCommandInterfaceControllers];
        }
	}
	return mediator;
}
@end
