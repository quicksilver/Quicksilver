//
//  QSTitleToolbarView.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 4/25/06.

//

#import <Cocoa/Cocoa.h>


@interface QSTitleToolbarItem : NSToolbarItem
{
}
- (BOOL)wantsToDrawIconInDisplayMode:(NSToolbarDisplayMode)mode;
- (BOOL)wantsToDrawLabelInDisplayMode:(NSToolbarDisplayMode)mode;
- (BOOL)wantsToDrawIconIntoLabelAreaInDisplayMode:(NSToolbarDisplayMode)mode;
@end