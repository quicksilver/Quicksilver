//
//  QSController.h
//  Crucible
//
//  Created by Etienne on 30/12/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSObject (QSController)
- (NSMenu *)statusMenuWithQuit;
- (QSInterfaceController *)interfaceController;
@end
