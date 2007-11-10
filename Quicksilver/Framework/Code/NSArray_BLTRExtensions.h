//
//  NSArray_Extensions.h
//  Quicksilver
//
//  Created by Alcor on Fri Apr 04 2003.

//

#import <Foundation/Foundation.h>

@interface NSArray (IndexSet)
- (NSArray *)objectsAtIndexes:(NSIndexSet *)indexes;
@end

@interface NSObject (BLTRArrayPerform)
+ (NSMutableArray *)performSelector:(SEL)aSelector onObjectsInArray:(id)array returnValues:(BOOL)flag;
- (NSMutableArray *)performSelector:(SEL)aSelector onObjectsInArray:(id)array returnValues:(BOOL)flag;
- (NSMutableArray *)performSelector:(SEL)aSelector onObjectsInArray:(id)array;

@end

@interface NSArray (Transformation)

- (NSString *)componentsJoinedByStrings:(NSArray *)strings;
- (id)head;
- (NSArray *)tail;
	
- (NSArray *)arrayByPerformingSelector:(SEL)aSelector;
- (NSArray *)arrayByPerformingSelector:(SEL)aSelector withObject:(id)object;
- (id)objectWithValue:(id)value forKey:(NSString *)key;
@end


@interface NSMutableArray (Moving)
- (void)moveIndex:(int)fromIndex toIndex:(int)toIndex;
- (void)insertObjectsFromArray:(NSArray *)array atIndex:(unsigned)index;
@end


@interface NSMutableArray (Reverse)
- (void)reverse;
@end

