#import "QSNotifyMediator.h"
#import "QSResourceManager.h"

BOOL QSShowAppNotifWithAttributes(NSString *type, NSString *title, NSString *message) {
    QSShowNotifierWithAttributes([NSDictionary dictionaryWithObjectsAndKeys:type, QSNotifierType, [QSResourceManager imageNamed:kQSBundleID], QSNotifierIcon, title, QSNotifierTitle, message, QSNotifierText, nil]);
    return YES;
}

BOOL QSShowNotifierWithAttributes(NSDictionary *attributes) {
	if ([attributes count]) {
		[[QSReg preferredNotifier] displayNotificationWithAttributes:attributes];
		return YES;
	} else
		return NO;
}

@implementation QSRegistry (QSNotifier)
- (id <QSNotifier>) preferredNotifier {
	id <QSNotifier> mediator = [prefInstances objectForKey:kQSNotifiers];
	if (!mediator) {
        NSString *userPref = [[NSUserDefaults standardUserDefaults] stringForKey:kQSNotifiers];
        if (![NSApplication isMountainLion] && [userPref isEqualToString:@"com.apple.NotificationCenter"]) {
            // drop10.7: ugly hack - when Notification Center becomes the default, remove this
            mediator = [self instanceForKey:@"com.blacktree.Quicksilver" inTable:kQSNotifiers];
        } else {
            mediator = [self instanceForKey:userPref inTable:kQSNotifiers];
        }
		if (mediator)
			[prefInstances setObject:mediator forKey:kQSNotifiers];
	}
	return mediator;
}
@end

@implementation QSNotifyScriptCommand
- (id)performDefaultImplementation {
	NSDictionary *args = [self evaluatedArguments];
	NSString *title = [self directParameter];
	NSString *text = [args objectForKey:@"text"];
	id imageStuff = [args objectForKey:@"imageName"];
	if (!imageStuff) imageStuff = [args objectForKey:@"imageData"];
	NSImage *image = nil;
	if ([imageStuff isKindOfClass:[NSString class]])
		image = [QSResourceManager imageNamed:imageStuff];
	else if ([imageStuff isKindOfClass:[NSData class]])
		image = [[[NSImage alloc] initWithData:imageStuff] autorelease];
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:title forKey:QSNotifierTitle];
	if (image) [dict setObject:image forKey:QSNotifierIcon];
	if (text) [dict setObject:text forKey:QSNotifierText];
	QSShowNotifierWithAttributes(dict);
	return nil;
}
@end
