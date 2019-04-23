//
// QSHistoryController.m
// Quicksilver
//
// Created by Alcor on 5/17/05.
// Copyright 2005 Blacktree, Inc. All rights reserved.
//

#import "QSHistoryController.h"
#import "QSCommand.h"

id QSHist;

@implementation QSHistoryController

+ (id)sharedInstance {
	if (!QSHist) QSHist = [[[self class] allocWithZone:nil] init];
	return QSHist;
}

- (id)init {
	self = [super init];
	if (self != nil) {
		objectHistory = [[NSMutableArray alloc] init];
		commandHistory = [[NSMutableArray alloc] init];
		actionHistory = [[NSMutableArray alloc] init];
	}
	return self;
}

- (NSArray *)recentObjects {return objectHistory;}
- (NSArray *)recentCommands {return commandHistory;}
- (NSArray *)recentActions {return actionHistory;}
- (NSUInteger)historyLength {
	return [[NSUserDefaults standardUserDefaults] integerForKey:@"QSHistoryMaxLength"];
}

- (void)addAction:(id)action {
	[actionHistory addObject:action];
	[actionHistory removeObject:action];
	[actionHistory insertObject:action atIndex:0];
	while ([actionHistory count] > [self historyLength])
		[actionHistory removeLastObject];
}
- (void)addCommand:(QSCommand *)command {
	if ([[[command dObject] identifier] isEqualToString:@"QSLastCommandProxy"] || !command) {
        // If we're re-running the last command, don't change anything
        return;
	}
    
    NSUInteger existingCommandIndex = [commandHistory indexOfObject:command];
    if (existingCommandIndex != NSNotFound) {
        if (existingCommandIndex == 0) {
            // command is already the first item in the history, no need to remove and re-add it
            return;
        }
        [commandHistory removeObjectAtIndex:existingCommandIndex];
    }
    [commandHistory insertObject:command atIndex:0];
    if (existingCommandIndex == NSNotFound) {
        while ([commandHistory count] > [self historyLength]) {
            [commandHistory removeLastObject];
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryInvalidatedNotification object:@"QSPresetCommandHistory"];
}

- (void)addObject:(id)object {
    if ([object isKindOfClass:[QSRankedObject class]] ) {
        object = [object object];
    }
	[objectHistory removeObject:object];
	[objectHistory insertObject:object atIndex:0];
	while ([objectHistory count] > [self historyLength])
		[objectHistory removeLastObject];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryInvalidatedNotification object:@"QSPresetObjectHistory"];
}

@end
