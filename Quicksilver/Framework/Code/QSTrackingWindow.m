//
//  QSTrackingwindow.m
//  Quicksilver
//
//  Created by Alcor on 7/5/04.

//

#import "QSTrackingWindow.h"



#import "QSTypes.h"

@implementation QSTrackingWindow
+(QSTrackingWindow *)trackingWindow{
	QSTrackingWindow* window = [[[QSTrackingWindow alloc]initWithContentRect:NSZeroRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreRetained defer:YES]autorelease];
	[window setBackgroundColor: [[NSColor redColor]colorWithAlphaComponent:0.5]];
	[window setOpaque:NO];
	[window setIgnoresMouseEvents:YES];
	[window setHasShadow:NO];
	[window setLevel:kCGPopUpMenuWindowLevel-1];
	[window setSticky:YES];
	//[window setDelegate:[window contentView]]];
	NSMutableArray *types=[[standardPasteboardTypes mutableCopy]autorelease];
  //  [types addObjectsFromArray:[[QSReg objectHandlers]allKeys]];
    [window registerForDraggedTypes:types];
	return window;
}

- (void)sendEvent:(NSEvent *)theEvent{
	//QSLog(@"Event %@", theEvent);
    [super sendEvent:theEvent];
}


- (void)updateTrackingRect{
	QSLog(@"update");
	//logRect([self frame]);
    if (trackingRect)[[self contentView] removeTrackingRect:trackingRect];
    trackingRect=[[self contentView] addTrackingRect:NSMakeRect(0,0,NSWidth([self frame]),NSHeight([self frame])) owner:self userData:self assumeInside:NO];
}

- (void)setFrame:(NSRect)frameRect display:(BOOL)flag{
	[super setFrame:frameRect display:flag];
	[self updateTrackingRect];
}


- (void)mouseEntered:(NSEvent *)theEvent{
	QSLog(@"entered tracking");
	[[self delegate]mouseEntered:theEvent];	
}

- (void)mouseExited:(NSEvent *)theEvent{
	QSLog(@"exited tracking");
	[[self delegate]mouseExited:theEvent];	
}

- (unsigned int)draggingEntered:(id <NSDraggingInfo>)theEvent{
    
	QSLog(@"dragging tracking");
	[[self delegate]mouseEntered:nil];	
	return NSDragOperationEvery;
}

- (BOOL)canBecomeKeyWindow{return NO;}
- (BOOL)canBecomeMainWindow{return NO;}

@end
