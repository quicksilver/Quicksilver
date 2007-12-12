//
// QSWebSource.m
// Quicksilver
//
// Created by Alcor on 7/9/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "QSWebSource.h"
#import "QSRegistry.h"
#import "QSKeys.h"
#import "QSParser.h"
#import "QSHTMLLinkParser.h"
#import "QSFoundation.h"

@implementation QSWebSource

- (NSImage *)iconForEntry:(NSDictionary *)entry {
	NSImage *image = [NSImage imageNamed:@"DefaultBookmarkIcon"];
	[image createIconRepresentations];
	return image;
}

- (NSArray *)objectsForEntry:(NSDictionary *)theEntry {
	NSMutableDictionary *settings = [theEntry objectForKey:kItemSettings];
	NSString *location = [settings objectForKey:kItemPath];
	if (location) {
		return [(QSHTMLLinkParser *)[QSReg getClassInstance:@"QSHTMLLinkParser"] objectsFromURL:[NSURL URLWithString:location] withSettings:settings];
	}
	return nil;
}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry {
	return YES;
}

@end
