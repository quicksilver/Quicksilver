//
//  NSArray_Extensions.h
//  Quicksilver
//
//  Created by Alcor on Fri Apr 04 2003.
//  Copyright (c) 2003 Blacktree, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (IndexSet)
- (NSArray *)objectsAtIndexes:(NSIndexSet *)indexes;
@end

@interface NSObject (BLTRArrayPerform)
+ (NSMutableArray *)performSelector:(SEL)aSelector onObjectsInArray:(NSArray *)array returnValues:(BOOL)flag;
- (NSMutableArray *)performSelector:(SEL)aSelector onObjectsInArray:(NSArray *)array returnValues:(BOOL)flag;
- (NSMutableArray *)performSelector:(SEL)aSelector onObjectsInArray:(NSArray *)array;

@end

@interface NSArray (Transformation)

- (NSString *)componentsJoinedByStrings:(NSArray *)strings;
- (id)head;
- (NSArray *)tail;

- (NSMutableArray *)arrayByPerformingSelector:(SEL)aSelector;
- (NSMutableArray *)arrayByPerformingSelector:(SEL)aSelector withObject:(id)object;
- (id)objectWithValue:(id)value forKey:(NSString *)key;
@end


@interface NSMutableArray (Moving)
- (void)moveIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
- (void)insertObjectsFromArray:(NSArray *)array atIndex:(NSUInteger)index;
@end


@interface NSMutableArray (Reverse)
- (void)reverse;
@end

