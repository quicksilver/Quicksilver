//
//  QSConsoleNotifier.m
//  Quicksilver
//
//  Created by Alcor on 7/8/04.

//

#import "QSConsoleNotifier.h"


@implementation QSConsoleNotifier

- (void) displayNotificationWithAttributes:(NSDictionary *)attributes{
	
	NSString *log=[NSString stringWithFormat:@"Console Notification\r%@",[attributes objectForKey:QSNotifierTitle]];
	if ([attributes objectForKey:QSNotifierText])
		log=[log stringByAppendingFormat:@":\r%@",[attributes objectForKey:QSNotifierText]];
	QSLog(@"%@\r",log);
}

@end
