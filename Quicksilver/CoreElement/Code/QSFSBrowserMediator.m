

#import "QSFSBrowserMediator.h"

#define kQSFSBrowserMediators @"QSFSBrowserMediators"

@implementation QSRegistry (QSFSBrowserMediator)
- (NSString *) FSBrowserMediatorID {
	NSString *key = [[NSUserDefaults standardUserDefaults] stringForKey:kQSFSBrowserMediators];
	//if ( !key ) key = defaultMailClientID();
    if( !key ) key = @"com.apple.finder";
	return key;
}

- (id <QSFSBrowserMediator>) FSBrowserMediator {
	id <QSFSBrowserMediator> mediator = [prefInstances objectForKey:kQSFSBrowserMediators];
	
	if ( !mediator ) {
		mediator = [self instanceForKey:[self FSBrowserMediatorID]
                                inTable:kQSFSBrowserMediators];
		if ( mediator )
			[prefInstances setObject:mediator forKey:kQSFSBrowserMediators];
	}
	return mediator;
}


@end