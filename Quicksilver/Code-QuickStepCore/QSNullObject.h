//
//  QSNullObject.h
//  Quicksilver
//
//  Created by Alcor on 7/29/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QSObject.h"

@interface QSNullObject : QSBasicObject {}
@end

@interface QSBasicObject (NullObject)
+(QSBasicObject *)nullObject;

@end
