//
//  QSTrackingwindow.h
//  Quicksilver
//
//  Created by Alcor on 7/5/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface QSTrackingWindow : NSWindow {
	NSTrackingRectTag trackingRect;
}

+(QSTrackingWindow *)trackingWindow;

@end
