//
//  QSCollection.h
//  Quicksilver
//
//  Created by Alcor on 8/6/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "QSObject.h"

@interface QSCollection : QSBasicObject {
	NSMutableArray *array;
//	QSObject *objectValue;
}
- (NSUInteger) count;
@end
