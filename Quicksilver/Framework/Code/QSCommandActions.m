//
//  QSCommandActions.m
//  Quicksilver
//
//  Created by Alcor on 7/29/04.

//

#import "QSCommandActions.h"
#import "QSCommand.h"


# define kQSCommandAddTriggerAction @"QSCommandAddTriggerAction"
# define kQSCommandExecuteAction @"QSCommandExecuteTriggerAction"

@implementation QSCommandActions




- (NSArray *) types{
	 return [NSArray arrayWithObject:QSCommandType];
}

- (NSArray *) actions{
    NSImage *icon=[NSImage imageNamed:@"Quicksilver"];
    NSMutableArray *actionArray=[NSMutableArray arrayWithCapacity:1];
    QSAction *action;
	action=[QSAction actionWithIdentifier:kQSCommandAddTriggerAction];
	[action setIcon:        icon];
	[action setProvider:    self];
	[action setAction:      @selector(addTrigger:)];
	[actionArray addObject:action]; 
	return actionArray;
}


- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject{

    NSMutableArray *newActions=[NSMutableArray arrayWithCapacity:1];
	
		[newActions addObject:kQSCommandAddTriggerAction];
	return newActions;
}


- (QSObject *) addTrigger:(QSObject *)dObject{
	return nil;
}

@end