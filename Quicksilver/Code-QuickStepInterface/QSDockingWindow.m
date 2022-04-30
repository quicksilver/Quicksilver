#import "QSDockingWindow.h"
#import "QSRegistry.h"
#import "QSController.h"

#import "QSTypes.h"

#import <QSFoundation/QSFoundation.h>

@implementation QSDockingWindow
- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
	if (self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag]) {
		[self setOpaque:NO];
		[self setMovableByWindowBackground:YES];
		[self setShowsResizeIndicator:YES];
		hideTimer = nil;
		[self setCanHide:NO];
		[self setLevel:NSFloatingWindowLevel];
		[self setSticky:YES];
		hidden = YES;
		
        [self registerForDraggedTypes:[standardPasteboardTypes arrayByAddingObjectsFromArray:[[QSReg objectHandlers] allKeys]]];
	}
	return self;
}

- (void)sendEvent:(NSEvent *)theEvent {
    // when events (such as a mouse click) are sent to the window, allow it to become key
    allowKey = YES;
    [super sendEvent:theEvent];
    allowKey = NO;
}

- (void)awakeFromNib {
	// Notification for when the menu items list is opened in a docking window (e.g. clipboard menu)
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(lock) name:@"com.apple.HIToolbox.beginMenuTrackingNotification" object:nil];
	// Notification for when the menu item list is closed in a docking window
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(unlock) name:@"com.apple.HIToolbox.endMenuTrackingNotification" object:nil];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}


- (void)lock {locked = YES;}
- (void)unlock {locked = NO;}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)theEvent {
	[self show:self];
	return [super draggingEntered:theEvent];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)theEvent {
	return [super draggingUpdated:theEvent];
}

- (void)draggingExited:(id <NSDraggingInfo>)theEvent {
	lastTime = [NSDate timeIntervalSinceReferenceDate];
	if ([hideTimer isValid]) {
		[hideTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:0.75]];
	} else {
		hideTimer = [NSTimer scheduledTimerWithTimeInterval:0.333 target:self selector:@selector(timerHide:) userInfo:nil repeats:YES];
		[hideTimer fire];
	}
	[super draggingExited:theEvent];
}

// mouse entered the docking window
- (void)mouseEntered:(NSEvent *)theEvent {
	// Set time when mouse entered the window
	// Case 1: If the window's a floating window that's hidden, set = 0.0 (allows for case where you mouse over the area where the window was as it's fading)
	// Case 2: If the window's a sliding-into-edge window, always set the time to the current time (it's always 'hidden', so must check for the isDocked case)
	if (!hidden || [self isDocked]) {
		timeEntered = [NSDate timeIntervalSinceReferenceDate];
	} else {
		timeEntered = 0.0;
	}

	[hideTimer invalidate];
	// Event for mouse exit. untilDate:+0.2s from now chosen as appropriate for holding the mose on the screen edge (trial and error)
	NSEvent *earlyExit = [NSApp nextEventMatchingMask:NSMouseExitedMask untilDate:[NSDate dateWithTimeIntervalSinceNow:0.2] inMode:NSDefaultRunLoopMode dequeue:YES];
	
	// Open the docking window if it's on the edge of the screen
	if ([self isDocked] && !earlyExit && !locked) {
		[self show:self];
	}
}

- (void)timerHide:(NSTimer *)timer {
	if (!NSMouseInRect([NSEvent mouseLocation], NSInsetRect([self frame], -10, -10), NO)) {
		if ([NSDate timeIntervalSinceReferenceDate] - lastTime > 0.3) {
			[self hideOrOrderOut:self];
			[hideTimer invalidate];
		}
	}
}

// mouse exited the docking window
- (void)mouseExited:(NSEvent *)theEvent {
	// don't dismiss the window unless it's docked to an edge
	if (![self isDocked]) {
		return;
	}
	
	// if the mouse never entered the window, it shouldn't close
	if(timeEntered == 0.0) {
		return;
	}
	// time when mouse exited the window
	NSTimeInterval timeExited = [NSDate timeIntervalSinceReferenceDate];
	
	// Event for mouse re-entry into window. 0.5s chosen as max time allowed for the mouse outside the window before it closes (best time through testing)
	NSEvent *reentry = [NSApp nextEventMatchingMask:NSMouseEnteredMask untilDate:[NSDate dateWithTimeIntervalSinceNow:0.5] inMode:NSDefaultRunLoopMode dequeue:NO];
	if ([reentry windowNumber] != [self windowNumber])
		reentry = nil;
	// no re-entry of mouse into window and was inside the window for more than 0.2s (best time found from trial and error)
	if (!reentry && ![NSEvent pressedMouseButtons] && (timeExited - timeEntered > 0.2)) {
		[self hideOrOrderOut:self];
	}
}

- (BOOL)isDocked
{
	return ((NSInteger)touchingEdgeForRectInRect([self frame], [[self screen] frame]) >= 0);
}

