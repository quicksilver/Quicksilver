//
//  QSDonationController.h
//  Quicksilver
//
//  Created by Patrick Robertson on 05/03/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QSDonationController : NSObject

+ (QSDonationController * )sharedInstance;
- (BOOL)openDonationPage;

@end

NS_ASSUME_NONNULL_END
