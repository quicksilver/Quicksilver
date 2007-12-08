//
//  QSProxyObject.h
//  Quicksilver
//
//  Created by Alcor on 1/16/05.

//

#import <Cocoa/Cocoa.h>

#define kQSProxyProvider @"provider"
#define kQSProxyProviderClass @"providerClass"
#define kQSProxyTypes @"types"
#define QSProxyType @"qs.proxy"

#define QSProxyTargetCache @"proxyTarget"

#import "QSObject.h"
@protocol QSProxyObjectProvider
-(id)resolveProxyObject:(id)proxy;
-(NSArray *)typesForProxyObject:(id)proxy;
-(NSTimeInterval)cacheTimeForProxy:(id)proxy;
@end

@interface QSProxyObject : QSObject

- (NSArray *)types;

- (void)releaseProxy;
- (id)_safeObjectForType:(id)aKey;


-(BOOL)bypassValidation;
@end

@interface QSObject (QSProxyObject)
- (id)proxyObject;
- (id)proxyProvider;
- (NSArray *)proxyTypes;
//- (id)proxyObjectWithProviderClass:(NSString *)providerClass;
//- (QSObject *)resolvedObject;
@end



@interface QSGlobalSelectionProxyProvider : NSObject
- (QSObject *)proxy;
@end
