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
    __block NSUInteger internalIndex = index;
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
       [self insertObject:obj atIndex:internalIndex];
        internalIndex++;
    }];
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
    NSMutableArray *resultArray = nil;
	__block id result;
    @synchronized(self) {
        resultArray = [NSMutableArray arrayWithCapacity:[self count]];
        [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            result = [obj performSelector:aSelector];
#pragma clang diagnostic pop
            [resultArray addObject:(result?result:[NSNull null])];
        }];
    }
	return resultArray;
}

- (NSMutableArray *)arrayByPerformingSelector:(SEL)aSelector withObject:(id)object {
    NSMutableArray *resultArray = nil;
    __block id result;
    @synchronized(self) {
        resultArray = [NSMutableArray arrayWithCapacity:[self count]];
        [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            result = [obj performSelector:aSelector withObject:object];
#pragma clang diagnostic pop
            [resultArray addObject:(result?result:[NSNull null])];
        }];
    }
	return resultArray;
}

- (id)objectWithValue:(id)value forKey:(NSString *)key {
    __block id returnVal = nil;
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([[obj valueForKey:key] isEqual:value]) {
            returnVal = obj;
            *stop = YES;
        }
    }];
    return returnVal;
}

@end

@implementation NSObject (BLTRArrayPerform)

+ (NSMutableArray *)performSelector:(SEL)aSelector onObjectsInArray:(id)array returnValues:(BOOL)flag {
	NSMutableArray *resultArray = nil;
    __block id result;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    @synchronized(array) {
        if (flag)
            resultArray = [NSMutableArray arrayWithCapacity:[(NSArray *)array count]];
        
        [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (flag) {
                result = [self performSelector:aSelector withObject:obj];
                [resultArray addObject:(result?result:[NSNull null])];
            } else {
                [self performSelector:aSelector withObject:obj];
            }
        }];
    }
#pragma clang diagnostic pop

	return resultArray;
}

- (NSMutableArray *)performSelector:(SEL)aSelector onObjectsInArray:(id)array returnValues:(BOOL)flag {
	NSMutableArray *resultArray = nil;
    __block id result;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    @synchronized(array) {
        if (flag)
            resultArray = [NSMutableArray arrayWithCapacity:[(NSArray *)array count]];
    
        [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (flag) {
                result = [self performSelector:aSelector withObject:obj];
                [resultArray addObject:(result?result:[NSNull null])];
            } else {
                [self performSelector:aSelector withObject:obj];
            }
        }];
    }
#pragma clang diagnostic pop

	return resultArray;
}

- (NSMutableArray *)performSelector:(SEL)aSelector onObjectsInArray:(id)array {
	return [self performSelector:aSelector onObjectsInArray:array returnValues:YES];
}

@end

@implementation NSArray (Enumeration)

- (NSArray *)arrayByEnumeratingArrayUsingBock:(id (^)(id obj))block {
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[self count]];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [arr addObject:block(obj)];
    }];
    return [NSArray arrayWithArray:arr];
}

@end

@implementation NSMutableArray (Reverse)

- (void)reverse {
	NSUInteger i;
	for (i = 0; i < (floor([self count]/2.0) ); i++)
		[self exchangeObjectAtIndex:i withObjectAtIndex:([self count]-i-1)];
}

@end
