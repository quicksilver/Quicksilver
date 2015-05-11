#import "QSAlertManager.h"

@interface QSAlertManager ()

@property (assign) NSInteger returnCode;

@end

@implementation QSAlertManager

+ (instancetype)defaultManager {
    static QSAlertManager *defaultManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultManager = [[self alloc] init];
    });
    return defaultManager;
}

#pragma mark -
#pragma mark NSAlert

- (void)beginAlert:(NSAlert *)alert onWindow:(NSWindow *)window completionHandler:(void (^)(NSModalResponse response))handler {
    NSParameterAssert(alert != nil);

    QSGCDMainAsync(^{
        NSModalResponse response = NSAlertErrorReturn;
        if (window && [alert respondsToSelector:@selector(beginSheetModalForWindow:completionHandler:)]) {
            [alert beginSheetModalForWindow:window completionHandler:^(NSModalResponse response) {
                [NSApp stopModalWithCode:response];
            }];

            response = [NSApp runModalForWindow:window];
        } else if (window) {
            [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];

            response = [NSApp runModalForWindow:window];
        } else {
            response = [alert runModal];
        }

        if (handler) handler(response);
    });
}

- (void)alertDidEnd:(NSAlert *)sheet returnCode:(NSInteger)theReturnCode contextInfo:(void *)contextInfo {
    [NSApp stopModalWithCode:theReturnCode];
}

- (NSModalResponse)runAlert:(NSAlert *)alert onWindow:(NSWindow *)window {
    __block NSModalResponse alertResponse = NSAlertErrorReturn;
    __block dispatch_semaphore_t alertSemaphore = dispatch_semaphore_create(0);

    [self beginAlert:alert onWindow:window completionHandler:^(NSModalResponse response) {
        alertResponse = response;
        dispatch_semaphore_signal(alertSemaphore);
    }];

    // Now let's mostly-busy loop while we wait for the semaphore above to get signaled
    long result = 0;
    do {
        [[NSRunLoop mainRunLoop] runMode:NSModalPanelRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:5]];
        result = dispatch_semaphore_wait(alertSemaphore, DISPATCH_TIME_NOW);
    } while (result != 0);

    return alertResponse;
}

- (NSModalResponse)runAlertWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons style:(NSAlertStyle)style attachToWindow:(NSWindow *)window {
    NSParameterAssert(title != nil);
    NSParameterAssert(buttons != nil);
    NSAssert(buttons.count > 1, @"Must have at least one button");

    // Configure the alert
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = title;
    alert.informativeText = message;
    for (NSString *buttonTitle in buttons) {
        [alert addButtonWithTitle:buttonTitle];
    }

    alert.alertStyle = style;

    return [self runAlert:alert onWindow:window];
}

// FIXME: This (and the property) can die when we're sure the QSRun.*Sheet functions are gone
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    self.returnCode = returnCode;
    [NSApp stopModal];
}

@end

// Eeek. This doesn't eve uses its parameters...
NSInteger QSRunSheet(id panel, NSWindow *attachToWin, NSString *title, NSString *msg, NSString *defaultButton, NSString *alternateButton, NSString *otherButton) {
    NSInteger result;
    @synchronized ([QSAlertManager defaultManager]) {
        [NSApp beginSheet:panel modalForWindow:attachToWin modalDelegate:[QSAlertManager defaultManager] didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
        [NSApp runModalForWindow:panel];
        [NSApp endSheet:panel];
        [panel orderOut:nil];
        NSReleaseAlertPanel(panel);
        result = [[QSAlertManager defaultManager] returnCode];
    }
    return result;
}

NSInteger _QSRunSheet(NSWindow *attachToWin, NSString *title, NSString *msg, NSString *defaultButton, NSString *alternateButton, NSString *otherButton, NSAlertStyle style) {
    NSMutableArray *buttons = [[NSMutableArray alloc] initWithCapacity:3];
    if (defaultButton)   [buttons addObject:defaultButton];
    if (alternateButton) [buttons addObject:alternateButton];
    if (otherButton)     [buttons addObject:otherButton];

    NSModalResponse response = [[QSAlertManager defaultManager] runAlertWithTitle:title message:msg buttons:buttons style:style attachToWindow:attachToWin];

    // Convert our response to the old NSPanel values
    // New-style
    //    NSAlertDefaultReturn means the user pressed the default button.
    //    NSAlertAlternateReturn means the user pressed the alternate button.
    //    NSAlertOtherReturn means the user pressed the other button.
    //    NSAlertErrorReturn means an error occurred while running the alert panel.
    // Old-style
    //    NSAlertFirstButtonReturn	= 1000,
    //    NSAlertSecondButtonReturn	= 1001,
    //    NSAlertThirdButtonReturn	= 1002

    if (response == NSAlertFirstButtonReturn) {
        return NSAlertDefaultReturn;
    } else if (response == NSAlertSecondButtonReturn) {
        return NSAlertOtherReturn;
    } else if (response == NSAlertThirdButtonReturn) {
        return NSAlertAlternateReturn;
    }
    return NSAlertErrorReturn;
}

NSInteger QSRunAlertSheet(NSWindow *attachToWin, NSString *title, NSString *msg, NSString *defaultButton, NSString *alternateButton, NSString *otherButton) {
    return _QSRunSheet(attachToWin, title, msg, defaultButton, alternateButton, otherButton, NSWarningAlertStyle);
}

NSInteger QSRunInformationalAlertSheet(NSWindow *attachToWin, NSString *title, NSString *msg, NSString *defaultButton, NSString *alternateButton, NSString *otherButton) {
    return _QSRunSheet(attachToWin, title, msg, defaultButton, alternateButton, otherButton, NSInformationalAlertStyle);
}

NSInteger QSRunCriticalAlertSheet(NSWindow *attachToWin, NSString *title, NSString *msg, NSString *defaultButton, NSString *alternateButton, NSString *otherButton) {
    return _QSRunSheet(attachToWin, title, msg, defaultButton, alternateButton, otherButton, NSCriticalAlertStyle);
}
