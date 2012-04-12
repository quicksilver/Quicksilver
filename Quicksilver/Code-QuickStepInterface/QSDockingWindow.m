#import "QSDockingWindow.h"
#import <Carbon/Carbon.h>
#import "QSRegistry.h"

#import "QSTypes.h"

#import <QSFoundation/QSFoundation.h>

@implementation QSDockingWindow
- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
	if (self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag]) {
		[self setOpaque:NO];
		[self center];
		[self setMovableByWindowBackground:YES];
		[self setShowsResizeIndicator:YES];
		hideTimer = nil;
		[self setCanHide:NO];
		[self setLevel:NSFloatingWindowLevel];
		[self setSticky:YES];
		[self setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
		hidden = YES;
		
		NSMutableArray *types = [standardPasteboardTypes mutableCopy];
		[types addObjectsFromArray:[[QSReg objectHandlers] allKeys]];
		[self registerForDraggedTypes:types];
		[types release];
		
		[self updateTrackingRect:self];
	}
	return self;
}

#if 0
- (void)sendEvent:(NSEvent *)theEvent { /*NSLog(@"Event: %@", theEvent);*/ [super sendEvent:theEvent]; }
#endif

- (void)awakeFromNib {
	[self center];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideOrOrderOut:) name:QSActiveApplicationChanged object:nil];
	// Notification for when the menu items list is opened in a docking window (e.g. clipboard menu)
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(lock) name:@"com.apple.HIToolbox.beginMenuTrackingNotification" object:nil];
	// Notification for when the menu item list is closed in a docking window
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(unlock) name:@"com.apple.HIToolbox.endMenuTrackingNotification" object:nil];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[autosaveName release];
	[hideTimer release];
	[super dealloc];
}


- (void)lock {locked = YES;}
- (void)unlock {locked = NO;}

- (unsigned int)draggingEntered:(id <NSDraggingInfo>)theEvent {
	[self show:self];
	return [super draggingEntered:theEvent];
}

- (unsigned int)draggingUpdated:(id <NSDraggingInfo>)theEvent {
	return [super draggingUpdated:theEvent];
}

- (void)draggingExited:(id <NSDraggingInfo>)theEvent {
	lastTime = [NSDate timeIntervalSinceReferenceDate];
	if ([hideTimer isValid]) {
		[hideTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:0.75]];
	} else {
		[hideTimer release];
		hideTimer = [[NSTimer scheduledTimerWithTimeInterval:0.333 target:self selector:@selector(timerHide:) userInfo:nil repeats:YES] retain];
		[hideTimer fire];
	}
	[super draggingExited:theEvent];
}

// mouse entered the docking window
- (void)mouseEntered:(NSEvent *)theEvent {
	// Set time when mouse entered the window
	// Case 1: If the window's a floating window that's hidden, set = 0.0 (allows for case where you mouse over the area where the window was as it's fading)
	// Case 2: If the window's a sliding-into-edge window, always set the time to the current time (it's always 'hidden', so must check for the canFade case)
	if (!hidden || [self canFade]) {
		timeEntered = [NSDate timeIntervalSinceReferenceDate];
	} else {
		timeEntered = 0.0;
	}

	[hideTimer invalidate];
	// Event for mouse exit. untilDate:+0.2s from now chosen as appropriate for holding the mose on the screen edge (trial and error)
	NSEvent *earlyExit = [NSApp nextEventMatchingMask:NSMouseExitedMask untilDate:[NSDate dateWithTimeIntervalSinceNow:0.2] inMode:NSDefaultRunLoopMode dequeue:YES];
	
	// Open the docking window if it's on the edge of the screen
	if ([self canFade] && earlyExit == nil && !locked) {
		[self show:self];
	}
}

- (void)timerHide:(NSTimer *)timer {
	if (!NSMouseInRect([NSEvent mouseLocation], NSInsetRect([self frame], -10, -10), NO)) {
		if ([NSDate timeIntervalSinceReferenceDate] - lastTime > 0.5) {
			[self hideOrOrderOut:self];
			[hideTimer invalidate];
		}
	}
}

// mouse exited the docking window
- (void)mouseExited:(NSEvent *)theEvent {
	
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
	if (!reentry && !StillDown() && (timeExited - timeEntered > 0.2)) {
		[self hideOrOrderOut:self];
	}
}

- (BOOL)canFade {
	return ((int)touchingEdgeForRectInRect([self frame], [[self screen] frame]) >= 0);
}

- (BOOL)canBecomeKeyWindow {
	return !hidden && allowKey;
}

- (BOOL)hidden {return hidden;}

- (IBAction)hideOrOrderOut:(id)sender {
	if ([self canFade]) {
		[self hide:self];
	} else {
		[self orderOut:self];
	}
}

- (void)makeKeyAndOrderFront:(id)sender {
	allowKey = YES;
	[super makeKeyAndOrderFront:sender];
	allowKey = NO;
}

- (IBAction)toggle:(id)sender {
	if (hidden)
		[self show:sender];
	else if ([self isVisible])
		[self hideOrOrderOut:sender];
	else
		[self makeKeyAndOrderFront:sender];
}

- (IBAction)hide:(id)sender {
	[self saveFrame];
	if ([self isKeyWindow])
		[self fakeResignKey];
	int edge = touchingEdgeForRectInRect([self frame], [[self screen] frame]);
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
		[[self helper] _resizeWindow:self toFrame:hideRect alpha:0.1 display:YES];
	} else {
		[self setFrame:hideRect display:YES];
		[self setAlphaValue:0.1];
	}
	[self setHasShadow:NO];
}

- (IBAction)orderFrontHidden:(id)sender {
	if ([self canFade]) {
		[self hide:sender];
		[self reallyOrderFront:self];
	} else {
		[self orderFront:sender];
	}
}
// method to close command window when Esc key is pressed
- (void)keyDown:(NSEvent *)theEvent {
	if ([self canFade] && [theEvent keyCode] == 53)
		[self hideOrOrderOut:nil];
	else
		[super keyDown:theEvent];
}

- (void)performClose:(id)sender {
	[self close];
}

- (IBAction)show:(id)sender {
	[self orderFront:sender];
	[self setHasShadow:YES];
	[[self helper] _resizeWindow:self toFrame:constrainRectToRect([self frame], [[self screen] frame]) alpha:1.0 display:YES];
	hidden = NO;
	[self makeKeyAndOrderFront:self];
}

- (IBAction)showKeyless:(id)sender {
	[self orderFront:sender];
	[self setHasShadow:YES];
	[[self helper] _resizeWindow:self toFrame:constrainRectToRect([self frame], [[self screen] frame]) alpha:1.0 display:YES];
	hidden = NO;
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
	if ([self autosaveName])
		[self saveFrameUsingName:[self autosaveName]];
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
- (NSString *)autosaveName { return autosaveName;  }

- (void)setAutosaveName:(NSString *)newAutosaveName {
	[autosaveName release];
	autosaveName = [newAutosaveName retain];
	[self setFrameUsingName:autosaveName force:YES];
}
@end
