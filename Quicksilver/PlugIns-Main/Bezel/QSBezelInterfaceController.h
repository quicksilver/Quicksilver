/* QSController */


#import <Cocoa/Cocoa.h>
#import <QSInterface/QSResizingInterfaceController.h>


@interface QSBezelInterfaceController : QSResizingInterfaceController{
    NSRect standardRect;
	IBOutlet NSTextField *details;
}

- (NSRect)rectForState:(BOOL)expanded;
@end