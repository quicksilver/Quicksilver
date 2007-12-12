//
// QSTitleToolbarItem.m
// Quicksilver
//
// Created by Nicholas Jitkoff on 4/25/06.
// Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "QSTitleToolbarItem.h"


@implementation QSTitleToolbarItem
- (BOOL)wantsToDrawIconInDisplayMode:(NSToolbarDisplayMode)mode {
	return !(mode == NSToolbarDisplayModeLabelOnly);
}
- (BOOL)wantsToDrawLabelInDisplayMode:(NSToolbarDisplayMode)mode {
	return YES;
}
- (BOOL)wantsToDrawIconIntoLabelAreaInDisplayMode:(NSToolbarDisplayMode)mode {
	return !(mode == NSToolbarDisplayModeLabelOnly);
}
@end
