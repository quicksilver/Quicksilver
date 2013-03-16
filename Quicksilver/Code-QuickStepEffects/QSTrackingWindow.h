//
//  QSTrackingwindow.h
//  Quicksilver
//
//  Created by Alcor on 7/5/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol QSTrackingWindowDelegate
- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;
@end

@interface QSTrackingWindow : NSWindow <NSWindowDelegate>
{
	NSTrackingRectTag trackingRect;
}

+ (QSTrackingWindow *)trackingWindow;
- (id <QSTrackingWindowDelegate>)delegate;
- (void)setDelegate:(id <QSTrackingWindowDelegate>)delegate;

@end
