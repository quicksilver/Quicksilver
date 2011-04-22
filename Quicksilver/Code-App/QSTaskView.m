//
// QSTaskView.m
// Quicksilver
//
// Created by Nicholas Jitkoff on 11/26/05.
// Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "QSTaskView.h"

@implementation QSTaskView
- (QSTask *)task { return task;  }
- (void)setTask:(QSTask *)newTask {
	if (task != newTask) {
		[task release];
		task = [newTask retain];
	}
}

- (void)awakeFromNib {
	[progress setUsesThreadedAnimation:YES];
}

- (void)dealloc {
	[progress unbind:@"isIndeterminate"];
	[task release];
	[super dealloc];
}

@end
