#import "QSAlertManager.h"

@interface QSAlertManager () <NSUserNotificationCenterDelegate>

@property (assign) NSInteger returnCode;

@property (retain) NSMutableDictionary *notificationHandlers;

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

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _notificationHandlers = [NSMutableDictionary dictionary];

    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];

    return self;
}

#pragma mark -
#pragma mark NSAlert

- (void)beginAlert:(NSAlert *)alert onWindow:(NSWindow *)window completionHandler:(QSAlertHandler)handler {
    NSParameterAssert(alert != nil);

    QSGCDMainAsync(^{
		NSAlert *mainAlert = [[NSAlert alloc] init];
		mainAlert.alertStyle = alert.alertStyle;
		mainAlert.messageText = alert.messageText;
		mainAlert.informativeText = alert.informativeText;
		mainAlert.icon = alert.icon;
		for (NSButton *button in alert.buttons) {
			[mainAlert addButtonWithTitle:button.title];
		}
		mainAlert.showsHelp = alert.showsHelp;
		mainAlert.helpAnchor = alert.helpAnchor;
		mainAlert.delegate = alert.delegate;
		mainAlert.showsSuppressionButton = alert.showsSuppressionButton;
		mainAlert.accessoryView = alert.accessoryView;

        NSModalResponse response = 0;
        if (window) {
            [mainAlert beginSheetModalForWindow:window completionHandler:^(NSModalResponse response) {
                [NSApp stopModalWithCode:response];
            }];

            response = [NSApp runModalForWindow:window];
        } else {
            response = [mainAlert runModal];
        }

        QSAlertResponse realResponse = response - 1000;

        if (handler) handler(realResponse);
    });
}

- (void)beginAlertWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons style:(NSAlertStyle)style onWindow:(NSWindow *)window completionHandler:(QSAlertHandler)handler {
    NSParameterAssert(title != nil);
    NSParameterAssert(message != nil);

    // Configure the alert
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = title;
    alert.informativeText = message;
    for (NSString *buttonTitle in buttons) {
        [alert addButtonWithTitle:buttonTitle];
    }

    alert.alertStyle = style;

    [self beginAlert:alert onWindow:window completionHandler:handler];
}

- (void)alertDidEnd:(NSAlert *)sheet returnCode:(NSInteger)theReturnCode contextInfo:(void *)contextInfo {
    [NSApp stopModalWithCode:theReturnCode];
}

- (QSAlertResponse)runAlert:(NSAlert *)alert onWindow:(NSWindow *)window {
    __block QSAlertResponse alertResponse = QSAlertResponseOK;
    __block dispatch_semaphore_t alertSemaphore = dispatch_semaphore_create(0);

    [self beginAlert:alert onWindow:window completionHandler:^(QSAlertResponse response) {
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

- (QSAlertResponse)runAlertWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons style:(NSAlertStyle)style attachToWindow:(NSWindow *)window {
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

    return [self runAlert:alert onWindow:window];
}

// FIXME: This (and the property) can die when we're sure the QSRun.*Sheet functions are gone
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    self.returnCode = returnCode;
    [NSApp stopModal];
}

- (void)notifyWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons completionHandler:(QSAlertHandler)handler {
    NSUserNotification *notif = [[NSUserNotification alloc] init];
    notif.title = title;
    notif.informativeText = message;

    if (buttons.count > 0) {
        notif.actionButtonTitle = buttons[0];
    }
    if (buttons.count > 1) {
        notif.otherButtonTitle = buttons[1];
    }

    [self notifyWithNotification:notif completionHandler:handler];
}

- (void)notifyWithNotification:(NSUserNotification *)notif completionHandler:(QSAlertHandler)handler {
	NSParameterAssert(notif != nil);

    if (!notif.identifier) {
        notif.identifier = [[NSUUID UUID] UUIDString];
    }

    self.notificationHandlers[notif.identifier] = handler;

    [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notif];
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    QSAlertHandler handler = self.notificationHandlers[notification.identifier];

    QSAlertResponse response = QSAlertResponseOK;
    // Convert activation type to alert response
    switch (notification.activationType) {
        case NSUserNotificationActivationTypeContentsClicked:
            response = QSAlertResponseFirst;
            break;

        case NSUserNotificationActivationTypeActionButtonClicked:
            response = QSAlertResponseOK;
            break;

		case NSUserNotificationActivationTypeAdditionalActionClicked:
			response = QSAlertResponseCancel;
			break;
			
        default:
            break;
    }

    if (handler) handler(response);

    [self.notificationHandlers removeObjectForKey:notification.identifier];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    // For now, always notify
    return YES;
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
	return response;
}

NSInteger QSRunAlertSheet(NSWindow *attachToWin, NSString *title, NSString *msg, NSString *defaultButton, NSString *alternateButton, NSString *otherButton) {
    return _QSRunSheet(attachToWin, title, msg, defaultButton, alternateButton, otherButton, NSWarningAlertStyle);
}

NSInteger QSRunInformationalAlertSheet(NSWindow *attachToWin, NSString *title, NSString *msg, NSString *defaultButton, NSString *alternateButton, NSString *otherButton) {
    return _QSRunSheet(attachToWin, title, msg, defaultButton, alternateButton, otherButton, NSAlertStyleInformational);
}

NSInteger QSRunCriticalAlertSheet(NSWindow *attachToWin, NSString *title, NSString *msg, NSString *defaultButton, NSString *alternateButton, NSString *otherButton) {
    return _QSRunSheet(attachToWin, title, msg, defaultButton, alternateButton, otherButton, NSCriticalAlertStyle);
}
