#import "QSDockingWindow.h"
#import <Carbon/Carbon.h>
#import "QSRegistry.h"

#import "QSTypes.h"

#import <QSFoundation/QSFoundation.h>

@implementation QSDockingWindow
- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
	NSWindow *result = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
	[self setOpaque:NO];
	[self center];
	[self setMovableByWindowBackground:YES];
	[self setShowsResizeIndicator:YES];
	hideTimer = nil;
	[self setCanHide:NO];
	[self setLevel:NSFloatingWindowLevel];
    [self setSticky:YES];
    [self setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
    
	NSMutableArray *types = [standardPasteboardTypes mutableCopy];
	[types addObjectsFromArray:[[QSReg objectHandlers] allKeys]];
	[self registerForDraggedTypes:types];
	[types release];

	[self updateTrackingRect:self];
	return result;
}

#if 0
- (void)sendEvent:(NSEvent *)theEvent { /*NSLog(@"Event: %@", theEvent);*/ [super sendEvent:theEvent]; }
#endif

- (void)awakeFromNib {
	[self center];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideOrOrderOut:) name:QSActiveApplicationChanged object:nil];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(lock) name:@"com.apple.HIToolbox.beginMenuTrackingNotification" object:nil];
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

- (void)mouseEntered:(NSEvent *)theEvent {
	[hideTimer invalidate];
	NSEvent *earlyExit = [NSApp nextEventMatchingMask:NSMouseExitedMask untilDate:[NSDate dateWithTimeIntervalSinceNow:0.25] inMode:NSDefaultRunLoopMode dequeue:YES];

	if (!earlyExit && !locked) {
		[self show:self];
	}
	if (!NSMouseInRect([NSEvent mouseLocation], NSInsetRect([self frame], -10, -10), NO) ) {
		[self hideOrOrderOut:self];
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

- (void)mouseExited:(NSEvent *)theEvent {
	NSEvent *reentry = [NSApp nextEventMatchingMask:NSMouseEnteredMask untilDate:[NSDate dateWithTimeIntervalSinceNow:0.333] inMode:NSDefaultRunLoopMode dequeue:NO];
	if ([reentry windowNumber] != [self windowNumber])
		reentry = nil;
	if (!reentry && !StillDown() ) {
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
	if (hidden) return;

	[self saveFrame];
	if ([self isKeyWindow])
		[self fakeResignKey];
	int edge = touchingEdgeForRectInRect([self frame], [[self screen] frame]);
	if (edge < 0)
		return;
	NSArray *screens = [NSScreen screens];
	NSRect hideRect = expelRectFromRectOnEdge([self frame], [[self screen] frame], edge, 1.0); // TESTING: not peeking?
	if ([screens count]) {
		int i;
		for (i = 0; i<[screens count]; i++) {
			if (NSIntersectsRect(NSInsetRect(hideRect, 1, 1), [[screens objectAtIndex:i] frame]) ) return;
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
