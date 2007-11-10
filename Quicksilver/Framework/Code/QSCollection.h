//
//  QSCollection.h
//  Quicksilver
//
//  Created by Alcor on 8/6/04.

//

#import <Cocoa/Cocoa.h>
#import "QSObject.h"

@interface QSCollection : QSBasicObject {
	NSMutableArray *array;
	QSObject *objectValue;
}

-(unsigned)count;

@end
