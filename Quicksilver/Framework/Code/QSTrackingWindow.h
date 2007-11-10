//
//  QSTrackingwindow.h
//  Quicksilver
//
//  Created by Alcor on 7/5/04.

//

#import <Cocoa/Cocoa.h>


@interface QSTrackingWindow : NSWindow {
	NSTrackingRectTag trackingRect;
}

+(QSTrackingWindow *)trackingWindow;

@end
