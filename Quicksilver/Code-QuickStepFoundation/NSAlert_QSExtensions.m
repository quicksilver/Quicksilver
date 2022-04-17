#import "NSAlert_QSExtensions.h"

@implementation NSAlert (QSExtensions)

#pragma mark -

- (QSAlertResponse)runAlert {
	return [self runModal] - 1000;
}

+ (QSAlertResponse)runAlertWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons style:(NSAlertStyle)style {
    NSParameterAssert(title != nil);
    NSParameterAssert(buttons != nil);
    NSAssert(buttons.count >= 1, @"Must have at least one button");

    // Configure the alert
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = title;
    alert.informativeText = message;
    for (NSString *buttonTitle in buttons) {
        [alert addButtonWithTitle:buttonTitle];
    }

    alert.alertStyle = style;

    return [alert runAlert];
}

- (QSAlertResponse)runModalSheetForWindow:(NSWindow *)window {
	// Set ourselves as the target for button clicks
	for (NSButton *button in [self buttons]) {
		[button setTarget:self];
		[button setAction:@selector(QS_stopSynchronousSheet:)];
	}
	
	// Bring up the sheet and wait until stopSynchronousSheet is triggered by a button click
	[self performSelectorOnMainThread:@selector(QS_beginSheetModalForWindow:) withObject:window waitUntilDone:YES];
	NSInteger modalCode = [NSApp runModalForWindow:[self window]];
	
	// This is called only after stopSynchronousSheet is called (that is,
	// one of the buttons is clicked)
	[NSApp performSelectorOnMainThread:@selector(endSheet:) withObject:[self window] waitUntilDone:YES];
	
	// Remove the sheet from the screen
	[[self window] performSelectorOnMainThread:@selector(orderOut:) withObject:self waitUntilDone:YES];
	
	return modalCode - 1000;
}

#pragma mark Private methods

-(IBAction)QS_stopSynchronousSheet:(id)sender {
	// See which of the buttons was clicked
	NSUInteger clickedButtonIndex = [[self buttons] indexOfObject:sender];
	
	// Be consistent with Apple's documentation (see NSAlert's addButtonWithTitle) so that
	// the fourth button is numbered NSAlertThirdButtonReturn + 1, and so on
	//
	// TODO: handle case when alert created with alertWithMessageText:... where the buttons
	//       have values NSAlertDefaultReturn, NSAlertAlternateReturn, ... instead (see also
	//       the documentation for the runModal method)
	NSInteger modalCode = 0;
	if (clickedButtonIndex == NSAlertFirstButtonReturn)
		modalCode = NSAlertFirstButtonReturn;
	else if (clickedButtonIndex == NSAlertSecondButtonReturn)
		modalCode = NSAlertSecondButtonReturn;
	else if (clickedButtonIndex == NSAlertThirdButtonReturn)
		modalCode = NSAlertThirdButtonReturn;
	else
		modalCode = NSAlertThirdButtonReturn + (clickedButtonIndex - 2);
	
	[NSApp stopModalWithCode:modalCode];
}

-(void) QS_beginSheetModalForWindow:(NSWindow *)aWindow {
	[self beginSheetModalForWindow:aWindow completionHandler:nil];
}

@end
