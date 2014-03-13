//
//  QSAutomatorSet.m
//  QSAutomatorSet
//
//  Created by Nicholas Jitkoff on 3/20/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "QSAutomatorSet.h"


@protocol QSController
- (void)setQSSelection:(id)sel;
- (id)QSSelection;
@end

@interface AMAction (Private)
- (id)providesDictionary;
@end
@implementation QSAutomatorSet

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo
{
	NSBundle *bundle = nil;
    if ([anAction respondsToSelector:@selector(bundle)]) {
        bundle = [(AMBundleAction *)anAction bundle];
    }

	// Add your code here, returning the data to be passed to the next action.
	NSConnection *connection = [NSConnection connectionWithRegisteredName:@"QuicksilverControllerConnection" host:nil];
	id proxy = [connection rootProxy];
	if (proxy) {
		[proxy setProtocolForProxy:@protocol(QSController)];
		[proxy setQSSelection:input];
	} else {
		NSLog(@"Unable to connect to Quicksilver");
	}

	return input;
}

@end
