//
//  QSGlobalSelectionProvider.h
//  Quicksilver
//
//  Created by Alcor on 1/21/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@protocol QSGlobalSelectionProvider
- (QSObject *)currentSelectionForApplication:(NSString *)bundleID;

@end

@interface QSGlobalSelectionProvider : NSObject <QSProxyObjectProvider>

@property NSTimeInterval failDate;
@property NSDictionary *currentAppSelectionProxyInfo;
@property id currentAppSelectionProxyProvider;

+ (instancetype)sharedInstance;
- (id)currentSelection;
+(id)currentSelection;

@end
