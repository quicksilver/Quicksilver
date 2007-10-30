//
//  QSTitleToolbarView.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 4/25/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "QSTitleToolbarItem.h"


@implementation QSTitleToolbarItem
- (BOOL)wantsToDrawIconInDisplayMode:(NSToolbarDisplayMode)mode{
	if (mode==NSToolbarDisplayModeLabelOnly) return NO;
	return YES;
}
- (BOOL)wantsToDrawLabelInDisplayMode:(NSToolbarDisplayMode)mode{
	return YES;
}
- (BOOL)wantsToDrawIconIntoLabelAreaInDisplayMode:(NSToolbarDisplayMode)mode{
	if (mode==NSToolbarDisplayModeLabelOnly) return NO;
	return YES;
}
@end
