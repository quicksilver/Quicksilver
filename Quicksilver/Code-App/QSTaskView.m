//
//  QSTaskView.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 11/26/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "QSTaskView.h"


@implementation QSTaskView
- (QSTask *)task { return [[task retain] autorelease]; }
- (void)setTask:(QSTask *)newTask
{
    if (task != newTask) {
        [task release];
        task = [newTask retain];
    }
}
- (void)awakeFromNib{
//	NSLog(@"thread");

	[progress setUsesThreadedAnimation:YES];
	//[progress startAnimation:nil];
}

- (void)dealloc
{
	//NSLog(@"release task view %@",task);
	[progress unbind:@"isIndeterminate"];
    [task release];
    task = nil;
    [super dealloc];
}

@end
