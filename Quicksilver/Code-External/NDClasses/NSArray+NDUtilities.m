/*
	NSArray+NDUtilities.m

	Created by Nathan Day on 16.01.03 under a MIT-style license. 
	Copyright (c) 2008 Nathan Day

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
 */

#import "NSArray+NDUtilities.h"

@interface NSEnumeratrorWithArrayIndicies : NSEnumerator
{
@private
	NSArray			* array;
	NSIndexSet		* indexSet;
	unsigned int	currentIndex;
}
+ (id)enumeratrorWithArray:(NSArray *)anArray indicies:(NSIndexSet *)anIndiciesSet;
- (id)initWithArray:(NSArray *)anArray indicies:(NSIndexSet *)anIndiciesSet;
@end

/*
 * category implementation NSArray (NDUtilities)
 */
@implementation NSArray (NDUtilities)

+ (NSArray *)stringArrayWithCommandLineArgumentValues:(char **)anArgv count:(int)anArgc
{
	NSMutableArray		* theResult = [NSMutableArray arrayWithCapacity:anArgc];

	for( int i = 0; i < anArgc && anArgv[i] != NULL && theResult != nil; i++ )
	{
		NSString	* theString = [NSString stringWithCString:anArgv[i] encoding:NSUTF8StringEncoding];
		if( theString == nil )
		{
			NSLog( @"Error parsing argument '%s'\n", anArgv[i] );
			theResult = nil;
		}
			
		[theResult addObject:theString];
	}
	return theResult;
}

/*
 * -arrayByUsingFunction:
 */
- (NSArray *)arrayByUsingFunction:(id (*)(id, BOOL *))aFunc
{
	unsigned int		theIndex,
							theCount;
	NSMutableArray		* theResultArray;
	BOOL					theContinue = YES;

	theCount = [self count];
	theResultArray = [NSMutableArray arrayWithCapacity:theCount];

	for( theIndex = 0; theIndex < theCount && theContinue == YES; theIndex++ )
	{
		id		theResult;
		
		theResult = aFunc([self objectAtIndex:theIndex], &theContinue );

		if( theResult ) [theResultArray addObject:theResult];
	}

	return theResultArray;
}

/*
 * -everyObjectOfKindOfClass:
 */
- (NSArray *)everyObjectOfKindOfClass:(Class)aClass
{
	unsigned int		theIndex,
							theCount;
	NSMutableArray		* theResultArray;

	theCount = [self count];
	theResultArray = [NSMutableArray arrayWithCapacity:theCount];
	
	for( theIndex = 0; theIndex < theCount; theIndex++ )
	{
		id		theObject;

		theObject = [self objectAtIndex:theIndex];

		if( [theObject isKindOfClass:aClass] )
			[theResultArray addObject:theObject];
	}

	return theResultArray;
}

/*
 * -makeObjectsPerformFunction:
 */
- (BOOL)makeObjectsPerformFunction:(BOOL (*)(id))aFunc
{
	unsigned int		theIndex,
							theCount = [self count];
	
	for( theIndex = 0; theIndex < theCount; theIndex++ )
		if( !aFunc([self objectAtIndex:theIndex]) ) return NO;

	return YES;
}

/*
 * -makeObjectsPerformFunction:withContext:
 */
- (BOOL)makeObjectsPerformFunction:(BOOL (*)(id, void *))aFunc withContext:(void *)aContext
{
	unsigned int		theIndex,
							theCount = [self count];

	for( theIndex = 0; theIndex < theCount; theIndex++ )
		if( !aFunc( [self objectAtIndex:theIndex], aContext ) ) return NO;

	return YES;
}

/*
 * -makeObjectsPerformFunction:withContext:
 */
- (BOOL)makeObjectsPerformFunction:(BOOL (*)(id, id))aFunc withObject:(id)anObject
{
	unsigned int		theIndex,
							theCount = [self count];

	for( theIndex = 0; theIndex < theCount; theIndex++ )
		if( !aFunc( [self objectAtIndex:theIndex], anObject ) ) return NO;

	return YES;
}

- (BOOL)makeObjectsPerformFunction:(BOOL (*)(id))aFunc usingIndicies:(NSIndexSet *)anIndexSet
{
	unsigned int		theIndex,
	theCount = [self count];
	
	for( theIndex = 0; theIndex < theCount; theIndex++ )
		if( [anIndexSet containsIndex:theIndex] && !aFunc( [self objectAtIndex:theIndex] ) ) return NO;
	
	return YES;
}

