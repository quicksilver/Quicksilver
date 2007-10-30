#import "QSNotifyMediator.h"
#import "QSResourceManager.h"

BOOL QSShowNotifierWithAttributes(NSDictionary *attributes){
	if (![attributes count])return NO;
	[[QSReg preferredNotifier]displayNotificationWithAttributes:attributes];
	return YES;
}

@implementation QSRegistry (QSNotifier)
- (id <QSNotifier>)preferredNotifier{
	id <QSNotifier> mediator=[prefInstances objectForKey:kQSNotifiers];
	if (!mediator){
		//QSLog(@"get");
		mediator=[self instanceForKey:[[NSUserDefaults standardUserDefaults] stringForKey:kQSNotifiers]
							  inTable:kQSNotifiers];
		if (mediator)
			[prefInstances setObject:mediator forKey:kQSNotifiers];
	}
	return mediator;
}
@end

@implementation QSNotifyScriptCommand
- (id)performDefaultImplementation {
	NSDictionary *args = [self evaluatedArguments];
    //NSString *titleString = [args objectForKey:@"title"];
	//QSLog(@"string %@ %@",args,[args objectForKey:@"imageName"]);
	NSString *title=[self directParameter];
	NSString *text=[args objectForKey:@"text"];
	id imageStuff=[args objectForKey:@"imageName"];
	if (!imageStuff)imageStuff=[args objectForKey:@"imageData"];
	NSImage *image=nil;
	
	if ([imageStuff isKindOfClass:[NSString class]])
		image=[QSResourceManager imageNamed:imageStuff];

	else if ([imageStuff isKindOfClass:[NSData class]])
		image=[[[NSImage alloc]initWithData:imageStuff]autorelease];
	
	//QSLog(@"imageStuff %@ %@",image, args);
	
	NSMutableDictionary *dict=[NSMutableDictionary dictionaryWithObject:title forKey:QSNotifierTitle];
	if (image)[dict setObject:image forKey:QSNotifierIcon];
	if (text)[dict setObject:text forKey:QSNotifierText];
	//QSLog(@"dict %@",dict);
	QSShowNotifierWithAttributes(dict);
								 
    return nil;
}
@end