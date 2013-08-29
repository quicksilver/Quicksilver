//
// QSTreeController.m
// Quicksilver
//
// Created by Nicholas Jitkoff on 4/27/06.
// Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "QSTreeController.h"

@implementation QSTreeController
- (void)setContent:(id)content {
	if (![content isEqual:[self content]]) {
		NSArray *paths = [self selectionIndexPaths];
		[super setContent:nil];
		[super setContent:content];
		[self setSelectionIndexPaths:paths];
	}
}
@end
