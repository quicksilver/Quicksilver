//
//  QSProxyObject.m
//  Quicksilver
//
//  Created by Alcor on 1/16/05.

//

#import "QSProxyObject.h"

#import "QSTypes.h"

#import "QSNotifications.h"
#import "QSObject_StringHandling.h"


@implementation QSObject (QSProxyObject)
- (id)proxyProvider {
	NSString *class = [[data objectForKey:QSProxyType] objectForKey:kQSProxyProviderClass];
	
	return [QSReg getClassInstance:class];
}

- (NSArray *)proxyTypes {
	NSArray *array = [[data objectForKey:QSProxyType] objectForKey:kQSProxyTypes]; 	
	if (array) return array;
	return [[self proxyProvider] typesForProxyObject:self];
}

- (id)proxyObject {
	id proxy = nil;
	if ((proxy = [self objectForCache:QSProxyTargetCache]) ) {
		
		return proxy;
	
	} else {
		id provider = [self proxyProvider];
		
		proxy = [provider resolveProxyObject:self];
	
		if ([self isEqual:proxy]) return nil;
		
		//QSLog(@"Proxy: %@", proxy);
		if (proxy)
			[self setObject:proxy forCache:QSProxyTargetCache];
		
		NSTimeInterval interval = 3.0f;
		
		if ([provider respondsToSelector:@selector(cacheTimeForProxy:)])
			interval = [[self proxyProvider] cacheTimeForProxy:self];
		
		[NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(releaseProxy) userInfo:nil repeats:NO];
	}
	return proxy; 	
}

- (id)proxyObjectWithProviderClass:(NSString *)providerClass identifier:(NSString *)ident {
	return nil;
}
@end

@implementation QSProxyObject
- (BOOL)hasChildren {return YES;}
- (NSString *)description {
	return [self identifier];
}
- (id)init {
	if ((self = [super init]) ) {		
		//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(releaseProxy) name:QSReleaseOldCachesNotification object:nil];
		//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(releaseProxy) name:QSReleaseAllCachesNotification object:nil];
	}
	return self;
}
- (NSArray *)types {
	return [self proxyTypes];
}
- (NSImage *)icon {
  NSImage *pIcon = [[self proxyObject] icon]; 
  NSLog(@"proxy icon %@", pIcon);
  return pIcon;
}

- (void)releaseProxy {
	//QSLog(@"release proxy");
	[cache removeObjectForKey:QSProxyTargetCache];
}

- (void)becameSelected {
	[self releaseProxy];
}


- (id)_safeObjectForType:(id)aKey {
	return [[self proxyObject] _safeObjectForType:aKey];
}
- (BOOL)bypassValidation {	

	return [[self proxyProvider] respondsToSelector:@selector(bypassValidation)] && [[self proxyProvider] bypassValidation];
}

- (NSMutableDictionary *)dataDictionary {
	return [[self proxyObject] dataDictionary];
}

- (QSBasicObject *)resolvedObject {return [self proxyObject];}
- (NSString *)stringValue {
	return [(QSObject *)[self resolvedObject] stringValue];
}


- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([super respondsToSelector:aSelector]) return YES;
	if ([[self resolvedObject] respondsToSelector:aSelector]) return YES;
	return NO;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    if ([[self resolvedObject] respondsToSelector:[invocation selector]])
        [invocation invokeWithTarget:[self resolvedObject]];
    else
        [self doesNotRecognizeSelector:[invocation selector]];
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)sel {
    NSMethodSignature *sig = [[self class] instanceMethodSignatureForSelector:sel];
    if (sig) return sig;
    return [[self resolvedObject] methodSignatureForSelector:sel];
}
@end


