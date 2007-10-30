//
//  QSInterfaceMediator.h
//  Quicksilver
//
//  Created by Alcor on 7/28/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QSRegistry.h"
#define QSPreferredCommandInterface [QSReg preferredCommandInterface]
@class QSInterfaceController;
#define kQSCommandInterfaceControllers @"QSCommandInterfaceControllers"

@interface QSRegistry (QSCommandInterface)
- (NSString *)preferredCommandInterfaceID;

- (QSInterfaceController *)preferredCommandInterface;
@end
