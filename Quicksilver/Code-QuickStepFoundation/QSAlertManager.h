#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define QSAlert [QSAlertManager defaultManager]

NSInteger QSRunSheet(id panel, NSWindow *attachToWin, NSString *title, NSString *msg, NSString *defaultButton, NSString *alternateButton, NSString *otherButton) QS_DEPRECATED;
NSInteger QSRunAlertSheet(NSWindow *attachToWin, NSString *title, NSString *msg, NSString *defaultButton, NSString *alternateButton, NSString *otherButton) QS_DEPRECATED;
NSInteger QSRunInformationalAlertSheet(NSWindow *attachToWin, NSString *title, NSString *msg, NSString *defaultButton, NSString *alternateButton, NSString *otherButton) QS_DEPRECATED;
NSInteger QSRunCriticalAlertSheet(NSWindow *attachToWin, NSString *title, NSString *msg, NSString *defaultButton, NSString *alternateButton, NSString *otherButton) QS_DEPRECATED;

typedef NS_ENUM(NSInteger, QSAlertResponse) {
    QSAlertResponseOK = 0,
    QSAlertResponseCancel = 1,

    QSAlertResponseFirst = 0,
    QSAlertResponseSecond = 1,
    QSAlertResponseThird = 2,
    /* Other button indexes can be returned */
};


typedef void (^QSAlertHandler)(QSAlertResponse);

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
- (void)beginAlert:(NSAlert *)alert onWindow:(nullable NSWindow *)window completionHandler:(nullable QSAlertHandler)handler;

- (void)beginAlertWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons style:(NSAlertStyle)style onWindow:(nullable NSWindow *)window completionHandler:(nullable QSAlertHandler)handler;

/**
 *  Display an alert synchronously
 *
 *  @param alert  Mandatory, the alert to display.
 *  @param window An (optional) window to which the alert will be attached.
 *
 *  @return The button that was used to dismiss the alert.
 */
- (QSAlertResponse)runAlert:(NSAlert *)alert onWindow:(nullable NSWindow *)window;

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
- (QSAlertResponse)runAlertWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons style:(NSAlertStyle)style attachToWindow:(nullable NSWindow *)window;

/**
 * Display a notification
 *
 * Note that (<=10.9) there can only be 2 buttons on a notification, the second always dismiss the notification without informing the caller.
 * Clicking the notification will give you QSAlertResponseFirst, the button will be QSAlertResponseSecond. The rest is ignored.
 */
- (void)notifyWithNotification:(NSUserNotification *)notif completionHandler:(nullable QSAlertHandler)handler;

/**
 * Create a notification from the given parameters and display it.
 *
 * @see notifyWithNotification:completionHandler:
 */
- (void)notifyWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons completionHandler:(nullable QSAlertHandler)handler;

@end

NS_ASSUME_NONNULL_END
