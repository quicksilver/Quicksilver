#import <Foundation/Foundation.h>

#define QSAlert [QSAlertManager defaultManager]

NSInteger QSRunSheet(id panel, NSWindow *attachToWin, NSString *title, NSString *msg, NSString *defaultButton, NSString *alternateButton, NSString *otherButton) QS_DEPRECATED;
NSInteger QSRunAlertSheet(NSWindow *attachToWin, NSString *title, NSString *msg, NSString *defaultButton, NSString *alternateButton, NSString *otherButton) QS_DEPRECATED;
NSInteger QSRunInformationalAlertSheet(NSWindow *attachToWin, NSString *title, NSString *msg, NSString *defaultButton, NSString *alternateButton, NSString *otherButton) QS_DEPRECATED;
NSInteger QSRunCriticalAlertSheet(NSWindow *attachToWin, NSString *title, NSString *msg, NSString *defaultButton, NSString *alternateButton, NSString *otherButton) QS_DEPRECATED;

@interface QSAlertManager : NSObject

/**
 *  Our singleton
 *
 *  @return The default alert manager.
 */
+ (instancetype)defaultManager;

/**
 *  Display an alert asynchronously.
 *
 *  @param alert   Mandatory, the alert to display.
 *  @param window  An (optional) window to which the alert will be attached.
 *  @param handler The completion block to call.
 */
- (void)beginAlert:(NSAlert *)alert onWindow:(NSWindow *)window completionHandler:(void (^)(NSModalResponse response))handler;

/**
 *  Display an alert synchronously
 *
 *  @param alert  Mandatory, the alert to display.
 *  @param window An (optional) window to which the alert will be attached.
 *
 *  @return The button that was used to dismiss the alert.
 */
- (NSModalResponse)runAlert:(NSAlert *)alert onWindow:(NSWindow *)window;

/**
 *  Display an alert synchronously (and conveniently)
 *
 *  @param title   The title of the alert.
 *  @param message The title of the alert.
 *  @param buttons An array containing the names of the buttons.
 *  @param style   The alert style to use.
 *  @param window  An (optional) window to which the alert will be attached.
 *
 *  @return The button that was used to dismiss the alert.
 */
- (NSModalResponse)runAlertWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons style:(NSAlertStyle)style attachToWindow:(NSWindow *)window;

@end
