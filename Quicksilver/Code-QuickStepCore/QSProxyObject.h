//
//  QSProxyObject.h
//  Quicksilver
//
//  Created by Alcor on 1/16/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QSCore/QSObject.h>

#define kQSProxyProvider @"provider"
#define kQSProxyProviderClass @"providerClass"
#define kQSProxyTypes @"types"
#define kQSProxyIdentifier @"identifier"

#define QSProxyType @"qs.proxy"

#define QSProxyTargetCache @"proxyTarget"
#define kQSDefaultProxyCacheTime 2.0f

@protocol QSProxyObjectProvider
- (id)resolveProxyObject:(id)proxy;
@optional
- (NSArray *)typesForProxyObject:(id)proxy;
- (BOOL)bypassValidation;
- (NSTimeInterval)cacheTimeForProxy:(id)proxy;
@end

@interface QSProxyObject : QSObject
+ (instancetype)proxyWithDictionary:(NSDictionary*)dictionary;
+ (instancetype)proxyWithIdentifier:(NSString*)identifier;

- (NSObject <QSProxyObjectProvider> *)proxyProvider;
- (QSObject *)proxyObject;

- (void)releaseProxy:(NSNotification *)notif;

- (BOOL)bypassValidation;
- (NSArray *)proxyTypes;
@end

@interface QSGlobalSelectionProxyProvider : NSObject
- (QSObject *)proxy;
@end
