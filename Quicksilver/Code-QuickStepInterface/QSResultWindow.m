#import "QSResultWindow.h"
@implementation QSResultWindow
- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
	NSWindow* result = [super initWithContentRect:contentRect styleMask:aStyle | NSResizableWindowMask backing:bufferingType defer:YES];
    [self setOpaque:![[NSUserDefaults standardUserDefaults] boolForKey:@"QSResultsUseAlpha"]];
    
    [self setShowEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSSlightGrowEffect", @"transformFn", @"show", @"type", [NSNumber numberWithDouble:0.05] , @"duration", nil]];
	[self setHideEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSSlightShrinkEffect", @"transformFn", @"hide", @"type", [NSNumber numberWithDouble:0.05] , @"duration", nil]];

    if([self setFrameUsingName:@"results"])
        [[self class] removeFrameUsingName:@"results"];
    
	// HenningJ 20110418: There seem to be several bugs in the setFrameAutosaveName stuff.
	// see http://www.cocoadev.com/index.pl?NSWindowFrameAutosizing
	// using manual loading and saving (in QSResultController windowDidResize:) instead
	[self setFrameUsingName:@"QSResultWindow" force:YES];
    [self setBackgroundColor:[NSColor clearColor]];
	[self setMovableByWindowBackground:NO];
    [self setShowsResizeIndicator:YES];
    return (QSResultWindow *)result;
}

- (NSTimeInterval)animationResizeTime:(NSRect)newFrame {
	return .1;
}

- (BOOL)acceptsFirstResponder {return NO;}
- (BOOL)canBecomeKeyWindow {return NO;}
- (BOOL)canBecomeMainWindow {return NO;}

@end
