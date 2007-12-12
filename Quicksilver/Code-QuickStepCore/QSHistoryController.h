//
//  QSHistoryController.h
//  Quicksilver
//
//  Created by Alcor on 5/17/05.
//  Copyright 2005 Blacktree, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


extern id QSHist; // Shared Instance


@interface QSHistoryController : NSObject {
	NSMutableArray *commandHistory;
	NSMutableArray *objectHistory;
	NSMutableArray *actionHistory;

}
+ (id)sharedInstance;

- (NSArray *)recentObjects;
- (NSArray *)recentCommands;
- (NSArray *)recentActions;

- (void)addAction:(id)action;
- (void)addCommand:(id)command;
- (void)addObject:(id)object;

@end
