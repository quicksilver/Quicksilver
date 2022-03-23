//
//  QSDonationController.h
//  Quicksilver
//
//  Created by Patrick Robertson on 05/03/2022.
//

#import <Foundation/Foundation.h>
#import "NSApplication_BLTRExtensions.h"

NS_ASSUME_NONNULL_BEGIN

@interface QSDonationController : NSObject

+ (QSDonationController * )sharedInstance;
- (BOOL)openDonationPage;
- (BOOL)checkDonationStatus:(QSApplicationLaunchStatusFlags)launchStatus;

@end

NS_ASSUME_NONNULL_END
