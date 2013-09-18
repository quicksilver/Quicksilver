//
// QSTaskViewController.m
// Quicksilver
//
// Created by Nicholas Jitkoff on 11/26/05.
// Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "QSTaskViewController.h"

@implementation QSTaskViewController

- (instancetype)initWithTask:(QSTask *)task {
    NSParameterAssert(task != nil);

    self = [super initWithNibName:@"QSTaskView" bundle:[NSBundle bundleForClass:[self class]]];
    if (self == nil) {
        return nil;
    }

    _task = task;

    return self;
}

- (void)awakeFromNib {
	[self.progressIndicator setUsesThreadedAnimation:YES];
}

- (void)dealloc {
	[self.progressIndicator unbind:@"isIndeterminate"];
}

- (IBAction)cancel:(id)sender {
    [self.task cancel];
}

@end
