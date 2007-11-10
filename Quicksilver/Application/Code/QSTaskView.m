//
//  QSTaskView.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 11/26/05.

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
//	QSLog(@"thread");

	[progress setUsesThreadedAnimation:YES];
	//[progress startAnimation:nil];
}

- (void)dealloc
{
	//QSLog(@"release task view %@",task);
	[progress unbind:@"isIndeterminate"];
    [task release];
    task = nil;
    [super dealloc];
}

@end
