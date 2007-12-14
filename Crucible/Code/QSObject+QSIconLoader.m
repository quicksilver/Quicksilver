//
//  QSObject+QSIconLoader.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 12/12/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "QSObject+QSIconLoader.h"

NSOperationQueue *iconLoadQueue = nil;


@implementation QSObject (QSIconLoader)

+ (NSOperationQueue *)iconLoadQueue {
  if (!iconLoadQueue) {
    iconLoadQueue = [[NSOperationQueue alloc] init];
    [iconLoadQueue setMaxConcurrentOperationCount:1];  
    [iconLoadQueue addObserver:self forKeyPath:@"operations" options:0 context:nil]; 
  }
  return iconLoadQueue;
}
+ (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ([[iconLoadQueue operations] count] == 0) {
    [iconLoadQueue release];
    iconLoadQueue = nil;
  }
}

- (NSImage *) delayedIcon {

  if (![self iconLoaded]) {
    NSOperationQueue *queue = [[self class] iconLoadQueue];
    NSInvocationOperation *operation = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(loadIconInQueue) object:nil] autorelease];
    [queue addOperation:operation];

  }
	return [self icon];

}


- (void)loadIconInQueue {
  if ([self loadIcon]) {
    [self willChangeValueForKey:@"delayedIcon"];
    [self didChangeValueForKey:@"delayedIcon"];
  }
}
@end
