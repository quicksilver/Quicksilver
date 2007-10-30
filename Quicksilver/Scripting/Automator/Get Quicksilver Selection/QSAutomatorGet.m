//
//  QSAutomatorGet.m
//  QSAutomatorGet
//
//  Created by Nicholas Jitkoff on 3/20/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "QSAutomatorGet.h"

@protocol QSController
- (void)setAESelection:(NSAppleEventDescriptor *)desc;
- (NSAppleEventDescriptor *)AESelection;
@end


@implementation QSAutomatorGet

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo
{
	// Add your code here, returning the data to be passed to the next action.
	NSConnection *connection=[NSConnection connectionWithRegisteredName:@"QuicksilverControllerConnection" host:nil];
	id proxy=[connection rootProxy];
	if (proxy){
		[proxy setProtocolForProxy:@protocol(QSController)];
		
		id selection=[proxy AESelection];
		NSLog(@"recieved selection %@",selection);
		return selection;
	}else{
		NSLog(@"Unable to connect to Quicksilver");
	}  
	
	return input;
}

@end
