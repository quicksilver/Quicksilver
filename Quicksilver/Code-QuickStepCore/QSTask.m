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

@synthesize status = _status;
@synthesize name = _name;
@synthesize progress = _progress;
@synthesize icon = _icon;
@synthesize showProgress = _showProgress;

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
	_showProgress = YES;

    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[%@:%@:%@] ", self.identifier, self.name, self.status];
}

- (void)start {
	if (self.isRunning) {
#ifdef DEBUG
		if (VERBOSE) NSLog(@"Task already started, ignoring: %@", self);
#endif
		return;
	}
	
#ifdef DEBUG
	if (VERBOSE) NSLog(@"Start Task: %@", self);
#endif
	QSGCDMainSync(^{
		self.running = YES;
		[QSTasks taskStarted:self];
	});
}

- (void)stop {
	if (self.isRunning == NO) {
#ifdef DEBUG
		if (VERBOSE) NSLog(@"Task already stopped, ignoring: %@", self);
#endif
		return;
	}
	
#ifdef DEBUG
	if (VERBOSE) NSLog(@"Stop Task: %@", self);
#endif
	
	QSGCDMainSync(^{
		self.running = NO;
		[self setStatus:NSLocalizedString(@"Complete", @"Text that is displayed in the task viewer when a task has finished running")];
		[QSTasks taskStopped:self];
	});
}

#pragma mark KVO

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
	// see here for more info: https://developer.apple.com/documentation/objectivec/nsobject/1409370-automaticallynotifiesobserversfo?language=objc
	// By default, Cocoa automatically notifies objects when values have changed. To ensure thread-safety, we disable this automatic notification, and send the notifications ourselves manually (using willChangeValueForKey: and didChangeValueForKey:).
	// Since we know that all QSTask-related values are used on the main thread, by doing this we can ensure the notifications are always sent on the main thread.
	return NO;
}

#pragma mark Getters & Setters

// the following manually created setters/getters are required, to ensure values are only set on the main thread - required for UI updates and KVO
- (void)setStatus:(NSString *)status {
	QSGCDMainSync(^{
		if (status != self->_status) {
			[self willChangeValueForKey:@"status"];
			self->_status = status;
			[self didChangeValueForKey:@"status"];
		}
	});
}
- (NSString *)status {
	return self->_status;
}

- (void)setProgress:(CGFloat)progress {
	QSGCDMainSync(^{
		if (progress != self->_progress) {
			[self willChangeValueForKey:@"progress"];
			self->_progress = progress;
			[self didChangeValueForKey:@"progress"];
		}
	});
}
- (CGFloat)progress {
	return self->_progress;
}


- (void)setName:(NSString *)name {
	QSGCDMainSync(^{
		if (name != self->_name) {
			[self willChangeValueForKey:@"name"];
			self->_name = name;
			[self didChangeValueForKey:@"name"];
		}
	});
}
- (NSString *)name {
	return self->_name;
}

- (void)setIcon:(NSImage *)icon {
	QSGCDMainSync(^{
		if (icon != self->_icon) {
			[self willChangeValueForKey:@"icon"];
			self->_icon = icon;
			[self didChangeValueForKey:@"icon"];
		}
	});
}
-(NSImage *)icon {
	return self->_icon;
}

- (void)setShowProgress:(BOOL)showProgress {
	QSGCDMainSync(^{
		[self willChangeValueForKey:@"showProgress"];
		self->_showProgress = showProgress;
		[self didChangeValueForKey:@"showProgress"];
	});
}
- (BOOL)showProgress {
	return _showProgress;
}

- (void)cancel {
	NSAssert(self.isRunning == YES, @"Asked to cancel stopped task %@", self);
	
#ifdef DEBUG
	if (VERBOSE) NSLog(@"Cancel Task: %@", self);
#endif
	
	if (self.cancelBlock) {
		self.cancelBlock();
	}
	[self stop];
}

- (void)addSubtask:(QSTask *)task {
	NSAssert(task != nil, @"Sub task shouldn't be nil");
	[self.subtasks addObject:task];
	task.parentTask = self;
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
