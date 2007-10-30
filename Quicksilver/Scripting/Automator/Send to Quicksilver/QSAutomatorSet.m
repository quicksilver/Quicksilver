//
//  QSAutomatorSet.m
//  QSAutomatorSet
//
//  Created by Nicholas Jitkoff on 3/20/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "QSAutomatorSet.h"


@protocol QSController
- (void)setAESelection:(NSAppleEventDescriptor *)desc types:(NSArray *)types;
- (NSAppleEventDescriptor *)AESelection;
@end

@interface AMAction (Private)
- (id)providesDictionary;
@end
@implementation QSAutomatorSet

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo
{
	NSBundle *bundle=[anAction respondsToSelector:@selector(bundle)]?[anAction bundle]:nil;
//	NSLog(@"Bundle %@",bundle);

	NSArray *types=[[anAction providesDictionary] objectForKey:@"Types"];
	
//	if ([[types objectAtIndex:0]isEqualToString:@"*"])
//		NSDictionary *param=[anAction parameters];
//		param objectForKey @"fromApplication"

	// Add your code here, returning the data to be passed to the next action.
	NSConnection *connection=[NSConnection connectionWithRegisteredName:@"QuicksilverControllerConnection" host:nil];
	id proxy=[connection rootProxy];
	if (proxy){
		[proxy setProtocolForProxy:@protocol(QSController)];
		[proxy setAESelection:input types:types];
	}else{
		NSLog(@"Unable to connect to Quicksilver");
	}  
	
	return input;
}

@end
