//
//  QSCollection.h
//  Quicksilver
//
//  Created by Alcor on 8/6/04.

//

#import <Cocoa/Cocoa.h>
#import <QSCrucible/QSObject.h>

/*
 * This class manages collection of QSObjects (objects created using the comma trick)
 * TODO: Fast-enumeration.
 */

@interface QSCollection : QSBasicObject {
	NSMutableArray *array;
	QSObject *objectValue;
}
+ (id)collection;
+ (id)collectionWithObjects:(id <QSObject>)objects, ...;
+ (id)collectionWithObject:(id <QSObject>)object;
+ (id)collectionWithArray:(NSArray *)objects;

- (id <QSObject>)objectAtIndex:(NSUInteger)index;
- (void)addObject:(id <QSObject>)object;
- (void)addObjectsFromArray:(NSArray *)array;
- (void)removeObject:(id <QSObject>)object;
- (void)removeLastObject;
- (void)removeAllObjects;
- (BOOL)containsObject:(id <QSObject>)object;
@end
