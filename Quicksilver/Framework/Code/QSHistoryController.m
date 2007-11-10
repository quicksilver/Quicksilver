//
//  QSHistoryController.m
//  Quicksilver
//
//  Created by Alcor on 5/17/05.

//

#import "QSHistoryController.h"
#import "QSCommand.h"

#define MAXHIST 50

id QSHist;

@implementation QSHistoryController

+ (id)sharedInstance{
    if (!QSHist) QSHist = [[[self class] allocWithZone:[self zone]] init];
    return QSHist;
}

- (id) init {
	self = [super init];
	if (self != nil) {
		objectHistory=[[NSMutableArray alloc]init];
		commandHistory=[[NSMutableArray alloc]init];
		actionHistory=[[NSMutableArray alloc]init];
	}
	return self;
}

- (NSArray *)recentObjects{return objectHistory;}
- (NSArray *)recentCommands{return commandHistory;}
- (NSArray *)recentActions{return actionHistory;}

- (void)addAction:(id)action{
	[actionHistory addObject:action];
	[actionHistory removeObject:action];
	[actionHistory insertObject:action atIndex:0];
	while ([actionHistory count]>MAXHIST)
		[actionHistory removeLastObject];
}
- (void)addCommand:(id)command{
	//[commandHistory removeObject:command];
	
	if ([[[command dObject] identifier] isEqualToString:@"QSLastCommandProxy"]){
		[command setDObject:[command dObject]];
		QSLog(@"command %@",[command dObject]);
	}
		if (command)
			[commandHistory insertObject:[command objectValue] atIndex:0];
	//QSLog(@"Added %@",command);
	while ([commandHistory count]>MAXHIST)
		[commandHistory removeLastObject];
}
- (void)addObject:(id)object{
	[objectHistory removeObject:object];
	[objectHistory insertObject:object atIndex:0];
	while ([objectHistory count]>MAXHIST)
		[objectHistory removeLastObject];
}

@end
