//
//  QSDonationController.m
//  Quicksilver
//
//  Created by Patrick Robertson on 05/03/2022.
//

#import "QSDonationController.h"
#import "QSPaths.h"

static QSDonationController *_controller;

@implementation QSDonationController

+ (QSDonationController * )sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _controller = [[[self class] allocWithZone:nil] init];
    });
    return _controller;
}

- (BOOL)openDonationPage {
	return [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kDonatePageURL]];
}

@end
