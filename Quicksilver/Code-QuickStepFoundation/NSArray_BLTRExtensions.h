//
//  NSArray_Extensions.h
//  Quicksilver
//
//  Created by Alcor on Fri Apr 04 2003.
//  Copyright (c) 2003 Blacktree, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Transformation)

- (NSString *)componentsJoinedByStrings:(NSArray *)strings;
- (id)head;
- (NSArray *)tail;

- (NSMutableArray *)arrayByPerformingSelector:(SEL)aSelector;
- (NSMutableArray *)arrayByPerformingSelector:(SEL)aSelector withObject:(id)object;
- (id)objectWithValue:(id)value forKey:(NSString *)key;
@end

@interface NSArray (Enumeration)

- (NSArray *)arrayByEnumeratingArrayUsingBock:(id (^)(id obj))block;

@end


@interface NSMutableArray (Moving)
- (void)moveIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;
- (void)insertObjectsFromArray:(NSArray *)array atIndex:(NSUInteger)index;
@end


@interface NSMutableArray (Reverse)
- (void)reverse;
@end

