#import "QSWindow.h"

#import "QSWindowAnimation.h"
#import "QSPreferenceKeys.h"

@interface NSWindow (QSAppKitPrivate)

- (void)_hideAllDrawers;
- (void)_unhideAllDrawers;

@end


@implementation QSWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
	if (self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag]) {
		[self setMovableByWindowBackground:YES];
		[self setHasShadow:YES];
		[self setLevel:NSNormalWindowLevel];
        [self useQuicksilverCollectionBehavior];
		[self setShowOffset:NSMakePoint(0, 50)];
		[self setHideOffset:NSMakePoint(0, -50)];
		trueRect = contentRect;
	}
	return self;
}

- (BOOL)makeFirstResponder:(NSResponder *)aResponder {
    if (aResponder == [self firstResponder]) {
        return YES;
    }
	BOOL responderChanged = [super makeFirstResponder:aResponder];
	if (responderChanged && [(NSObject *)[self delegate] respondsToSelector:@selector(firstResponderChanged:)])
		[[self delegate] firstResponderChanged:aResponder];
	return responderChanged;
}

- (void)sendEvent:(NSEvent *)theEvent {
//	[self retain];
	if (delegatesEvents && [(NSObject *)[self delegate] respondsToSelector:@selector(shouldSendEvent:)] && ![[self delegate] shouldSendEvent:theEvent])
		return;
	if (eventDelegates) {
		for(id eDelegate in eventDelegates) {
			if ([eDelegate respondsToSelector:@selector(shouldSendEvent:)] && ![eDelegate shouldSendEvent:theEvent])
				return;
		}
	}
	[super sendEvent:theEvent];
//	[self release];
}

- (BOOL)allowsConcurrentViewDrawing {
	return NO;
}

- (void)reallySendEvent:(NSEvent *)theEvent {
	[super sendEvent:theEvent];
}

- (NSTimeInterval) animationResizeTime:(NSRect)newFrame {
	return MAX([super animationResizeTime:newFrame] / 3, 0.125);
}

- (BOOL)acceptsFirstResponder {
	return YES;
}

- (BOOL)canBecomeKeyWindow {
	return YES;
}

- (BOOL)canBecomeMainWindow {
    if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible]) {
        [[QLPreviewPanel sharedPreviewPanel] orderOut:nil];
    }
	return YES;
}

- (void)performMiniaturize:(id)sender {
	[self miniaturize:sender];
}

- (void)orderOut:(id)sender {
	[NSApp preventWindowOrdering];
	if ([self isVisible] && [[NSUserDefaults standardUserDefaults] boolForKey:kUseEffects]) {
		[self hideThreaded:sender];
	} else
		[super orderOut:sender];
}

- (void)reallyOrderFront:(id)sender {
	[super orderFront:sender];
}

- (void)reallyOrderOut:(id)sender {
	[super orderOut:sender];
}

- (void)orderFront:(id)sender {
	if ([self isVisible] || fastShow || ![[NSUserDefaults standardUserDefaults] boolForKey:kUseEffects]) {
		[self setAlphaValue:1.0];
		[super orderFront:sender];
	} else {
		[self setAlphaValue:0.0];
		[super orderFront:sender];
		[super display];
		[self showThreaded:self];
	}
}

- (void)makeKeyAndOrderFront:(id)sender {
	if ([self isVisible] || fastShow || ![[NSUserDefaults standardUserDefaults] boolForKey:kUseEffects]) {
		[self setAlphaValue:1.0];
		[super makeKeyAndOrderFront:sender];
	} else {
		[self setAlphaValue:0.0];
		[super makeKeyAndOrderFront:sender];
		[self showThreaded:self];
	}
}

- (void)finishShow:(id)sender {
	[self setAlphaValue:1.0];
	if ([self drawers])
		[self performSelector:@selector(_unhideAllDrawers)];
}

- (void)performEffect:(NSDictionary *)effect {
	[[QSWindowAnimation effectWithWindow:self attributes:effect] startAnimation];
}

- (void)showWithEffect:(id)showEffect {
	trueRect = [self frame];
	if (!showEffect) {
		showEffect = [self showEffect];
	}
	if (!showEffect) {
		showEffect = [NSDictionary dictionaryWithObjectsAndKeys:@"QSDefaultGrowEffect", @"transformFn", @"show", @"type", [NSNumber numberWithDouble:0.2] , @"duration", nil];
	}
	if (showEffect) {
		//[self disableScreenUpdatesUntilFlush];
		id hl = [QSWindowAnimation effectWithWindow:self attributes:showEffect];
		[hl setDelegate:self];
	//	[hl setTarget:self];
	//	[hl setAction:@selector(finishShow:)];
		[hl startAnimation];
	} else {
		[self setFrame:NSOffsetRect(trueRect, showOffset.x, showOffset.y) display:YES animate:NO];
		[self resizeToFrame:trueRect alpha:1.0 display:YES completionHandler:^{
			[self finishShow:self];
		}];
		//NSLog(@"show");
	}
}

- (IBAction)showThreaded:(id)sender {
	[self showWithEffect:[self showEffect]];
}

- (BOOL)animationIsValid {return !animationInvalid;}

