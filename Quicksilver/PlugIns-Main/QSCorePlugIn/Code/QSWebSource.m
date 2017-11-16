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

- (NSImage *)iconForEntry:(QSCatalogEntry *)theEntry {
	return [QSResourceManager imageNamed:@"DefaultBookmarkIcon"];
}

- (NSArray *)objectsForEntry:(QSCatalogEntry *)theEntry {
    NSMutableDictionary *settings = theEntry.sourceSettings;
	NSString *location = [settings objectForKey:kItemPath];
	if (location) {
		NSArray *contents = [(QSHTMLLinkParser *)[QSReg getClassInstance:@"QSHTMLLinkParser"] objectsFromURL:[NSURL URLWithString:location] withSettings:settings];
		if (contents) {
			return contents;
		}
		// return the original contents of the catalog entry if there was a problem getting data from the internet
		return [QSLib entryForID:theEntry.identifier].contents;
    }
    return nil;
}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(QSCatalogEntry *)theEntry {
	return YES;
}

@end
