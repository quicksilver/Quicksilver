#import "QSFSBrowserMediator.h"

@implementation QSRegistry (QSFSBrowserMediator)
- (NSString *)FSBrowserMediatorID {
	return [[NSUserDefaults standardUserDefaults] stringForKey:kQSFSBrowserMediators];
}
- (id <QSFSBrowserMediator>)FSBrowserMediator {
	id <QSFSBrowserMediator> mediator = [prefInstances objectForKey:kQSFSBrowserMediators];
	if (!mediator) {
		mediator = [self instanceForKey:[self FSBrowserMediatorID] inTable:kQSFSBrowserMediators];
		if (mediator)
			[prefInstances setObject:mediator forKey:kQSFSBrowserMediators];
		//else NSLog(@"Mediator not found %@", [[NSUserDefaults standardUserDefaults] stringForKey:kQSFSBrowserMediators]);
	}
	return mediator;
}
@end
