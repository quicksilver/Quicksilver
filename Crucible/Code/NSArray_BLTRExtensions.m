//
//  NSArray_Extensions.m
//  Quicksilver
//
//  Created by Alcor on Fri Apr 04 2003.

//

#import "NSArray_BLTRExtensions.h"

@implementation NSMutableArray (Moving)
- (void)moveIndex:(int)fromIndex toIndex:(int)toIndex{
	if (fromIndex==toIndex)return;
	id object=[self objectAtIndex:fromIndex];
	[self insertObject:object atIndex:toIndex];
	if (toIndex<fromIndex)fromIndex++;
	[self removeObjectAtIndex:fromIndex];
}
- (void)insertObjectsFromArray:(NSArray *)array atIndex:(unsigned)index{
	id object;
	for(object in array){
		[self insertObject:object atIndex:index];
	}
}

@end


@implementation NSArray (IndexSet)
- (NSArray *)objectsAtIndexes:(NSIndexSet *)indexes{
	NSMutableArray *array=[NSMutableArray array];
	unsigned int index;
	for (index=[indexes firstIndex];index!=NSNotFound;index=[indexes indexGreaterThanIndex:index]){
		[array addObject:[self objectAtIndex:index]];	
	}
	return array;
}
@end

@implementation NSArray (Transformation)
- (BOOL)hasPrefix:(NSArray *)prefixArray{
//	int i;
//	int count=MIN([self count],
//	for (i=0
	return NO;
}
- (NSString *)componentsJoinedByStrings:(NSArray *)strings{
	NSArray *joinedStrings=[self arrayByPerformingSelector:@selector(componentsJoinedByStrings:) withObject:[strings tail]];
	return [joinedStrings componentsJoinedByString:[strings head]];
}


- (id)head{
	return [self count]?[self objectAtIndex:0]:nil;
}
- (NSArray *)tail{
	return [self count]>1?[self subarrayWithRange:NSMakeRange(1,[self count]-1)]:nil;
}
- (NSArray *)arrayByPerformingSelector:(SEL)aSelector{
    NSMutableArray *resultArray=[NSMutableArray arrayWithCapacity:[self count]];
    int i;
    id result;
    for (i=0;i<(int)[self count];i++){
        result=[[self objectAtIndex:i]performSelector:aSelector];
        [resultArray addObject:(result?result:[NSNull null])];
    }
    return resultArray;
}

- (NSArray *)arrayByPerformingSelector:(SEL)aSelector withObject:(id)object{
    NSMutableArray *resultArray=[NSMutableArray arrayWithCapacity:[self count]];
    int i;
    id result=nil;
    for (i=0;i<(int)[self count];i++){
        result=[[self objectAtIndex:i]performSelector:aSelector withObject:object];
        [resultArray addObject:(result?result:[NSNull null])];
	}
    return resultArray;
}

/*
 - (NSArray *)valuesForKeys:NSArray *{
	 NSMutableArray *array=[NSMutableArray array];
	 
 }
 */

- (id)objectWithValue:(id)value forKey:(NSString *)key{
	NSEnumerator *e=[self objectEnumerator];
	id object;
	while((object=[e nextObject])){
		if ([[object valueForKey:key]isEqual:value]) return object; 
	}
	return nil;
}


@end

//performSelectorOnObjectsInArray(id target,SEL aSelector,

@implementation NSObject (BLTRArrayPerform)


+ (NSMutableArray *)performSelector:(SEL)aSelector onObjectsInArray:(id)array returnValues:(BOOL)flag{
    NSMutableArray *resultArray=nil;
	if (flag)resultArray=[NSMutableArray arrayWithCapacity:[array count]];
    int i;
    id result=nil;
    for (i=0;i<(int)[array count];i++){
        result=[self performSelector:aSelector withObject:[array objectAtIndex:i]];
        if (flag) [resultArray addObject:(result?result:[NSNull null])];
	}
    return resultArray;
}

- (NSMutableArray *)performSelector:(SEL)aSelector onObjectsInArray:(id)array returnValues:(BOOL)flag{
    NSMutableArray *resultArray=nil;
	if (flag)resultArray=[NSMutableArray arrayWithCapacity:[array count]];
    int i;
    id result=nil;
    for (i=0;i<(int)[array count];i++){
        result=[self performSelector:aSelector withObject:[array objectAtIndex:i]];
        if (flag) [resultArray addObject:(result?result:[NSNull null])];
	}
    return resultArray;
}

- (NSMutableArray *)performSelector:(SEL)aSelector onObjectsInArray:(id)array{
	return [self performSelector:(SEL)aSelector onObjectsInArray:(id)array returnValues:YES];
}



@end

@implementation NSMutableArray (Reverse)

- (void)reverse{
	int i;
	for (i=0; i<(floor([self count]/2.0)); i++) {
		[self exchangeObjectAtIndex:i withObjectAtIndex:([self count]-(i+1))];
	}
}

@end

