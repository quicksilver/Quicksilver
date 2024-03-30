#import "QSBezelInterfaceController.h"

@implementation QSBezelInterfaceController

- (id)init {
	return [self initWithWindowNibName:@"QSBezelInterface"];
}

- (void)windowDidLoad {
	standardRect = centerRectInRect([[self window] frame], [[NSScreen mainScreen] frame]);

	[super windowDidLoad];
	QSWindow *window = (QSWindow *)[self window];
	[window setLevel:NSPopUpMenuWindowLevel];
	[window setBackgroundColor:[NSColor clearColor]];
	
	[window setHideOffset:NSMakePoint(0, 0)];
	[window setShowOffset:NSMakePoint(0, 0)];

	[window setWindowProperty:[NSDictionary dictionaryWithObjectsAndKeys:@"QSExplodeEffect", @"transformFn", @"hide", @"type", [NSNumber numberWithDouble:0.15], @"duration", nil] forKey:kQSWindowExecEffect];
	[window setWindowProperty:[NSDictionary dictionaryWithObjectsAndKeys:@"hide", @"type", [NSNumber numberWithDouble:0.15], @"duration", nil] forKey:kQSWindowFadeEffect];
	[window setWindowProperty:[NSDictionary dictionaryWithObjectsAndKeys:@"QSVContractEffect", @"transformFn", @"hide", @"type", [NSNumber numberWithDouble:0.25], @"duration", nil, [NSNumber numberWithDouble:0.25] , @"brightnessB", @"QSStandardBrightBlending", @"brightnessFn", nil] forKey:kQSWindowCancelEffect];

	[(QSBezelBackgroundView *)[[self window] contentView] setRadius:12.0];
	[(QSBezelBackgroundView *)[[self window] contentView] setGlassStyle:QSGlossUpArc];

	[[self window] setFrame:standardRect display:YES];

	[[[self window] contentView] bind:@"color" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.QSAppearance1B" options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:NSValueTransformerNameBindingOption]];
	[[self window] bind:@"hasShadow" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.QSBezelHasShadow" options:nil];
	[details bind:@"textColor" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.QSAppearance1T" options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:NSValueTransformerNameBindingOption]];
	[commandView bind:@"textColor" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.QSAppearance1T" options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:NSValueTransformerNameBindingOption]];

	[[self window] setMovableByWindowBackground:NO];
	[(QSWindow *)[self window] setFastShow:YES];

	NSArray *theControls = [NSArray arrayWithObjects:dSelector, aSelector, iSelector, nil];
	for(QSSearchObjectView *theControl in theControls) {
		QSObjectCell *theCell = [theControl cell];
		[theCell setAlignment:NSCenterTextAlignment];
		[theControl setResultsPadding:NSMinY([dSelector frame])];
		[theControl setPreferredEdge:NSMinYEdge];
		[(QSWindow *)[(theControl)->resultController window] setHideOffset:NSMakePoint(0, NSMinY([iSelector frame]))];
		[(QSWindow *)[(theControl)->resultController window] setShowOffset:NSMakePoint(0, NSMinY([dSelector frame]))];

		[theCell setShowDetails:NO];
		[theCell setTextColor:[NSColor whiteColor]];
		[theCell setState:NSOnState];

        [theCell setCellRadiusFactor:16];
        
		[theCell bind:@"highlightColor" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.QSAppearance1A" options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:NSValueTransformerNameBindingOption]];
		[theCell bind:@"textColor" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.QSAppearance1T" options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:NSValueTransformerNameBindingOption]];
	 }

	[self contractWindow:nil];
}

- (void)dealloc {
	if ([self isWindowLoaded]) {
		[[[self window] contentView] unbind:@"color"];
		[[self window] unbind:@"hasShadow"];
		[details unbind:@"textColor"];
		[commandView unbind:@"textColor"];
		NSArray *theControls = [NSArray arrayWithObjects:dSelector, aSelector, iSelector, nil];
		for(NSControl * theControl in theControls) {
			NSCell *theCell = [theControl cell];
			[theCell unbind:@"highlightColor"];
			[theCell unbind:@"textColor"];
			[(QSObjectCell *)theCell setTextColor:nil];
			[(QSObjectCell *)theCell setHighlightColor:nil];
		}
	}
}


- (NSSize) maxIconSize {
	return QSSize256;
}

- (void)showMainWindow:(id)sender {
	[[self window] setFrame:[self rectForState:[self expanded]]  display:YES];
	[super showMainWindow:sender];
//    Does this need to be here?
	[[[self window] contentView] setNeedsDisplay:YES];
}

- (void)expandWindow:(id)sender {
	if (![self expanded])
		[[self window] setFrame:[self rectForState:YES] display:YES animate:YES];
	[super expandWindow:sender];
}
- (void)contractWindow:(id)sender {
	if ([self expanded])
		[[self window] setFrame:[self rectForState:NO] display:YES animate:YES];
	[super contractWindow:sender];
}

- (NSRect) rectForState:(BOOL)shouldExpand {
	NSRect newRect = standardRect;
	NSRect screenRect = [[NSScreen mainScreen] frame];
	if (!shouldExpand) {
		newRect.size.width -= NSMaxX([iSelector frame]) -NSMaxX([aSelector frame]);
		newRect = centerRectInRect(newRect, [[NSScreen mainScreen] frame]);
	}
	return NSOffsetRect(centerRectInRect(newRect, screenRect), 0, NSHeight(screenRect) /8);
}

- (NSRect)window:(NSWindow *)window willPositionSheet:(NSWindow *)sheet usingRect:(NSRect)rect {
	return NSOffsetRect(NSInsetRect(rect, 8, 0), 0, -21);
}

- (void)updateDetailsString {
	NSControl *firstResponder = (NSControl *)[[self window] firstResponder];
	if ([firstResponder respondsToSelector:@selector(objectValue)]) {
		id object = [firstResponder objectValue];
		NSString *string = [object details];
		if ([object respondsToSelector:@selector(details)] && string) {
			[details setStringValue:string];
			return;
		}
	}
	[details setStringValue:@""];
}

- (void)firstResponderChanged:(NSResponder *)aResponder {
	[super firstResponderChanged:aResponder];
	[self updateDetailsString];
}

- (void)searchObjectChanged:(NSNotification*)notif {
	[super searchObjectChanged:notif];
    if ([[notif object] isKindOfClass:[QSCollectingSearchObjectView class]]) {
        [self updateDetailsString];
    }
}

-(NSTimeInterval)animationResizeTime:(NSRect)newWindowFrame
{
	return 0.01;
}

@end