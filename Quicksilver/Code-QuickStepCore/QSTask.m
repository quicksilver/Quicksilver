//
// QSTask.m
// Quicksilver
//
// Created by Nicholas Jitkoff on 6/29/05. Adapted by Florian Heckl on 20/08/10.
//

#import "QSTask.h"
#import "QSTaskController.h"
#import "QSTaskController_Private.h"

@interface QSTask ()

@property (getter=isRunning) BOOL running;
@property (copy) NSMutableArray *subtasks;
@property (weak) QSTask *parentTask;

@end

@implementation QSTask

// KVO
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

    if ([key isEqualToString:@"indeterminateProgress"] || [key isEqualToString:@"animateProgress"]) {
        keyPaths = [keyPaths setByAddingObject:@"progress"];
    }
    return keyPaths;
}

+ (QSTask *)taskWithIdentifier:(NSString *)identifier {
    NSParameterAssert(identifier != nil);

    QSTask *task = [QSTaskController.sharedInstance taskWithIdentifier:identifier];
    if (!task)
        task = [[self alloc] initWithIdentifier:identifier];
    return task;
}

- (id)init {
    return [self initWithIdentifier:NSString.uniqueString];
}

- (id)initWithIdentifier:(NSString *)identifier {
    NSParameterAssert(identifier != nil);

    self = [super init];
    if (self == nil) {
        return nil;
    }

    _subtasks = [NSMutableArray array];
    _identifier = identifier.copy;
	_progress = -1.0;

    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[%@:%@:%@] ", self.identifier, self.name, self.status];
}

- (void)start {
    @synchronized (self) {
        if (self.isRunning) {
#ifdef DEBUG
            if (VERBOSE) NSLog(@"Task already started, ignoring: %@", self);
#endif
            return;
        }

#ifdef DEBUG
        if (VERBOSE) NSLog(@"Start Task: %@", self);
#endif

        self.running = YES;
        [QSTasks taskStarted:self];
    }
}

- (void)stop {
    @synchronized (self) {
        if (self.isRunning == NO) {
#ifdef DEBUG
            if (VERBOSE) NSLog(@"Task already stopped, ignoring: %@", self);
#endif
            return;
        }

#ifdef DEBUG
        if (VERBOSE) NSLog(@"Stop Task: %@", self);
#endif

        self.running = NO;
        [QSTasks taskStopped:self];
    }
}

- (void)cancel {
    @synchronized (self) {
        NSAssert(self.isRunning == YES, @"Asked to cancel stopped task %@", self);

#ifdef DEBUG
        if (VERBOSE) NSLog(@"Cancel Task: %@", self);
#endif

        if (self.cancelBlock) {
            self.cancelBlock();
        }
        [self stop];
    }
}

- (void)addSubtask:(QSTask *)task {
    NSAssert(task != nil, @"Sub task shouldn't be nil");
    @synchronized (self) {
        [self.subtasks addObject:task];
        task.parentTask = self;
    }
}

// Bindings

- (BOOL)animateProgress {
    return self.progress < 0;
}

- (BOOL)indeterminateProgress {
    return self.progress < 0;
}

- (BOOL)canBeCancelled {
    return self.cancelBlock != nil;
}

@end
