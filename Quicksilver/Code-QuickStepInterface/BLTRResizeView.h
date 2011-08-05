//
//  BLTRResizeView.h
//  Quicksilver
//
//  Created by Alcor on Sat Aug 30 2003.
//  Copyright (c) 2003 Blacktree. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface BLTRResizeView : NSView {
	NSPoint mouseDownPoint;
	NSRect oldFrame;
	NSInteger quadrant;
}

@end
