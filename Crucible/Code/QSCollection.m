//
//  QSCollection.m
//  Quicksilver
//
//  Created by Alcor on 8/6/04.

//

#import "QSCollection.h"

@implementation QSCollection
+ (id)collection {
    return [[[self alloc] init] autorelease];
}

+ (id)collectionWithObjects:(id <QSObject>)objects, ... {
    [NSException raise:NSInternalInconsistencyException format:@"%s TODO", __FILE__];
    return nil;
}

+ (id)collectionWithObject:(id <QSObject>)object {
    QSCollection *collection = [self collection];
    [collection addObject:object];
    return collection;
}

+ (id)collectionWithArray:(NSArray *)objects {
    QSCollection *collection = [self collection];
    [collection addObjectsFromArray:objects];
    return collection;    
}

- (id)init {
    if ((self = [super init])) {
        objects = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
	[objects release];
    [super dealloc];
}

//Methods for array passing
- (BOOL)respondsToSelector:(SEL)aSelector{
    if ([super respondsToSelector:aSelector])
        return YES;
    return [objects respondsToSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
  if ([objects respondsToSelector:[invocation selector]])
        [invocation invokeWithTarget:objects];
    else
        [self doesNotRecognizeSelector:[invocation selector]];
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)sel {
    NSMethodSignature *sig = [[self class] instanceMethodSignatureForSelector:sel];
    if (sig) return sig;
    return [objects methodSignatureForSelector:sel];
}

- (NSUInteger)count {
	return [objects count];
}

- (NSArray *)allObjects {
    return [objects copy];
}

@end
