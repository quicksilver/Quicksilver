//
//  NSTreeController+BLTRExtensions.m
//  QuickStep Foundation
//
//  Created by Patrick Robertson on 12/06/2022.
//

#import "NSTreeController+BLTRExtensions.h"

#import <AppKit/AppKit.h>

// Inefficient, but only needed for QSCatalogPrefPane
// Kudos to Rob Keniger from SO: https://stackoverflow.com/a/9050488/305324

@implementation NSTreeController (NSTreeController_BLTRExtensions)

- (NSIndexPath*)indexPathOfObject:(id)anObject
{
    return [self indexPathOfObject:anObject inNodes:[[self arrangedObjects] childNodes]];
}

- (NSIndexPath*)indexPathOfObject:(id)anObject inNodes:(NSArray*)nodes
{
    for (NSTreeNode* node in nodes) {
		if ([[node representedObject] isEqual:anObject]) {
            return [node indexPath];
		}
        if ([[node childNodes] count]) {
            NSIndexPath* path = [self indexPathOfObject:anObject inNodes:[node childNodes]];
			if (path) {
                return path;
			}
        }
    }
    return nil;
}

@end
