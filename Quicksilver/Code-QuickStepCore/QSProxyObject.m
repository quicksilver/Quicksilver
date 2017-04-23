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

- (instancetype)init {
	self = [super init];
	if (!self) return nil;

	self.data[QSProxyType] = [NSMutableDictionary dictionary];

	return self;
}

- (id)initWithDictionary:(NSDictionary*)dictionary {
    self = [self init];
	if (!self) return nil;

	[self.proxyDict setDictionary:dictionary];
	self.primaryType = QSProxyType;

    return self;
}

- (NSMutableDictionary *)proxyDict {
	return self.data[QSProxyType];
}

- (id)proxyObjectWithProviderClass:(NSString *)providerClass identifier:(NSString *)ident {
	return nil;
}

- (NSObject <QSProxyObjectProvider> *)proxyProvider {
	NSString *class = [self objectForType:QSProxyType][kQSProxyProviderClass];
	return [QSReg getClassInstance:class];
}

- (QSObject *)proxyObject {
	id proxy = nil;
	if (proxy = [self objectForCache:QSProxyTargetCache])
		return proxy;
    
    id provider = self.proxyProvider;
    proxy = [provider resolveProxyObject:self];
    
    if ([self isEqual:proxy]) return nil;
    
    //NSLog(@"Proxy: %@", proxy);
    if (proxy) {
        [self setObject:proxy forCache:QSProxyTargetCache];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(releaseProxy:) name:QSInterfaceDeactivatedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(releaseProxy:) name:QSCommandExecutedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(objectIconModified:) name:QSObjectIconModified object:proxy];
    }
	return proxy;
}


- (void)releaseProxy:(NSNotification *)notif {
	if ([notif.name isEqualToString:QSInterfaceDeactivatedNotification]) {
		NSString *reason = notif.userInfo[kQSInterfaceDeactivatedReason];
		if ([reason isEqualToString:@"execution"]) {
			// if the interface is hiding from running a command, keep the cached value
			// it will get cleared after the command executes
			return;
		}
	}

	/* Release our proxied object (and observations) so we refresh it next time */
	self.cache[QSProxyTargetCache] = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self name:QSObjectIconModified object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:QSInterfaceDeactivatedNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:QSCommandExecutedNotification object:nil];
}

- (NSArray *)proxyTypes {
	NSArray *array = self.proxyDict[kQSProxyTypes];
	if (array) return array;
	return [self.proxyProvider typesForProxyObject:self];
}

- (BOOL)enabled {
    NSNumber *e = self.proxyDict[@"enabled"];
    if (e)
        return [e boolValue];
    return YES;
}

- (BOOL)hasChildren {return YES;}

- (NSArray *)types {
	return self.proxyTypes;
}

- (BOOL)bypassValidation {
	return [self.proxyProvider respondsToSelector:@selector(bypassValidation)] && [self.proxyProvider bypassValidation];
}

- (QSObject *)resolvedObject {return self.proxyObject; }

- (NSString *)stringValue {
	return [self.resolvedObject stringValue];
}

- (BOOL)respondsToSelector:(SEL)aSelector {
	if ([super respondsToSelector:aSelector]) return YES;
	if ([self.resolvedObject respondsToSelector:aSelector]) return YES;
	return NO;
}   

- (void)forwardInvocation:(NSInvocation *)invocation {
	if ([self.resolvedObject respondsToSelector:invocation.selector])
		[invocation invokeWithTarget:self.resolvedObject];
	else
		[self doesNotRecognizeSelector:[invocation selector]];
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)sel {
	NSMethodSignature *sig = [[self class] instanceMethodSignatureForSelector:sel];
	if (sig) return sig;
	return [self.resolvedObject methodSignatureForSelector:sel];
}

- (void)objectIconModified:(NSNotification *)notif {
    self.icon = self.proxyObject.icon;
}

- (BOOL)isProxyObject { return YES; }

- (id)_safeObjectForType:(id)aKey {
    id object = self.data[aKey];
    if (!object) {
        object = [self.resolvedObject _safeObjectForType:aKey];
    }
    return object;
}

- (BOOL)loadIcon {
    NSString *namedIcon = [self objectForMeta:kQSObjectIconName];
    if (!namedIcon || [namedIcon isEqualToString:@"ProxyIcon"]) {
        // use the resolved object's icon instead
		return [self.resolvedObject loadIcon];
    }
    return [super loadIcon];
}
@end
