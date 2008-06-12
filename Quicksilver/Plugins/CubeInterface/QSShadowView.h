//
//  QSShadowView.h
//  QSCubeInterfacePlugIn
//
//  Created by Nicholas Jitkoff on 6/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface QSShadowView : NSView {
	NSView *targetView;
	NSColor *color;
	float blur;
	float distance;
	float angle;
	float expand;
}

- (NSRect)paddedFrameForFrame:(NSRect)frame;


- (NSView *) targetView;
- (void) setTargetView: (NSView *) newTargetView;
- (NSColor *) color;
- (void) setColor: (NSColor *) newColor;
- (float) blur;
- (void) setBlur: (float) newBlur;
- (float) distance;
- (void) setDistance: (float) newDistance;
- (float) angle;
- (void) setAngle: (float) newAngle;
- (float) expand;
- (void) setExpand: (float) newExpand;




@end
