//
// QSHistoryObjectSource.m
// Quicksilver
//
// Created by Nicholas Jitkoff on 8/18/05.
// Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "QSHistoryObjectSource.h"
#import "QSHistoryController.h"

#import "QSObject_FileHandling.h"
#import <QSCore/QSObject.h>
#import <QSCore/QSResourceManager.h>

@implementation QSHistoryObjectSource

- (id)init {
	if (self = [super init]) {
		[QSHistoryController sharedInstance];
	}
	return self;
}

- (BOOL)entryCanBeIndexed:(NSDictionary *)theEntry {return NO;}
- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry { return YES; }
- (NSImage *)iconForEntry:(NSDictionary *)dict { return [QSResourceManager imageNamed:@"Quicksilver"]; }
- (NSArray *)objectsForEntry:(NSDictionary *)dict {
	if ([[dict objectForKey:kItemID] isEqualToString:@"QSPresetCommandHistory"])
		return [QSHist recentCommands];
	else
		return [QSHist recentObjects];
}

- (id)resolveProxyObject:(id)proxy {
	if ([[proxy identifier] isEqualToString:@"QSLastCommandProxy"]) {
        NSArray * recentCmds = [QSHist recentCommands];
        if([recentCmds count] != 0)
            return [recentCmds objectAtIndex:0];
	} else if ([[proxy identifier] isEqualToString:@"QSLastObjectProxy"]) {
        NSArray * recentObjs = [QSHist recentObjects];
        if([recentObjs count] != 0)
		return [recentObjs objectAtIndex:0];
	}
	return nil;
}

@end
