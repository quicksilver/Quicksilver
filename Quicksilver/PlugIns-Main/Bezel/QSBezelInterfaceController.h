/* QSController */

#import <Cocoa/Cocoa.h>
#import <QSFoundation/QSFoundation.h>
#import <QSCore/QSCore.h>
#import <QSInterface/QSResizingInterfaceController.h>


@interface QSBezelInterfaceController : QSResizingInterfaceController {
	NSRect standardRect;
	IBOutlet NSTextField *details;
}

- (NSRect) rectForState:(BOOL)expanded;
@end
