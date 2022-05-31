//
// QSTaskViewController.m
// Quicksilver
//
// Created by Nicholas Jitkoff on 11/26/05.
// Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "QSTaskViewController.h"


@implementation QSTaskViewController

+ (instancetype)controllerWithTask:(QSTask *)task {
    return [[self alloc] initWithTask:task];
}

- (instancetype)initWithTask:(QSTask *)task {
    NSParameterAssert(task != nil);

    self = [super initWithNibName:@"QSTaskView" bundle:[NSBundle bundleForClass:[self class]]];
    if (!self) return nil;

	self.representedObject = task;

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
