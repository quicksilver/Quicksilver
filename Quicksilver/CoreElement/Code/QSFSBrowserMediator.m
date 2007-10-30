

#import "QSFSBrowserMediator.h"


@implementation QSRegistry (QSFSBrowserMediator)
- (NSString *)FSBrowserMediatorID{
	NSString *key=[[NSUserDefaults standardUserDefaults] stringForKey:kQSFSBrowserMediators];
	//if (!key)key=defaultMailClientID();
	return key;
}
- (id <QSFSBrowserMediator>)FSBrowserMediator{
	id <QSFSBrowserMediator> mediator=[prefInstances objectForKey:kQSFSBrowserMediators];
	
	if (!mediator){
		mediator=[self instanceForKey:[self FSBrowserMediatorID]
					 inTable:kQSFSBrowserMediators];
		if (mediator)
			[prefInstances setObject:mediator forKey:kQSFSBrowserMediators];
		//else QSLog(@"Mediator not found %@",[[NSUserDefaults standardUserDefaults] stringForKey:kQSFSBrowserMediators]);
	}
	return mediator;
}


@end