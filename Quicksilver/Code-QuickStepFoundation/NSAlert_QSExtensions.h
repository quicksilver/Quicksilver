#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, QSAlertResponse) {
    QSAlertResponseOK = 0,
    QSAlertResponseCancel = 1,

    QSAlertResponseFirst = 0,
    QSAlertResponseSecond = 1,
    QSAlertResponseThird = 2,
    /* Other button indexes can be returned */
};


@interface NSAlert (QSExtensions)

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
+ (QSAlertResponse)runAlertWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons style:(NSAlertStyle)style;


- (QSAlertResponse)runAlert;
- (QSAlertResponse)runModalSheetForWindow:(NSWindow *)window;

@end