- (BOOL)makeObjectsPerformFunction:(BOOL (*)(id, id))aFunc withObject:(id)anObject usingIndicies:(NSIndexSet *)anIndexSet
{
	unsigned int		theIndex,
	theCount = [self count];
	
	for( theIndex = 0; theIndex < theCount; theIndex++ )
		if( [anIndexSet containsIndex:theIndex] && !aFunc( [self objectAtIndex:theIndex], anObject ) ) return NO;
	
	return YES;
}

- (BOOL)makeObjectsPerformFunction:(BOOL (*)(id))aFunc usingPredicate:(NSPredicate *)aPredicate
{
	unsigned int		theIndex,
	theCount = [self count];
	
	for( theIndex = 0; theIndex < theCount; theIndex++ )
	{
		id		theObject = [self objectAtIndex:theIndex];
		if( [aPredicate evaluateWithObject:theObject] && !aFunc( theObject ) ) return NO;
	}
	
	return YES;
}


- (BOOL)makeObjectsPerformFunction:(BOOL (*)(id, id))aFunc withObject:(id)anObject usingPredicate:(NSPredicate *)aPredicate
{
	unsigned int		theIndex,
	theCount = [self count];
	
	for( theIndex = 0; theIndex < theCount; theIndex++ )
	{
		id		theObject = [self objectAtIndex:theIndex];
		if( [aPredicate evaluateWithObject:theObject] && !aFunc( theObject, anObject ) ) return NO;
	}
	
	return YES;
}

/*
 * -findObjectWithFunction:
 */
- (id)findObjectWithFunction:(BOOL (*)(id))aFunc
{
	id						theFoundObject = nil;
	unsigned int		theIndex,
							theCount = [self count];

	for( theIndex = 0; theIndex < theCount && theFoundObject == nil; theIndex++ )
	{
		id		theObject = [self objectAtIndex:theIndex];
		if( aFunc( theObject ) )
				theFoundObject = theObject;
	}

	return theFoundObject;
}

/*
 * -findObjectWithFunction:withContext:
 */
- (id)findObjectWithFunction:(BOOL (*)(id, void *))aFunc withContext:(void*)aContext
{
	id						theFoundObject = nil;
	unsigned int		theIndex,
		theCount = [self count];

	for( theIndex = 0; theIndex < theCount && theFoundObject == nil; theIndex++ )
	{
		id		theObject = [self objectAtIndex:theIndex];
		if( aFunc( theObject, aContext ) )
			theFoundObject = theObject;
	}

	return theFoundObject;
}

- (NSArray *)findAllObjectWithFunction:(BOOL (*)(id))aFunc
{
	NSMutableArray		* theFoundObjectArray = [NSMutableArray arrayWithCapacity:[self count]];
	unsigned int		theIndex,
							theCount = [self count];
	
	for( theIndex = 0; theIndex < theCount; theIndex++ )
	{
		id		theObject = [self objectAtIndex:theIndex];
		if( aFunc( theObject ) )
			[theFoundObjectArray addObject:theObject];
	}
	
	return theFoundObjectArray;
}

- (NSArray *)findAllObjectWithFunction:(BOOL (*)(id, void *))aFunc withContext:(void*)aContext
{
	NSMutableArray		* theFoundObjectArray = [NSMutableArray arrayWithCapacity:[self count]];
	unsigned int		theIndex,
		theCount = [self count];
	
	for( theIndex = 0; theIndex < theCount; theIndex++ )
	{
		id		theObject = [self objectAtIndex:theIndex];
		if( aFunc( theObject, aContext ) )
			[theFoundObjectArray addObject:theObject];
	}
	
	return theFoundObjectArray;
}

/*
 * -indexOfObjectWithFunction:
 */
- (unsigned int)indexOfObjectWithFunction:(BOOL (*)(id))aFunc
{
	unsigned int		theIndex,
							theFoundIndex = NSNotFound,
							theCount = [self count];
	
	for( theIndex = 0; theIndex < theCount && theFoundIndex == NSNotFound; theIndex++ )
	{
		if( aFunc( [self objectAtIndex:theIndex] ) )
			theFoundIndex = theIndex;
	}
	
	return theFoundIndex;
}

/*
 * -indexOfObjectWithFunction:withContext:
 */
- (unsigned int)indexOfObjectWithFunction:(BOOL (*)(id, void *))aFunc withContext:(void*)aContext
{
	unsigned int		theIndex,
	theFoundIndex = NSNotFound,
							theCount = [self count];

	for( theIndex = 0; theIndex < theCount && theFoundIndex == NSNotFound; theIndex++ )
	{
		if( aFunc( [self objectAtIndex:theIndex], aContext ) )
			theFoundIndex = theIndex;
	}

	return theFoundIndex;
}

