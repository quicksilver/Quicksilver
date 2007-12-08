//
//  BLTRResizeView.h
//  Quicksilver
//
//  Created by Alcor on Sat Aug 30 2003.

//

#import <AppKit/AppKit.h>


@interface BLTRResizeView : NSView {
    NSPoint mouseDownPoint;
    NSRect oldFrame;
    int quadrant;
}

@end
