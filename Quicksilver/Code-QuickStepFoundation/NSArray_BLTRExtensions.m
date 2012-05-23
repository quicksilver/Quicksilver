//
// NSArray_Extensions.m
// Quicksilver
//
// Created by Alcor on Fri Apr 04 2003.
// Copyright (c) 2003 Blacktree, Inc. All rights reserved.
//

#import "NSArray_BLTRExtensions.h"

@implementation NSMutableArray (Moving)
- (void)moveIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex {
	if (fromIndex != toIndex){
		[self insertObject:[self objectAtIndex:fromIndex] atIndex:toIndex];
		if (toIndex<fromIndex)
			fromIndex++;
		[self removeObjectAtIndex:fromIndex];
	}
}
- (void)insertObjectsFromArray:(NSArray *)array atIndex:(NSUInteger)index {
	id object;
	for(object in array)
		[self insertObject:object atIndex:index];
}

@end

@implementation NSArray (IndexSet)
- (NSArray *)objectsAtIndexes:(NSIndexSet *)indexes {
	NSMutableArray *array = [NSMutableArray array];
	NSUInteger index;
	for (index = [indexes firstIndex]; index != NSNotFound; index = [indexes indexGreaterThanIndex:index])
		[array addObject:[self objectAtIndex:index]];
	return array;
}
@end

@implementation NSArray (Transformation)

- (BOOL)hasPrefix:(NSArray *)prefixArray { return NO; }

- (NSString *)componentsJoinedByStrings:(NSArray *)strings {
	return [[self arrayByPerformingSelector:@selector(componentsJoinedByStrings:) withObject:[strings tail]] componentsJoinedByString:[strings head]];
}

- (id)head { return [self count] ? [self objectAtIndex:0] : nil; }
- (NSArray *)tail { return [self count] > 1 ? [self subarrayWithRange:NSMakeRange(1, [self count]-1)] : nil; }
- (NSMutableArray *)arrayByPerformingSelector:(SEL)aSelector {
	NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:[self count]];
	id result;
	for (id anObject in self)
	{
		result = [anObject performSelector:aSelector];
		[resultArray addObject:(result?result:[NSNull null])];
	}
	return resultArray;
}

- (NSMutableArray *)arrayByPerformingSelector:(SEL)aSelector withObject:(id)object {
	NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:[self count]];
	NSUInteger i;
	id result = nil;
	for (i = 0; i < [self count]; i++) {
		result = [[self objectAtIndex:i] performSelector:aSelector withObject:object];
		[resultArray addObject:(result?result:[NSNull null])];
	}
	return resultArray;
}

- (id)objectWithValue:(id)value forKey:(NSString *)key {
	for(id object in self) {
		if ([[object valueForKey:key] isEqual:value])
			return object;
	}
	return nil;
}

@end

@implementation NSObject (BLTRArrayPerform)

+ (NSMutableArray *)performSelector:(SEL)aSelector onObjectsInArray:(id)array returnValues:(BOOL)flag {
	NSMutableArray *resultArray = nil;
	if (flag)
		resultArray = [NSMutableArray arrayWithCapacity:[(NSArray *)array count]];
	NSUInteger i;
	id result;
	for (i = 0; i < [(NSArray *)array count]; i++) {
		result = [self performSelector:aSelector withObject:[array objectAtIndex:i]];
		if (flag)
			[resultArray addObject:(result?result:[NSNull null])];
	}
	return resultArray;
}

- (NSMutableArray *)performSelector:(SEL)aSelector onObjectsInArray:(id)array returnValues:(BOOL)flag {
	NSMutableArray *resultArray = nil;
	if (flag)
		resultArray = [NSMutableArray arrayWithCapacity:[(NSArray *)array count]];
	NSUInteger i;
	id result;
	for (i = 0; i < [(NSArray *)array count]; i++) {
		result = [self performSelector:aSelector withObject:[array objectAtIndex:i]];
		if (flag) [resultArray addObject:(result?result:[NSNull null])];
	}
	return resultArray;
}

- (NSMutableArray *)performSelector:(SEL)aSelector onObjectsInArray:(id)array {
	return [self performSelector:(SEL) aSelector onObjectsInArray:(id)array returnValues:YES];
}

@end

@implementation NSMutableArray (Reverse)

- (void)reverse {
	NSUInteger i;
	for (i = 0; i < (floor([self count]/2.0) ); i++)
		[self exchangeObjectAtIndex:i withObjectAtIndex:([self count]-i-1)];
}

@end
