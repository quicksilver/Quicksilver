//
//  QSInterfaceMediator.h
//  Quicksilver
//
//  Created by Alcor on 7/28/04.

//

#import <Cocoa/Cocoa.h>
#import <QSElements/QSElements.h>

#define QSPreferredCommandInterface [QSReg preferredCommandInterface]
@class QSInterfaceController;
#define kQSCommandInterfaceControllers @"QSCommandInterfaceControllers"

@interface QSRegistry (QSCommandInterface)
- (NSString *)preferredCommandInterfaceID;

- (QSInterfaceController *)preferredCommandInterface;
@end
