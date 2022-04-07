//
// QSTaskViewController.m
// Quicksilver
//
// Created by Nicholas Jitkoff on 11/26/05.
// Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "QSTaskViewController.h"

const NSString *QSTaskProxyObservationContext = @"QSTaskProxyObservationContext";
#define QSTaskKeyPaths @[@"name", @"status", @"progress", @"icon", @"indeterminateProgress", @"animateProgress", @"canBeCancelled"]

@interface QSTaskProxy : NSObject {
	QSTask *_task;
}
+ (instancetype)proxyTaskWithTask:(QSTask *)task;
- (instancetype)initWithTask:(QSTask *)task;
@end

@implementation QSTaskProxy


+ (instancetype)proxyTaskWithTask:(QSTask *)task {
	return [[self alloc] initWithTask:task];
}

- (instancetype)initWithTask:(QSTask *)task {
	NSParameterAssert(task != nil);
	self = [super init];
	if (!self) return nil;

	_task = task;
	for (NSString *keyPath in QSTaskKeyPaths) {
		[_task addObserver:self
				forKeyPath:keyPath
				   options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew
				   context:(__bridge void *)QSTaskProxyObservationContext];
	}

	return self;
}

- (void)dealloc {
	for (NSString *keyPath in QSTaskKeyPaths) {
		[_task removeObserver:self forKeyPath:keyPath];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
	if (context == (__bridge void *)QSTaskProxyObservationContext) {
		QSGCDMainAsync(^{
			[self willChangeValueForKey:keyPath];
			[self didChangeValueForKey:keyPath];
		});
	}
}

- (id)valueForKey:(NSString *)key {
	return [_task valueForKey:key];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
	return [_task methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
	[invocation invokeWithTarget:_task];
}

@end

@implementation QSTaskViewController

+ (instancetype)controllerWithTask:(QSTask *)task {
    return [[self alloc] initWithTask:task];
}

- (instancetype)initWithTask:(QSTask *)task {
    NSParameterAssert(task != nil);

    self = [super initWithNibName:@"QSTaskView" bundle:[NSBundle bundleForClass:[self class]]];
    if (!self) return nil;

    self.representedObject = [QSTaskProxy proxyTaskWithTask:task];

    return self;
}

- (void)awakeFromNib {
    [self.progressIndicator bind:@"hidden" toObject:self.task withKeyPath:@"showProgress" options:@{NSValueTransformerNameBindingOption: NSNegateBooleanTransformerName}];
	[self.progressIndicator bind:@"isIndeterminate" toObject:self.task withKeyPath:@"indeterminateProgress" options:nil];
    [self.progressIndicator setUsesThreadedAnimation:YES];
}

- (void)dealloc {
    [self.progressIndicator unbind:@"isIndeterminate"];
    [self.progressIndicator unbind:@"hidden"];
}

- (QSTask *)task {
    return [self representedObject];
}

- (void)setTask:(QSTask *)task {
    self.representedObject = task;
}

- (IBAction)cancel:(id)sender {
    [self.task cancel];
}

@end
