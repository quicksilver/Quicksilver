#import "QSPrimerInterfaceController.h"

#define DIFF 84

@implementation QSPrimerInterfaceController


- (id)init {
	self = [super initWithWindowNibName:@"Primer"];
	if (self) {

	}
	return self;
}

- (void)windowDidLoad {
	[super windowDidLoad];
	// logRect([[self window] frame]);
	[[self window] addInternalWidgetsForStyleMask:NSUtilityWindowMask closeOnly:YES];
	[[self window] setLevel:NSPopUpMenuWindowLevel];
	[[self window] setFrameAutosaveName:@"PrimerInterfaceWindow"];
    
	//  [[self window] setFrame:constrainRectToRect([[self window] frame] , [[[self window] screen] visibleFrame]) display:NO];
	//	[(QSWindow *)[self window] setHideOffset:NSMakePoint(0, -99)];
	//   [(QSWindow *)[self window] setShowOffset:NSMakePoint(0, 99)];
	[[self window] setHasShadow:YES];

	QSWindow *window = (QSWindow*)[self window];
	[window setHideOffset:NSMakePoint(0, 0)];
	[window setShowOffset:NSMakePoint(0, 0)];

	[dSelector setResultsPadding:2];
	[aSelector setResultsPadding:2];
	[iSelector setResultsPadding:2];
	//	[window setFastShow:YES];
	[window setShowEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSVExpandEffect", @"transformFn", @"show", @"type", [NSNumber numberWithDouble:0.15] , @"duration", nil]];
	//	[window setHideEffect:[NSDictionary dictionaryWithObjectsAndKeys:@"QSShrinkEffect", @"transformFn", @"hide", @"type", [NSNumber numberWithFloat:.25] , @"duration", nil]];

	[window setWindowProperty:[NSDictionary dictionaryWithObjectsAndKeys:@"QSExplodeEffect", @"transformFn", @"hide", @"type", [NSNumber numberWithDouble:0.2] , @"duration", nil]
					   forKey:kQSWindowExecEffect];

	[window setWindowProperty:[NSDictionary dictionaryWithObjectsAndKeys:@"hide", @"type", [NSNumber numberWithDouble:0.15] , @"duration", nil]
					   forKey:kQSWindowFadeEffect];

	[window setWindowProperty:[NSDictionary dictionaryWithObjectsAndKeys:@"QSVContractEffect", @"transformFn", @"hide", @"type", [NSNumber numberWithDouble:0.333] , @"duration", nil, [NSNumber numberWithDouble:0.25] , @"brightnessB", @"QSStandardBrightBlending", @"brightnessFn", nil]
					   forKey:kQSWindowCancelEffect];


	//  standardRect = [[self window] frame] , [[NSScreen mainScreen] frame]);

	// [setHidden:![NSApp isUIElement]];


	// [[[self window] _borderView] _resetDragMargins];
	//  */
	//   [self contractWindow:self];
}

- (void)updateViewLocations {
	[super updateViewLocations];
	//   [[[self window] contentView] display];
}


- (void)hideMainWindow:(id)sender {

	[[self window] saveFrameUsingName:@"PrimerInterfaceWindow"];

	[super hideMainWindow:sender];
}

- (void)showMainWindow:(id)sender {
	NSRect frame = [[self window] frame];
	frame = constrainRectToRect(frame, [[[self window] screen] frame]);
	[[self window] setFrame:frame display:YES];

	if (defaultBool(@"QSAlwaysCenterInterface") ) {
		NSRect frame = [[self window] frame];
		frame = centerRectInRect(frame, [[[self window] screen] frame]);
		[[self window] setFrame:frame display:YES];
	}

	[super showMainWindow:(id)sender];
}
- (NSSize) maxIconSize {
	return QSSize256;
}
- (NSRect) window:(NSWindow *)window willPositionSheet:(NSWindow *)sheet usingRect:(NSRect)rect {
	//
	return NSOffsetRect(NSInsetRect(rect, 8, 0), 0, 0);
	//return NSMakeRect(0, 0, NSWidth(rect), 0);
}




- (void)hideIndirectSelector:(id)sender {
	//[super hideIndirectSelector:sender];

	[indirectView setHidden:YES];

	[self adjustWindow:nil];
}


- (void)showIndirectSelector:(id)sender {

	if ([indirectView isHidden]) {
		[(QSFadingView*)indirectView setOpacity:0.0];
		[indirectView setHidden:NO];

		//  [super showIndirectSelector:sender];

		[self adjustWindow:nil];
	}
}

- (void)expandWindow:(id)sender {
	//return nil;
	NSRect expandedRect = [[self window] frame];

	// float diff = 28;
	expandedRect.size.height += DIFF;
	expandedRect.origin.y -= DIFF;
	constrainRectToRect(expandedRect, [[[self window] screen] frame]);
	if (!expanded)
		[[self window] setFrame:expandedRect display:YES animate:YES];
	[super expandWindow:sender];
	[(QSFadingView*)indirectView setOpacity:1.0];
}

- (void)contractWindow:(id)sender {

	NSRect contractedRect = [[self window] frame];

	contractedRect.size.height -= DIFF;
	contractedRect.origin.y += DIFF;
	//   NSLog(@"expnded? %d", expanded);
	if (expanded)
		[[self window] setFrame:contractedRect display:YES animate:YES];

	[super contractWindow:sender];
}


- (void)searchObjectChanged:(NSNotification*)notif {
	[super searchObjectChanged:notif];
	//	[self updateDetailsString];
	NSString *commandName = [[self currentCommand] name];
	if (!commandName) commandName = @"";
	[commandView setStringValue:([dSelector objectValue] ? commandName : @"Begin typing in the Subject field to search")];
}

- (void)updateDetailsString {
	NSString *commandName = [[self currentCommand] name];
	[commandView setStringValue:(commandName ? commandName : @"")];
	return;
	NSResponder *firstResponder = [[self window] firstResponder];
	if ([firstResponder respondsToSelector:@selector(objectValue)]) {
		id object = [firstResponder performSelector:@selector(objectValue)];
		if ([object respondsToSelector:@selector(details)]) {
			NSString *string = [object details];
			if (string) {
				[commandView setStringValue:string];
				return;
			}
		}
	}
	[commandView setStringValue:[[self currentCommand] name]];
}

- (void)searchView:(QSSearchObjectView *)view changedString:(NSString *)string {
	//	NSLog(@"string %@ %@", string, view);

    if (!string) return;

    if (view == dSelector)
        [dSearchText setStringValue:string];
    if (view == aSelector)
        [aSearchText setStringValue:string];
    if (view == iSelector)
        [iSearchText setStringValue:string];
}

- (void)searchView:(QSSearchObjectView *)view changedResults:(NSArray *)array {
	//	NSLog(@"string %@ %@", string, view);
	NSInteger count = [array count];
    NSBundle *selfBundle = [NSBundle bundleForClass:[self class]];

    NSString *string = nil;
    if (view == aSelector) {
        switch (count) {
            case 0:
                string = @"No actions";
                break;
            case 1:
                string = @"1 action";
                break;
            default:
                string = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%lu actions", nil, selfBundle, @""), count];
                break;
        }
    } else {
        switch (count) {
            case 0:
                string = @"No items";
                break;
            case 1:
                string = @"1 item";
                break;
            default:
                string = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%lu items", nil, selfBundle, @""), count];
                break;
        }
    }

	if (string) {
		if (view == dSelector)
			[dSearchCount setStringValue:string];
		if (view == aSelector)
			[aSearchCount setStringValue:string];
		if (view == iSelector)
			[iSearchCount setStringValue:string];

	}
}

- (void)searchView:(QSSearchObjectView *)view resultsVisible:(BOOL)resultsVisible {
	if (view == dSelector)
		[dSearchResultDisclosure setState:resultsVisible];
	if (view == aSelector)
		[aSearchResultDisclosure setState:resultsVisible];
	if (view == iSelector)
		[iSearchResultDisclosure setState:resultsVisible];
}


@end
