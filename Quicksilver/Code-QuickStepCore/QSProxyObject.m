//
// QSProxyObject.m
// Quicksilver
//
// Created by Alcor on 1/16/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "QSProxyObject.h"
#import "QSRegistry.h"
#import "QSTypes.h"

#import "QSNotifications.h"
#import "QSObject_StringHandling.h"

@interface QSProxyObject ()
- (NSMutableDictionary*)proxyDict;
@end

@implementation QSProxyObject
+ (id)proxyWithDictionary:(NSDictionary*)dictionary {
    return [[[self alloc] initWithDictionary:dictionary] autorelease];
}

+ (id)proxyWithIdentifier:(NSString*)identifier {
    id obj = [QSObject objectWithIdentifier:identifier];
    if (!obj) {
        id rep = [[QSReg tableNamed:@"QSProxies"] objectForKey:identifier];
        if (rep)
            obj = [QSProxyObject objectWithDictionary:rep];
    }
    return obj;
}

- (id)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if (self) {
        [[self proxyDict] setDictionary:dictionary];
        [self setPrimaryType:QSProxyType];
    }
    return self;
}

- (NSMutableDictionary*)proxyDict {
    id dict = [self objectForType:QSProxyType];
    if (!dict) [self setObject:(dict = [NSMutableDictionary dictionary])
                       forType:QSProxyType];
    return dict;
}

- (id)proxyObjectWithProviderClass:(NSString *)providerClass identifier:(NSString *)ident {
	return nil;
}

- (NSObject <QSProxyObjectProvider> *)proxyProvider {
	NSString *class = [[data objectForKey:QSProxyType] objectForKey:kQSProxyProviderClass];
	return [QSReg getClassInstance:class];
}

- (QSObject*)proxyObject {
	id proxy = nil;
	if (proxy = [self objectForCache:QSProxyTargetCache])
		return proxy;
    
    id provider = [self proxyProvider];        
    proxy = [provider resolveProxyObject:self];
    
    if ([self isEqual:proxy]) return nil;
    
    //NSLog(@"Proxy: %@", proxy);
    if (proxy) {
        [self setObject:proxy forCache:QSProxyTargetCache];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(objectIconModified:) name:QSObjectIconModified object:proxy];
    }
    
    NSTimeInterval interval = 3.0f;
    
    if ([provider respondsToSelector:@selector(cacheTimeForProxy:)])
        interval = [[self proxyProvider] cacheTimeForProxy:self];
    
    [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(releaseProxy) userInfo:nil repeats:NO];
	return proxy;
}


- (void)releaseProxy {
	//NSLog(@"release proxy");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:QSObjectIconModified object:[cache objectForKey:QSProxyTargetCache]];
	[cache removeObjectForKey:QSProxyTargetCache];
}

- (NSArray *)proxyTypes {
	NSArray *array = [[data objectForKey:QSProxyType] objectForKey:kQSProxyTypes];
	if (array) return array;
	return [[self proxyProvider] typesForProxyObject:self];
}

- (BOOL)enabled {
    NSNumber *e = [[self proxyDict] objectForKey:@"enabled"];
    if (e)
        return [e boolValue];
    return YES;
}

- (BOOL)hasChildren {return YES;}

- (NSArray *)types {
	return [self proxyTypes];
}

- (BOOL)bypassValidation {
	return [[self proxyProvider] respondsToSelector:@selector(bypassValidation)] && [[self proxyProvider] bypassValidation];
}

- (QSBasicObject *)resolvedObject {return [self proxyObject];}

- (NSString *)stringValue {
	return [(QSObject*)[self resolvedObject] stringValue];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
	if ([super respondsToSelector:aSelector]) return YES;
	if ([[self resolvedObject] respondsToSelector:aSelector]) return YES;
	return NO;
}   

- (void)forwardInvocation:(NSInvocation *)invocation {
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

- (void)objectIconModified:(NSNotification *)notif
{
    [self updateIcon:[[self proxyObject] icon]];
}
@end
