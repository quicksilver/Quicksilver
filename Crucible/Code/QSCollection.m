//
//  QSCollection.m
//  Quicksilver
//
//  Created by Alcor on 8/6/04.

//

#import "QSCollection.h"


@implementation QSCollection
- (id)init{
    if ((self=[super init])){
        array=[[NSMutableArray alloc]init];
    }
    return self;
}
- (void)dealloc{
	[array release];
    [super dealloc];
}

//Methods for array passing

- (BOOL)respondsToSelector:(SEL)aSelector{
    if ([super respondsToSelector:aSelector]) return YES;
    return [array respondsToSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation{
  if ([array respondsToSelector:[invocation selector]])
        [invocation invokeWithTarget:array];
    else
        [self doesNotRecognizeSelector:[invocation selector]];
}

-(NSMethodSignature*)methodSignatureForSelector:(SEL)sel {
    NSMethodSignature *sig=[[self class] instanceMethodSignatureForSelector:sel];
    if (sig) return sig;
    return [array methodSignatureForSelector:sel];
}

-(unsigned)count{
	return [array count];
}


@end