- (BOOL)canFade
{
	NSLog(@"`canFade` (in QSDockingWindow) is deprecated as of B68. Please use `isDocked` instead.");
	return [self isDocked];
}

- (BOOL)canBecomeKeyWindow {
	return !hidden && allowKey;
}

- (BOOL)hidden {return hidden;}

- (IBAction)hideOrOrderOut:(id)sender {
	if ([self isDocked]) {
		[self hide:self];
	} else {
		[self orderOut:self];
	}
}

- (void)makeKeyAndOrderFront:(id)sender {
	allowKey = YES;
    QSInterfaceController *interfaceController = [(QSController *)[NSApp delegate] interfaceController];
    [interfaceController setHiding:YES];
	[super makeKeyAndOrderFront:sender];
    [interfaceController setHiding:NO];
	allowKey = NO;
}

- (IBAction)toggle:(id)sender {
	if (hidden) {
		[self show:sender];
	} else if ([self isVisible]) {
		[self hideOrOrderOut:sender];
	} else {
		[self makeKeyAndOrderFront:sender];
	}
}

- (IBAction)hide:(id)sender {
	if ([self isKeyWindow])
		[self fakeResignKey];
	NSInteger edge = touchingEdgeForRectInRect([self frame], [[self screen] frame]);
	if (edge < 0)
		return;
	NSArray *screens = [NSScreen screens];
	NSRect hideRect = expelRectFromRectOnEdge([self frame], [[self screen] frame], edge, 1.0); // TESTING: not peeking?
	if ([screens count]) {
		for (id loopItem in screens) {
			if (NSIntersectsRect(NSInsetRect(hideRect, 1, 1), [loopItem frame]) ) return;
		}
	}
	hidden = YES;
	if ([self isVisible]) {
		// hide on mouse out
		[self resizeToFrame:hideRect alpha:1 display:YES completionHandler:^{
			[self setAlphaValue:0];
			[self saveFrame];
		}];
	} else {
		// hide on application launch
		[self setFrame:hideRect display:YES];
		[self setAlphaValue:0];
	}
	[self setHasShadow:NO];
}

- (IBAction)orderFrontHidden:(id)sender {
	if ([self isDocked]) {
		[self hide:sender];
		[self reallyOrderFront:self];
	} else {
		[self show:sender];
	}
}

- (void)keyDown:(NSEvent *)theEvent {
    // close docked windows when Esc key is pressed
	if ([theEvent keyCode] == kVK_Escape) {
		[self hideOrOrderOut:nil];
	} else {
		[super keyDown:theEvent];
	}
}

- (void)performClose:(id)sender {
	[self close];
}

- (IBAction)show:(id)sender {
	[self orderFront:sender];
	[self setHasShadow:YES];
	[self resizeToFrame:constrainRectToRect([self frame], [[self screen] frame]) alpha:1 display:NO completionHandler:^{
		self->hidden = NO;
		[self makeKeyAndOrderFront:self];
	}];
}

- (IBAction)showKeyless:(id)sender {
	[self orderFront:sender];
	[self setHasShadow:YES];
	[self resizeToFrame:constrainRectToRect([self frame], [[self screen] frame]) alpha:1 display:NO completionHandler:^{
		self->hidden = NO;
	}];
}

- (NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)aScreen {
	return frameRect;
}

- (void)resignKeyWindowNow {
	[self fakeResignKey];
}

- (void)updateTrackingRect:(id)sender {
	NSView *frameView = [[self contentView] superview];
	if (trackingRect)
		[frameView removeTrackingRect:trackingRect];
	trackingRect = [frameView addTrackingRect:[frameView bounds] owner:self userData:nil assumeInside:NO];
}

- (void)setFrame:(NSRect)frameRect display:(BOOL)flag {
	[super setFrame:frameRect display:flag];
	if (!(NSEqualSizes(frameRect.size, [self frame].size)))
		[self updateTrackingRect:self];
}

- (void)saveFrame {
	if ([self frameAutosaveName]) {
		[self saveFrameUsingName:[self frameAutosaveName]];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

- (void)orderOut:(id)sender {
	if (hidden) {
		[super reallyOrderOut:sender];
	} else {
		// Set the state that the window is hidden
		hidden = YES;
		[self saveFrame];
		[super orderOut:sender];
	}
}

- (NSString *)autosaveName { return self.frameAutosaveName;  }

- (BOOL)setFrameAutosaveName:(NSString *)name {
    BOOL success = [super setFrameAutosaveName:name];
    if (!success) return NO;

    [self setFrameUsingName:self.frameAutosaveName force:YES];
    [self updateTrackingRect:self];
    return YES;
}

- (void)setAutosaveName:(NSString *)newAutosaveName {
    [self setFrameAutosaveName:newAutosaveName];
}
@end
