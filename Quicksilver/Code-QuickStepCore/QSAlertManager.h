#import <Foundation/Foundation.h>

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
- (void)beginAlert:(NSAlert *)alert onWindow:(NSWindow *)window completionHandler:(QSAlertHandler)handler;

- (void)beginAlertWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons style:(NSAlertStyle)style onWindow:(NSWindow *)window completionHandler:(QSAlertHandler)handler;

/**
 *  Display an alert synchronously
 *
 *  @param alert  Mandatory, the alert to display.
 *  @param window An (optional) window to which the alert will be attached.
 *
 *  @return The button that was used to dismiss the alert.
 */
- (QSAlertResponse)runAlert:(NSAlert *)alert onWindow:(NSWindow *)window;

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
- (QSAlertResponse)runAlertWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons style:(NSAlertStyle)style attachToWindow:(NSWindow *)window;

@end