- (void)animationDidEnd:(NSAnimation*)animation {
	NSString *type = [(QSWindowAnimation *)animation type];
	if ([type isEqualToString:@"hide"]) {
		[self finishHide:animation];
	} else if ([type isEqualToString:@"show"]) {
		[self finishShow:animation];
	}
}

- (void)finishHide:(id)sender {
	[super orderOut:sender];
	if (hadShadow)
		[self setHasShadow:YES];
	[self setFrame:trueRect display:NO animate:NO];
	[self setAlphaValue:0.0];
}

- (IBAction)hideThreaded:(id)sender {
	[self hideWithEffect:[self hideEffect]];
}

- (void)hideWithEffect:(id)hideEffect {
	if ([self drawers]) {
		[self performSelector:@selector(_hideAllDrawers)];
	}

	trueRect = [self frame];
	hadShadow = [self hasShadow];

	[self setHasShadow:NO];
	if (!hideEffect) {
		hideEffect = [NSDictionary dictionaryWithObjectsAndKeys:@"QSDefaultShrinkEffect", @"transformFn", @"hide", @"type", [NSNumber numberWithDouble:0.2] , @"duration", nil];
	}
	if (hideEffect) {
		id hl = [QSWindowAnimation effectWithWindow:self attributes:hideEffect];
		[hl setDelegate:self];
		[hl startAnimation];
	} else {
		[self resizeToFrame:NSOffsetRect(trueRect, hideOffset.x, hideOffset.y) alpha:0.0 display:YES completionHandler:^{
			[self finishHide:self];
		}];
	}
}

//#define RESIZE_SIZE 16

- (NSPoint)hideOffset { return hideOffset;  }
- (void)setHideOffset:(NSPoint)newHideOffset {
	hideOffset = newHideOffset;
}

- (NSPoint)showOffset { return showOffset;  }
- (void)setShowOffset:(NSPoint)newShowOffset {
	showOffset = newShowOffset;
}

- (char) _hasMainAppearance {
	return YES;
}

- (NSImage *)_gradientImage {
	return nil;
}

- (char) _scalesBackgroundHorizontally {
	return NO;
}

- (char) _hasGradientBackground {
	return YES;
}

- (BOOL)isKeyWindow {
	return [super isKeyWindow] && !liesAboutKey;
}

- (void)fakeResignKey {
	NSDisableScreenUpdates();
	[super orderOut:self];
	[super orderFront:self];
	NSEnableScreenUpdates();
}

- (BOOL)liesAboutKey { return liesAboutKey;  }
- (void)setLiesAboutKey:(BOOL)flag {
	liesAboutKey = flag;
}

- (BOOL)fastShow { return fastShow;  }
- (void)setFastShow:(BOOL)flag {
	fastShow = flag;
}

- (BOOL)delegatesEvents { return delegatesEvents;  }
- (void)setDelegatesEvents:(BOOL)flag {
	delegatesEvents = flag;
}

- (NSMutableDictionary *)mutableProperties {
	if (!properties) {
		properties = [[NSMutableDictionary alloc] init];
	} else if (![properties isKindOfClass:[NSMutableDictionary class]]) {
		properties = [properties mutableCopy];
	}
	return properties;
}

- (NSMutableDictionary *)properties {
	return properties;
}

- (id)windowPropertyForKey:(NSString *)key {return[properties objectForKey:key];}

- (void)setWindowProperty:(id)prop forKey:(NSString *)key {
	if (key){
		if (prop)
			[[self mutableProperties] setObject:prop forKey:key];
		else
			[[self mutableProperties] removeObjectForKey:key];
	}
}

- (id)hideEffect { return [properties objectForKey:kQSWindowHideEffect];  }

- (void)setHideEffect:(id)aHideEffect {
	[self setWindowProperty:aHideEffect forKey:kQSWindowHideEffect];
}

- (id)showEffect { return [properties objectForKey:kQSWindowShowEffect];  }

- (void)setShowEffect:(id)aShowEffect {
	[self setWindowProperty:aShowEffect forKey:kQSWindowShowEffect];
}

- (void)setProperties:(NSMutableDictionary *)newProperties {
	if(newProperties != properties){
		properties = newProperties;
	}
}

- (void)addEventDelegate:(id)eDelegate {
	if (!eventDelegates)
		eventDelegates = [[NSMutableArray alloc] init];
	[eventDelegates addObject:eDelegate];
}

- (void)removeEventDelegate:(id)eDelegate {
	[eventDelegates removeObject:eDelegate];
	if (![eventDelegates count]) {
		eventDelegates = nil;
	}
}

- (id <QSWindowDelegate>)delegate {
    return (id <QSWindowDelegate>)[super delegate];
}

- (void)setDelegate:(id <QSWindowDelegate>)delegate {
    [super setDelegate:(id <NSWindowDelegate>)delegate];
}

@end

@implementation QSBorderlessWindow
- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
	if (self = [super initWithContentRect:contentRect styleMask:NSNonactivatingPanelMask | NSBorderlessWindowMask | NSClosableWindowMask backing:bufferingType defer:YES]) {
		[self setBackgroundColor:[NSColor clearColor]];
		[self setOpaque:NO];
	}
	return self;
}
@end
