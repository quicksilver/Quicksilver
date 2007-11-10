//
//  QSTreeController.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 4/27/06.

//

#import "QSTreeController.h"


@implementation QSTreeController
- (void)setContent:(id)content
{
	if(![content isEqual:[self content]])
	{
		NSArray *paths = [[self selectionIndexPaths] retain];
		[super setContent:nil];
		[super setContent:content];
		[self setSelectionIndexPaths:paths];
		[paths release];
	}
}
@end
