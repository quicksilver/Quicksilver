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

#pragma mark Proxy Cache Time

@interface QSProxyObject ()
- (NSMutableDictionary*)proxyDict;
@end

@implementation QSProxyObject
+ (id)proxyWithDictionary:(NSDictionary*)dictionary {
    return [[self alloc] initWithDictionary:dictionary];
}

+ (id)proxyWithIdentifier:(NSString*)identifier {
    id obj = [QSLib objectWithIdentifier:identifier];
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
	id target = nil;
	if (target = [self objectForCache:QSProxyTargetCache])
		return target;
    
    id provider = [self proxyProvider];        
    target = [provider resolveProxyObject:self];
    
    if ([self isEqual:target]) return nil;
    
	// NSLog(@"Proxy: %@", target);
    if (target) {
        [self setObject:target forCache:QSProxyTargetCache];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(releaseProxy:) name:QSInterfaceDeactivatedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(releaseProxy:) name:QSCommandExecutedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(objectIconModified:) name:QSObjectIconModified object:target];
    }
	return target;
}


- (void)releaseProxy:(NSNotification *)notif {
	if ([[notif name] isEqualToString:QSInterfaceDeactivatedNotification]) {
		NSString *reason = [[notif userInfo] objectForKey:kQSInterfaceDeactivatedReason];
		if ([reason isEqualToString:@"execution"]) {
			// if the interface is hiding from running a command, keep the cached value
			// it will get cleared after the command executes
			return;
		}
	}
	[cache removeObjectForKey:QSProxyTargetCache];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:QSInterfaceDeactivatedNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:QSCommandExecutedNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:QSObjectIconModified object:[cache objectForKey:QSProxyTargetCache]];
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
    return [super enabled];
}

- (BOOL)hasChildren {return YES;}

- (NSArray *)types {
	return [self proxyTypes];
}

- (BOOL)bypassValidation {
	return [[self proxyProvider] respondsToSelector:@selector(bypassValidation)] && [[self proxyProvider] bypassValidation];
}

- (QSObject *)resolvedObject {return [self proxyObject];}

- (QSObject *)cachedProxyTarget
{
	return [self objectForCache:QSProxyTargetCache];
}

- (NSString *)stringValue {
	return [[self resolvedObject] stringValue];
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
    [self setIcon:[[self proxyObject] icon]];
}

- (BOOL)isProxyObject
{
    return YES;
}

- (id)_safeObjectForType:(id)aKey {
    id object = [data objectForKey:aKey];
    if (!object) {
        object = [[self resolvedObject] _safeObjectForType:aKey];
    }
    return object;
}

- (BOOL)loadIcon
{
    NSString *namedIcon = [self objectForMeta:kQSObjectIconName];
    if (!namedIcon || [namedIcon isEqualToString:@"ProxyIcon"]) {
        // use the resolved object's icon instead
        QSObject *resolved = [self resolvedObject];
        [self setIcon:[resolved icon]];
        [self setIconLoaded:YES];
	    [resolved loadIcon];
        return YES;
    }
    return [super loadIcon];
}
@end