- (void)sendEveryObjectToTarget:(id)aTarget withSelector:(SEL)aSelector
{
	unsigned int		theIndex,
							theCount = [self count];
	
	for( theIndex = 0; theIndex < theCount; theIndex++ )
		[aTarget performSelector:aSelector withObject:[self objectAtIndex:theIndex]];
}

- (void)sendEveryObjectToTarget:(id)aTarget withSelector:(SEL)aSelector withObject:(id)anObject
{
	unsigned int		theIndex,
							theCount = [self count];
	
	for( theIndex = 0; theIndex < theCount; theIndex++ )
		[aTarget performSelector:aSelector withObject:[self objectAtIndex:theIndex] withObject:anObject];
}

/*
 * -firstObject
 */
- (id)firstObject
{
	return ([self count] > 0 ) ? [self objectAtIndex:0] : nil;
}

/*
 * -isEmpty
 */
- (BOOL)isEmpty
{
	return [self count] == 0;
}

- (NSEnumerator *)objectEnumeratorWithIndicies:(NSIndexSet *)anIndicies
{
	return [NSEnumeratrorWithArrayIndicies enumeratrorWithArray:self indicies:anIndicies];
}

- (id)firstObjectReturningYESToSelector:(SEL)aSelector
{
	id		theFoundObject = nil;
	for( unsigned int theIndex = 0, theCount = [self count]; theIndex < theCount && theFoundObject == nil; theIndex ++ )
	{
		id	theObject = [self objectAtIndex:theIndex];
		if( [theObject respondsToSelector:aSelector] )
		{
			BOOL (*theTestMethod)(id, SEL) = (BOOL (*)(id, SEL))[theObject methodForSelector:aSelector];
			if( theTestMethod( theObject, aSelector ) )
				theFoundObject = theObject;
		}
	}
	
	return theFoundObject;
}

- (id)firstObjectReturningYESToSelector:(SEL)aSelector withContext:(void*)aContext
{
	id		theFoundObject = nil;
	for( unsigned int theIndex = 0, theCount = [self count]; theIndex < theCount && theFoundObject == nil; theIndex ++ )
	{
		id	theObject = [self objectAtIndex:theIndex];
		if( [theObject respondsToSelector:aSelector] )
		{
			BOOL (*theTestMethod)(id, SEL, id) = (BOOL (*)(id, SEL, id))[theObject methodForSelector:aSelector];
			if( theTestMethod( theObject, aSelector, aContext ) )
				theFoundObject = theObject;
		}
	}

	return theFoundObject;
}

- (id)firstObjectOfKind:(Class)aClass
{
	return [self firstObjectReturningYESToSelector:@selector(isKindOfClass:) withContext:aClass];
}

@end

#if 0
@implementation NSMutableArray (NDUtilities)

- (void)insertObject:(id)anObject usingFunction:(int (*)(id, id, void *))aCompFun context:(void *)aContext
{
	unsigned int	theIndex = 0,
					theCount = [self count];
	for( theIndex = 0; theIndex < theCount && anObject != nil; theIndex++ )
	{
		if( aCompFun( anObject, [self objectAtIndex:theIndex], aContext ) > 0 )
		{
			[self insertObject:anObject atIndex:theIndex];
			anObject = nil;
		}
	}
	if( anObject != nil )
		[self addObject:anObject];
}

@end
#endif

@implementation NSEnumeratrorWithArrayIndicies

+ (id)enumeratrorWithArray:(NSArray *)anArray indicies:(NSIndexSet *)anIndiciesSet
{
	return [[[self alloc] initWithArray:anArray indicies:anIndiciesSet] autorelease];
}

- (id)initWithArray:(NSArray *)anArray indicies:(NSIndexSet *)anIndiciesSet
{
	if( (self = [super init]) != nil )
	{
		array = [anArray retain];
		indexSet = [anIndiciesSet retain];
		currentIndex = [indexSet indexGreaterThanOrEqualToIndex:0];
	}
	return self;
}

- (id)nextObject
{
	unsigned int	theCount = [array count];
	id					theObject = nil;
	if( currentIndex < theCount && currentIndex != NSNotFound )
	{
		theObject = [array objectAtIndex:currentIndex];		
		currentIndex = [indexSet indexGreaterThanIndex:currentIndex];
	}
	return theObject;
}

@end
